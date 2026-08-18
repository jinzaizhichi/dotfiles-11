#include <X11/Xatom.h>
#include <X11/Xlib.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

static int ignore_x_error(Display *display, XErrorEvent *event)
{
	(void)display;
	(void)event;
	return 0;
}

static Window find_frame(Display *display, Window client)
{
	Window current = client;
	Window root = DefaultRootWindow(display);

	for (;;) {
		Window query_root;
		Window parent;
		Window *children = NULL;
		unsigned int child_count = 0;

		if (!XQueryTree(display, current, &query_root, &parent, &children,
				&child_count)) {
			return None;
		}
		if (children != NULL) {
			XFree(children);
		}
		if (parent == root || parent == None) {
			return current;
		}
		current = parent;
	}
}

static unsigned long frame_top_extent(Display *display, Window client)
{
	Atom extents_atom = XInternAtom(display, "_NET_FRAME_EXTENTS", False);
	Atom actual_type;
	int actual_format;
	unsigned long item_count;
	unsigned long bytes_after;
	unsigned char *value = NULL;
	unsigned long top = 0;

	if (XGetWindowProperty(display, client, extents_atom, 0, 4, False,
			XA_CARDINAL, &actual_type, &actual_format, &item_count,
			&bytes_after, &value) == Success && actual_format == 32 &&
			item_count == 4 && value != NULL) {
		top = ((unsigned long *)value)[2];
	}
	if (value != NULL) {
		XFree(value);
	}
	return top;
}

static void position_catcher(Display *display, Window catcher, Window frame,
		unsigned long top_extent)
{
	XWindowAttributes attributes;
	unsigned int height;
	unsigned int width;
	int x;

	if (!XGetWindowAttributes(display, frame, &attributes)) {
		return;
	}
	height = top_extent >= 20 && top_extent <= 64 ? top_extent : 30;
	width = height + 10;
	x = attributes.width > (int)width ? attributes.width - (int)width : 0;
	XMoveResizeWindow(display, catcher, x, 0, width, height);
	XRaiseWindow(display, catcher);
}

static Window attach_catcher(Display *display, Window client, Window old_frame,
		Window old_catcher)
{
	Window frame = find_frame(display, client);
	XSetWindowAttributes attributes;
	Window catcher;

	if (frame == None || frame == client) {
		if (old_catcher != None) {
			XDestroyWindow(display, old_catcher);
			XFlush(display);
		}
		return None;
	}
	if (frame == old_frame && old_catcher != None) {
		position_catcher(display, old_catcher, frame,
				frame_top_extent(display, client));
		return old_catcher;
	}
	if (old_catcher != None) {
		XDestroyWindow(display, old_catcher);
	}
	attributes.event_mask = ButtonPressMask | ButtonReleaseMask;
	attributes.override_redirect = True;
	catcher = XCreateWindow(display, frame, 0, 0, 1, 1, 0, 0, InputOnly,
			CopyFromParent, CWEventMask | CWOverrideRedirect, &attributes);
	XSelectInput(display, frame, StructureNotifyMask);
	position_catcher(display, catcher, frame,
			frame_top_extent(display, client));
	XMapRaised(display, catcher);
	XFlush(display);
	return catcher;
}

static void hide_window(Display *display, Window client)
{
	int screen = DefaultScreen(display);

	XIconifyWindow(display, client, screen);
	XSync(display, False);
	XWithdrawWindow(display, client, screen);
	XSync(display, False);
}

int main(int argc, char **argv)
{
	char *end = NULL;
	unsigned long parsed_id;
	Display *display;
	Window client;
	Window frame;
	Window catcher;

	if (argc != 2) {
		fprintf(stderr, "usage: %s WINDOW_ID\n", argv[0]);
		return 2;
	}
	errno = 0;
	parsed_id = strtoul(argv[1], &end, 0);
	if (errno != 0 || end == argv[1] || *end != '\0') {
		fprintf(stderr, "%s: invalid window id: %s\n", argv[0], argv[1]);
		return 2;
	}
	display = XOpenDisplay(NULL);
	if (display == NULL) {
		fprintf(stderr, "%s: cannot open X display\n", argv[0]);
		return 1;
	}
	XSetErrorHandler(ignore_x_error);
	client = (Window)parsed_id;
	frame = find_frame(display, client);
	if (frame == None) {
		fprintf(stderr, "%s: cannot find the window frame\n", argv[0]);
		XCloseDisplay(display);
		return 1;
	}
	XSelectInput(display, client, StructureNotifyMask | PropertyChangeMask);
	catcher = attach_catcher(display, client, None, None);
	frame = catcher == None ? None : find_frame(display, client);
	XFlush(display);

	for (;;) {
		XEvent event;

		XNextEvent(display, &event);
		if (event.type == ButtonRelease && event.xbutton.window == catcher &&
				event.xbutton.button == Button1) {
			hide_window(display, client);
		} else if (event.type == DestroyNotify &&
				event.xdestroywindow.window == client) {
			break;
		} else if (event.type == DestroyNotify &&
				(event.xdestroywindow.window == frame ||
				 event.xdestroywindow.window == catcher)) {
			frame = None;
			catcher = None;
		} else if ((event.type == ReparentNotify || event.type == MapNotify ||
				event.type == ConfigureNotify || event.type == PropertyNotify) &&
				(event.xany.window == client || event.xany.window == frame)) {
			Window new_frame = find_frame(display, client);
			Window new_catcher = attach_catcher(display, client, frame,
					catcher);

			frame = new_catcher == None ? None : new_frame;
			catcher = new_catcher;
		}
	}

	XCloseDisplay(display);
	return 0;
}

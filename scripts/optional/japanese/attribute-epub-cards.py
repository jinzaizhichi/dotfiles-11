#!/usr/bin/env python3

import argparse
import html.parser
import json
import os
import posixpath
import sys
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path


ANKI_CONNECT_URL = os.environ.get("ANKI_CONNECT_URL", "http://127.0.0.1:8765")


class TextExtractor(html.parser.HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []
        self.ignored_depth = 0

    def handle_starttag(self, tag, _attrs):
        if tag in {"script", "style"}:
            self.ignored_depth += 1

    def handle_endtag(self, tag):
        if tag in {"script", "style"} and self.ignored_depth:
            self.ignored_depth -= 1

    def handle_data(self, data):
        if not self.ignored_depth:
            self.parts.append(data)


def plain_text(value: str) -> str:
    parser = TextExtractor()
    parser.feed(value)
    parser.close()
    return "".join(parser.parts)


def normalize(value: str) -> str:
    return "".join(unicodedata.normalize("NFKC", plain_text(value)).split())


def read_epub(path: Path) -> tuple[str, str]:
    with zipfile.ZipFile(path) as archive:
        container = ET.fromstring(archive.read("META-INF/container.xml"))
        rootfile = container.find(".//{*}rootfile")
        if rootfile is None or not rootfile.get("full-path"):
            raise ValueError("EPUB container does not name a package document")

        package_path = rootfile.get("full-path")
        package = ET.fromstring(archive.read(package_path))
        title_element = package.find(
            ".//{http://purl.org/dc/elements/1.1/}title"
        )
        title = "" if title_element is None else "".join(title_element.itertext()).strip()

        manifest = {
            item.get("id"): item.get("href")
            for item in package.findall(".//{*}manifest/{*}item")
            if item.get("id") and item.get("href")
        }
        package_directory = posixpath.dirname(package_path)
        chapters = []
        for itemref in package.findall(".//{*}spine/{*}itemref"):
            href = manifest.get(itemref.get("idref"))
            if not href:
                continue
            chapter_path = posixpath.normpath(
                posixpath.join(
                    package_directory,
                    urllib.parse.unquote(href.split("#", 1)[0]),
                )
            )
            chapters.append(archive.read(chapter_path).decode("utf-8-sig"))

    if not chapters:
        raise ValueError("EPUB package has no readable spine entries")
    return title, "".join(chapters)


def anki_request(action: str, params: dict) -> object:
    payload = json.dumps(
        {"action": action, "version": 6, "params": params}
    ).encode()
    request = urllib.request.Request(ANKI_CONNECT_URL, payload)
    with urllib.request.urlopen(request) as response:
        body = json.load(response)
    if not isinstance(body, dict) or "result" not in body or body.get("error") is not None:
        error = body.get("error", "invalid response") if isinstance(body, dict) else "invalid response"
        raise ValueError(f"AnkiConnect {action} failed: {error}")
    return body["result"]


def field_value(note: dict, name: str) -> str:
    value = note.get("fields", {}).get(name, {}).get("value", "")
    return value if isinstance(value, str) else ""


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Restore book titles on Japanese Sentences notes matched to an EPUB."
    )
    parser.add_argument("epub", type=Path)
    parser.add_argument("--title", help="override the EPUB metadata title")
    parser.add_argument("--apply", action="store_true", help="update matching Anki notes")
    arguments = parser.parse_args()

    try:
        epub_title, book_html = read_epub(arguments.epub)
        title = (arguments.title or epub_title).strip()
        if not title:
            raise ValueError("EPUB has no title; pass one with --title")

        note_ids = anki_request("findNotes", {"query": 'note:"Japanese sentences"'})
        if not isinstance(note_ids, list):
            raise ValueError("AnkiConnect findNotes returned invalid data")
        notes = anki_request("notesInfo", {"notes": note_ids})
        if not isinstance(notes, list):
            raise ValueError("AnkiConnect notesInfo returned invalid data")
    except (KeyError, OSError, UnicodeError, ValueError, zipfile.BadZipFile, ET.ParseError, urllib.error.URLError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    book_text = normalize(book_html)
    candidates = []
    unmatched = attributed = 0
    for note in notes:
        current_notes = field_value(note, "Notes")
        if current_notes not in {"", "Yomitan Search"}:
            attributed += 1
            continue
        sentence_html = field_value(note, "SentKanji")
        sentence = normalize(sentence_html)
        occurrences = book_text.count(sentence) if sentence else 0
        if occurrences == 0:
            unmatched += 1
        else:
            candidates.append((note["noteId"], plain_text(sentence_html), current_notes))

    for note_id, sentence, current_notes in candidates:
        print(f"Note {note_id}")
        print(f"  Sentence: {sentence}")
        print(f"  Current Notes: {current_notes or '<empty>'}")
        print(f"  Proposed Notes: {title}")

    print(
        f"Summary: candidates: {len(candidates)}, unmatched: {unmatched}, "
        f"already attributed: {attributed}"
    )

    if not arguments.apply:
        print("Dry run; pass --apply to update these notes.")
        return 0

    try:
        for note_id, _sentence, _current_notes in candidates:
            anki_request(
                "updateNoteFields",
                {"note": {"id": note_id, "fields": {"Notes": title}}},
            )
    except (OSError, ValueError, urllib.error.URLError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(f"Updated {len(candidates)} note{'s' if len(candidates) != 1 else ''}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

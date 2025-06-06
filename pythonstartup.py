# https://unix.stackexchange.com/a/740971
import os
import atexit
import readline
from pathlib import Path

if readline.get_current_history_length() == 0:
    state_home = os.environ.get("XDG_STATE_HOME")
    if state_home is None:
        state_home = Path.home() / ".local" / "state"
    else:
        state_home = Path(state_home)

    history_path = state_home / "python_history"
    if history_path.is_dir():
        raise OSError(f"'{history_path}' cannot be a directory")

    history = str(history_path)

    try:
        readline.read_history_file(history)
    except OSError:  # Non existent
        pass

    def write_history():
        try:
            readline.write_history_file(history)
        except OSError:
            pass

    atexit.register(write_history)

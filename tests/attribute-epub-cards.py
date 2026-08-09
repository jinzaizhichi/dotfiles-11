#!/usr/bin/env python3

import json
import os
import subprocess
import sys
import tempfile
import threading
import unittest
import zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/optional/japanese/attribute-epub-cards.py"


class AnkiHandler(BaseHTTPRequestHandler):
    updates = []
    notes = [
        {
            "noteId": 1,
            "fields": {
                "SentKanji": {"value": "吾輩は<b>猫</b>である。"},
                "Notes": {"value": ""},
            },
        },
        {
            "noteId": 2,
            "fields": {
                "SentKanji": {"value": "吾輩は猫である。"},
                "Notes": {"value": "既存の出典"},
            },
        },
        {
            "noteId": 3,
            "fields": {
                "SentKanji": {"value": "同じ文。"},
                "Notes": {"value": "Yomitan Search"},
            },
        },
    ]

    def do_POST(self):
        request = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        action = request["action"]
        if action == "findNotes":
            result = [note["noteId"] for note in self.notes]
        elif action == "notesInfo":
            result = self.notes
        elif action == "updateNoteFields":
            self.updates.append(request["params"])
            result = None
        else:
            self.send_error(400, f"Unexpected action: {action}")
            return
        body = json.dumps({"result": result, "error": None}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, _format, *_args):
        pass


def make_epub(path):
    with zipfile.ZipFile(path, "w") as archive:
        archive.writestr(
            "META-INF/container.xml",
            '<?xml version="1.0"?><container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OEBPS/content.opf"/></rootfiles></container>',
        )
        archive.writestr(
            "OEBPS/content.opf",
            '<?xml version="1.0"?><package xmlns="http://www.idpf.org/2007/opf" version="3.0"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>吾輩は猫である</dc:title></metadata><manifest><item id="chapter" href="chapter.xhtml" media-type="application/xhtml+xml"/></manifest><spine><itemref idref="chapter"/></spine></package>',
        )
        archive.writestr(
            "OEBPS/chapter.xhtml",
            "<html><body><p>吾輩は猫である。</p><p>同じ文。</p><p>同じ文。</p></body></html>",
        )


class AttributeEpubCardsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), AnkiHandler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()

    def setUp(self):
        AnkiHandler.updates.clear()

    def run_script(self, epub, *arguments):
        environment = os.environ.copy()
        environment["ANKI_CONNECT_URL"] = (
            f"http://127.0.0.1:{self.server.server_address[1]}"
        )
        return subprocess.run(
            [sys.executable, SCRIPT, epub, *arguments],
            text=True,
            capture_output=True,
            env=environment,
        )

    def test_dry_run_previews_and_apply_updates_all_matching_unattributed_notes(self):
        with tempfile.TemporaryDirectory() as directory:
            epub = Path(directory) / "book.epub"
            make_epub(epub)

            dry_run = self.run_script(epub)
            self.assertEqual(dry_run.returncode, 0, dry_run.stderr)
            self.assertIn("Note 1", dry_run.stdout)
            self.assertIn("吾輩は猫である", dry_run.stdout)
            self.assertIn("Proposed Notes: 吾輩は猫である", dry_run.stdout)
            self.assertIn("Note 3", dry_run.stdout)
            self.assertIn("candidates: 2", dry_run.stdout)
            self.assertEqual(AnkiHandler.updates, [])

            applied = self.run_script(epub, "--apply")
            self.assertEqual(applied.returncode, 0, applied.stderr)
            self.assertEqual(
                AnkiHandler.updates,
                [
                    {"note": {"id": 1, "fields": {"Notes": "吾輩は猫である"}}},
                    {"note": {"id": 3, "fields": {"Notes": "吾輩は猫である"}}},
                ],
            )
            self.assertIn("Updated 2 notes.", applied.stdout)


if __name__ == "__main__":
    unittest.main()

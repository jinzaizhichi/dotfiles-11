# EPUB Card Attribution

## Purpose

Recover missing book attribution for `Japanese sentences` notes created from copied EPUB text.

## Interface

`scripts/optional/japanese/attribute-epub-cards.py BOOK.epub [--title TITLE] [--apply]`

The EPUB metadata title is the proposed `Notes` value unless `--title` overrides it. Without `--apply`, the script only reports proposed changes.

## Behavior

The script uses Python's standard library to extract and normalize EPUB XHTML text and calls AnkiConnect at `http://127.0.0.1:8765`. It queries `Japanese sentences` notes, normalizes `SentKanji` by removing HTML and whitespace differences, and finds it as a substring of the normalized book text.

Only notes whose `Notes` field is empty or exactly `Yomitan Search` and whose sentence occurs in the normalized book text are eligible. Dry-run output shows note ID, sentence, current `Notes`, and proposed title. `--apply` updates that same eligible set. Real existing attribution is never overwritten; unmatched sentences are summarized and left unchanged.

## Failure handling

The script exits without modifying Anki when the EPUB is invalid, lacks a usable title, AnkiConnect is unavailable, or its response is invalid. Updates are sent only after discovery and reporting complete.

## Check

One standard-library test builds a minimal EPUB and fake AnkiConnect server, verifies dry-run leaves notes untouched, then verifies `--apply` updates only the exact eligible note.

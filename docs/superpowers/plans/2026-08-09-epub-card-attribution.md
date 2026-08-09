# EPUB Card Attribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a safe utility that finds Japanese Sentences cards belonging to one EPUB and restores their missing book title.

**Architecture:** One dependency-free Python command extracts the EPUB title and reading-order text, queries AnkiConnect, and classifies notes before any write occurs. A standard-library integration test supplies a minimal EPUB and fake AnkiConnect server.

**Tech Stack:** Python 3 standard library, EPUB ZIP/XML, AnkiConnect JSON API, `unittest`

## Global Constraints

- Install no Python packages.
- Dry-run unless `--apply` is present.
- Never replace `Notes` unless its value is empty or exactly `Yomitan Search`.
- Modify only notes whose normalized sentence occurs in the supplied EPUB.

---

### Task 1: EPUB-to-Anki attribution command

**Files:**
- Create: `scripts/optional/japanese/attribute-epub-cards.py`
- Create: `tests/attribute-epub-cards.py`
- Modify: `README.md`

**Interfaces:**
- Consumes: `BOOK.epub`, optional `--title TITLE`, optional `--apply`, and AnkiConnect at `http://127.0.0.1:8765`.
- Produces: a reviewable report and, with `--apply`, `updateNoteFields` requests for eligible note IDs.

- [ ] **Step 1: Write the failing integration test**

Create a minimal EPUB containing title `吾輩は猫である`, one unique Japanese sentence, and one repeated sentence. Serve fake responses for `findNotes`, `notesInfo`, and `updateNoteFields`; assert dry-run reports both unattributed matching notes without updating them, and `--apply` updates both while leaving an attributed note unchanged.

- [ ] **Step 2: Run the test to verify it fails**

Run: `python3 tests/attribute-epub-cards.py`

Expected: FAIL because `scripts/optional/japanese/attribute-epub-cards.py` does not exist.

- [ ] **Step 3: Implement the minimal command**

Implement these direct helpers in the command:

```python
def normalize(value: str) -> str: ...
def read_epub(path: Path) -> tuple[str, str]: ...
def anki_request(action: str, params: dict) -> object: ...
def main() -> int: ...
```

Use `zipfile` and `xml.etree.ElementTree` to resolve `META-INF/container.xml`, read Dublin Core title metadata, follow the OPF spine, and collect XHTML text. Use `html.parser.HTMLParser`, HTML unescaping, Unicode NFKC normalization, and whitespace removal for both book and note sentences. Query `findNotes` with `note:"Japanese sentences"`, fetch `notesInfo`, classify before writing, print each candidate's ID/current/proposed fields, and issue `updateNoteFields` only after `--apply` and only for candidates.

- [ ] **Step 4: Run the focused test**

Run: `python3 tests/attribute-epub-cards.py`

Expected: PASS with dry-run and apply assertions satisfied.

- [ ] **Step 5: Document the command**

Add the optional script to the README manual-setup table and show:

```sh
./scripts/optional/japanese/attribute-epub-cards.py ~/Books/book.epub
./scripts/optional/japanese/attribute-epub-cards.py ~/Books/book.epub --apply
```

- [ ] **Step 6: Run repository verification**

Run:

```sh
python3 tests/attribute-epub-cards.py
bash tests/bootstrap.sh
```

Expected: both commands exit successfully.

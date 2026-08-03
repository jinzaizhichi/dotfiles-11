# Japanese Sentences Updater Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an explicit optional command that installs or updates the official AJATT Japanese Sentences note type while preserving rich Yomitan dictionary HTML.

**Architecture:** A Bash script downloads the current upstream manifest, templates, and CSS into a temporary directory. It validates and applies the three expected `VocabDef` substitutions plus the mobile-image expansion before creating or updating the note type through AnkiConnect; any upstream mismatch stops before Anki is changed.

**Tech Stack:** Bash, curl, jq, AnkiConnect v6.

## Global Constraints

- The updater is optional and must not run from bootstrap.
- Fetch from `Ajatt-Tools/AnkiNoteTypes` main on each explicit invocation.
- Replace exactly one normal and one hinted `VocabDef` expression in Recognition, and exactly one normal expression in Production.
- Keep Recognition images expanded initially on mobile while retaining the native disclosure toggle.
- Abort before an Anki write if upstream no longer matches those expectations.
- Existing note types are updated; missing note types are created with upstream fields and card names.

---

### Task 1: Optional updater

**Files:**
- Create: `scripts/optional/update-japanese-sentences.sh`
- Create: `tests/update-japanese-sentences.sh`
- Modify: `tests/bootstrap.sh`
- Modify: `README.md`

**Interfaces:**
- Consumes: raw files under `templates/Japanese sentences/` in `Ajatt-Tools/AnkiNoteTypes` and AnkiConnect at `http://127.0.0.1:8765`.
- Produces: an installed or updated `Japanese sentences` model whose Recognition and Production templates use `{{edit:VocabDef}}`, with Recognition retaining `{{edit:hint:VocabDef}}` and opening images initially on mobile.

- [x] **Step 1: Write the failing integration test**

Create upstream fixture files and a fake `curl` that serves them, returns an empty `modelNames` result, captures `createModel`, and verifies that the resulting payload contains the upstream fields/CSS and all three patched expressions.

- [x] **Step 2: Run the focused test to verify it fails**

Run: `bash tests/update-japanese-sentences.sh`

Expected: failure because `scripts/optional/update-japanese-sentences.sh` does not exist.

- [x] **Step 3: Implement the minimal updater**

Download `template.json`, `template.css`, and both sides of Recognition and Production. Validate exact source-expression counts, apply the substitutions, query `modelNames`, then call `createModel` or validate the existing model and call `updateModelTemplates` plus `updateModelStyling`. Check every AnkiConnect response for a non-null error.

- [x] **Step 4: Document and wire the test**

Add the optional command to the README table and invoke the focused integration test from `tests/bootstrap.sh`.

- [x] **Step 5: Verify**

Run: `bash tests/update-japanese-sentences.sh && bash tests/bootstrap.sh`

Expected: both commands exit 0 with no shell syntax or whitespace errors.

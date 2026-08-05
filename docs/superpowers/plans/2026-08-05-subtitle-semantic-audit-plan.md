# Subtitle Semantic Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce and review a focused cross-show report of Japanese/English semantic mismatches, then safely correct only confirmed cases.

**Architecture:** A small standard-library scanner parses final ASS files and emits ranked candidates. Semantic decisions remain a manual review step; a separate confirmed report records findings and drives explicit subtitle edits.

**Tech Stack:** Python 3 standard library, ASS text files, CSV, existing handoff alignment helpers.

## Global Constraints

- Do not install or run local AI/Whisper models.
- Do not modify MKV files.
- Do not infer semantic correctness from timing alone.
- Do not apply heuristic-only subtitle changes.
- Preserve the 400 ms minimum cue duration and adjacent-English-deduplication invariants.

---

### Task 1: Candidate generator

**Files:**
- Create: `japanese/anime/subtitles/handoff/semantic_audit.py`
- Test: `japanese/anime/subtitles/handoff/test_semantic_audit.py`

**Interfaces:**
- Consumes: final `subs.jp`/`subs.ja` and `subs.en` ASS files beneath the subtitle root.
- Produces: `iter_candidates(root: Path) -> list[dict[str, str]]` and CSV output.

- [ ] Write a failing test with literal ASS fixtures covering missing counterparts, multiple English cues, length-ratio anomalies, question mismatch, and a clean pair.
- [ ] Run `python3 test_semantic_audit.py` and confirm it fails because `semantic_audit` is absent.
- [ ] Implement the minimal ASS parser and candidate rules using only `csv`, `pathlib`, and `re`.
- [ ] Run `python3 test_semantic_audit.py` and confirm it passes.

### Task 2: Cross-show candidate generation

**Files:**
- Create: `/tmp/subtitle-semantic-candidates.csv`

**Interfaces:**
- Consumes: `iter_candidates()` from Task 1.
- Produces: ranked rows containing show, episode, timing, Japanese, English, neighboring English, and triggered signals.

- [ ] Run the scanner against `/home/evakuator/dotfiles/japanese/anime/subtitles`.
- [ ] Check candidate counts per show and tune only thresholds that produce demonstrably noisy results.
- [ ] Rerun the scanner and retain the final candidate CSV.

### Task 3: Semantic review

**Files:**
- Create: `japanese/anime/subtitles/handoff/semantic-mismatches.csv`

**Interfaces:**
- Consumes: ranked candidates and neighboring subtitle context.
- Produces: rows classified as `wrong_pair`, `partial_translation`, `missing_translation`, or `segmentation`, with proposed correction and confidence.

- [ ] Review each candidate's Japanese meaning against its English and adjacent cues.
- [ ] Remove structurally suspicious but semantically correct pairs.
- [ ] Record only confirmed or genuinely ambiguous mismatches.
- [ ] Verify every proposed replacement against the complete local dialogue context.

### Task 4: High-confidence corrections

**Files:**
- Modify: only ASS files named by confirmed high-confidence rows.
- Modify: `japanese/anime/subtitles/handoff/semantic-mismatches.csv`

**Interfaces:**
- Consumes: confirmed mismatch rows from Task 3.
- Produces: corrected English cue timing/text and unresolved-only report rows.

- [ ] Add a literal regression assertion for each correction before editing its ASS file.
- [ ] Run the regression check and confirm failure.
- [ ] Apply the smallest timing, split, merge, or translation correction that preserves chronology.
- [ ] Run the regression check and confirm success.
- [ ] Copy corrected subtitle files to their matching local show folders without touching videos.

### Task 5: Verification

**Files:**
- Verify: all subtitle and report files.

- [ ] Run `python3 handoff/test_semantic_audit.py`.
- [ ] Run `python3 handoff/test_bidirectional_alignment.py`.
- [ ] Verify all ASS dialogue events have positive duration of at least 400 ms.
- [ ] Verify no adjacent normalized English text is duplicated.
- [ ] Verify local and dotfiles copies are byte-identical where local show folders exist.
- [ ] Report corrected counts, unresolved counts, and the audit's non-exhaustive limitation.

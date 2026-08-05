# Subtitle Semantic Audit Design

## Goal

Find Japanese/English cue pairs whose meanings do not correspond across the six completed shows, without changing MKVs or trusting timing equality as proof of translation correctness.

## Approach

Use a dependency-free structural scanner to reduce roughly 38,000 English cues to a reviewable candidate set. It flags missing exact-time counterparts, multiple English cues attached to one Japanese cue, extreme Japanese/English text-length ratios, contradictory question punctuation, and numbers present on only one side. These signals rank candidates; they do not decide correctness.

The assistant then reviews every candidate semantically with neighboring cues. Confirmed problems are classified as `wrong_pair`, `partial_translation`, `missing_translation`, or `segmentation`. Only high-confidence timing/text corrections are applied. Ambiguous cases remain in the report.

## Outputs

- `handoff/semantic_audit.py`: candidate generator.
- `handoff/test_semantic_audit.py`: dependency-free regression check.
- `handoff/semantic-mismatches.csv`: confirmed or unresolved semantic problems only.
- Corrected ASS files when the intended English counterpart is clear.

## Constraints

- Do not install or run local AI/Whisper models.
- Do not modify MKV files.
- Preserve subtitle styles and dialogue text unless a reviewed correction requires splitting or combining English.
- Never auto-apply a semantic correction from a heuristic score.
- Keep every cue at least 400 ms and prevent adjacent duplicate English text.

## Verification

Run the audit regression check, existing eleven alignment tests, ASS duration and duplicate checks, semantic spot checks for every correction, and byte comparison between dotfiles and local show copies.

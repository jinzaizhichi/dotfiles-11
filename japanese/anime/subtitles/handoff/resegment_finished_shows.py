from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sonny_process import (
    align_english, dedupe_adjacent, load_dialogue, ms, normalize_short_pairs,
    plain, split_for_refs, write_ass,
)

ROOT = Path('/home/evakuator/dotfiles/japanese/anime/subtitles')
OUT = Path('/tmp/coverage-preview')


def load_ass(path):
    cues = []
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        if line.startswith('Dialogue:'):
            fields = line.split(',', 9)
            cues.append((ms(fields[1]), ms(fields[2]), fields[9]))
    return cues


def load_styles(path, accepted):
    cues, seen = [], set()
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        if not line.startswith('Dialogue:'):
            continue
        fields = line.split(',', 9)
        if not accepted(fields[3]) or re.search(r'\\p[1-9]', fields[9]):
            continue
        cue = (ms(fields[1]), ms(fields[2]), fields[9])
        key = (cue[0], cue[1], re.sub(r'\s+', ' ', plain(cue[2])).casefold())
        if plain(cue[2]) and key not in seen:
            seen.add(key)
            cues.append(cue)
    return cues


def matches(cue, ref):
    overlap = min(cue[1], ref[1]) - max(cue[0], ref[0])
    return overlap >= 250 and overlap / max(1, ref[1] - ref[0]) >= 0.2


def text_key(text):
    return re.sub(r'\s+', ' ', plain(text).replace(r'\N', ' ')).casefold().strip()


def process(show, jp_paths, raw_paths, destinations, loader):
    assert len(jp_paths) == len(raw_paths) == len(destinations), (
        show, len(jp_paths), len(raw_paths), len(destinations)
    )
    show_spans = 0
    for episode, (jp_path, raw_path, destination) in enumerate(
        zip(jp_paths, raw_paths, destinations), 1
    ):
        jp = load_ass(jp_path)
        raw = loader(raw_path)
        ambiguous = []
        for cue in raw:
            refs = [ref for ref in jp if matches(cue, ref)]
            if len(refs) > 1 and split_for_refs(cue[2], refs) is None:
                ambiguous.append((cue, refs))
        aligned, _, _ = align_english(jp, raw)
        jp, aligned = normalize_short_pairs(jp, aligned)
        for cue, refs in ambiguous:
            key = text_key(cue[2])
            candidates = [out for out in aligned if key in text_key(out[2])]
            assert any(out[0] <= refs[0][0] and out[1] >= refs[-1][1] for out in candidates), (
                show, episode, cue, refs, candidates
            )
        assert all(end > start and end - start >= 400 for start, end, _ in aligned)
        assert dedupe_adjacent(aligned) == aligned
        path = OUT / destination
        path.parent.mkdir(parents=True, exist_ok=True)
        title = re.sub(r'\.(?:ja|jp)\.ass$', '', jp_path.name)
        write_ass(path, title, aligned, False)
        show_spans += len(ambiguous)
        print(
            f'{show}\t{episode:02}\tspanning={len(ambiguous)}\t'
            f'en={len(raw)}->{len(aligned)}'
        )
    return show_spans


shows = []

jp = sorted((ROOT / 'erased/subs.ja').glob('*.ass'))
shows.append(('erased', jp, sorted(Path('/tmp/erased-en-before-resegment').glob('*.ass')),
              [Path('erased/subs.en') / p.name.replace('.ja.ass', '.en.ass') for p in jp],
              load_dialogue))

jp = sorted((ROOT / 'kokoro-connect/subs.jp').glob('*.ass'))
shows.append(('kokoro-connect', jp, sorted(Path('/tmp/kokoro-english').glob('*.ass')),
              [Path('kokoro-connect/subs.en') / p.name.replace('.ja.ass', '.en.ass') for p in jp],
              lambda p: load_styles(p, lambda style: style in {'Default', 'Alternative'})))

jp = sorted((ROOT / 'monogatari/bakemonogatari/subs.jp').glob('*.ass'))
shows.append(('bakemonogatari', jp, sorted(Path('/tmp/bakemonogatari-en-before-resegment').glob('*.dialogue.en.ass')),
              [Path('monogatari/bakemonogatari/subs.en') / p.name.replace('.ja.ass', '.en.ass') for p in jp],
              load_dialogue))

jp = sorted((ROOT / 'sonny-boy/subs.jp').glob('*.ass'))
shows.append(('sonny-boy', jp, sorted(Path('/tmp/sonny-boy-kitsunekko-extract/en').glob('*.ass')),
              [Path('sonny-boy/subs.en') / p.name.replace('.ja.ass', '.en.ass') for p in jp],
              load_dialogue))

jp = sorted((ROOT / 'wonder-egg-priority/subs.jp').glob('*.ass'))
jp += sorted((ROOT / 'wonder-egg-priority/Specials/subs.jp').glob('*.ass'))
destinations = [Path('wonder-egg-priority/subs.en') / p.name.replace('.ja.ass', '.en.ass') for p in jp[:-1]]
destinations += [Path('wonder-egg-priority/Specials/subs.en') / jp[-1].name.replace('.ja.ass', '.en.ass')]
shows.append(('wonder-egg-priority', jp, sorted(Path('/tmp/wonder-egg-english').glob('*.ass')),
              destinations, lambda p: load_styles(p, lambda style: style.startswith('Default'))))

jp = sorted((ROOT / 'fullmetal-alchemist/subs.jp').glob('*.ass'))
shows.append(('fullmetal-alchemist', jp, sorted(Path('/tmp/fma-english').glob('*.ass')),
              [Path('fullmetal-alchemist/subs.en') / p.name.replace('.ja.ass', '.en.ass') for p in jp],
              lambda p: load_styles(p, lambda style: style in {'Dialogue', 'Dialogue Alt'})))

total = 0
for args in shows:
    total += process(*args)
print(f'TOTAL spanning cues extended: {total}')

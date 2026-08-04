from pathlib import Path
from itertools import combinations
import re


def plain(text):
    return re.sub(r"\{[^}]*\}", "", text).replace(r"\h", " ").strip()


def merge_texts(texts):
    merged = []
    seen = set()
    for text in texts:
        for part in re.split(r"\\N|\n", text):
            key = re.sub(r"\s+", " ", plain(part)).casefold()
            if key and key not in seen:
                seen.add(key)
                merged.append(part.strip())
    return r"\N".join(merged)


def merge_group(events):
    events = sorted(events)
    if all(events[i][0] >= events[i - 1][1] - 250 for i in range(1, len(events))):
        return [merge_texts(event[2] for event in events)]
    return [event[2] for event in events]


def dedupe_adjacent(cues):
    out = []
    for start, end, text in cues:
        if out and start <= out[-1][1] + 260:
            prev_start, prev_end, prev_text = out[-1]
            prev_parts = re.split(r"\\N|\n", prev_text)
            parts = re.split(r"\\N|\n", text)
            prev_keys = {re.sub(r"\s+", " ", plain(part)).casefold() for part in prev_parts}
            key = re.sub(r"\s+", " ", plain(text)).casefold()
            prev_key = re.sub(r"\s+", " ", plain(prev_text)).casefold()
            if key == prev_key:
                out[-1] = (prev_start, max(prev_end, end), prev_text)
                continue
            if len(prev_parts) > 1 or len(parts) > 1:
                parts = [
                    part for part in parts
                    if re.sub(r"\s+", " ", plain(part)).casefold() not in prev_keys
                ]
                if not parts:
                    out[-1] = (prev_start, max(prev_end, end), prev_text)
                    continue
                text = r"\N".join(parts)
        out.append((start, end, text))
    return out


def repair_invalid(cues):
    repaired = []
    for i, (start, end, text) in enumerate(cues):
        if end <= start:
            next_start = cues[i + 1][0] if i + 1 < len(cues) else start + 1600
            end = min(start + 1500, next_start - 100)
        repaired.append((start, end, text))
    return repaired


def ms(value):
    h, m, s = value.replace(",", ".").split(":")
    return round((int(h) * 3600 + int(m) * 60 + float(s)) * 1000)


def load_srt(path):
    cues = []
    for block in re.split(r"\r?\n\r?\n", path.read_text(encoding="utf-8-sig").strip()):
        lines = block.splitlines()
        for i, line in enumerate(lines):
            match = re.match(r"(\d\d:\d\d:\d\d[,.]\d+) --> (\d\d:\d\d:\d\d[,.]\d+)", line)
            if match:
                text = r"\N".join(lines[i + 1 :]).strip()
                cues.append((ms(match[1]), ms(match[2]), text))
                break
    return cues


def load_dialogue(path):
    cues = []
    seen = set()
    blocked_style = re.compile(r"sign|ed|op|title|credit|ts", re.I)
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        if not line.startswith("Dialogue:"):
            continue
        fields = line.split(",", 9)
        start, end, style, text = ms(fields[1]), ms(fields[2]), fields[3], fields[9]
        key = (start, end, re.sub(r"\s+", " ", plain(text)).casefold())
        if (
            blocked_style.search(style)
            or re.search(r"\\p[1-9]", text)
            or not plain(text)
            or key in seen
        ):
            continue
        seen.add(key)
        cues.append((start, end, text))
    return cues


def split_sentences(text):
    comments = []
    def stash(match):
        comments.append(match.group())
        return f"\x00{len(comments) - 1}\x00"

    masked = re.sub(r"\{[^}]*\}", stash, text)
    restore = lambda part: re.sub(r"\x00(\d+)\x00", lambda match: comments[int(match.group(1))], part)
    return [restore(part).strip() for part in re.split(r"(?<=[.!?])(?:\\N|\s)+", masked) if plain(restore(part))]


def split_for_refs(text, refs):
    parts = split_sentences(text)
    if len(refs) < 2 or len(parts) < len(refs):
        return None
    durations = [end - start for start, end, _ in refs]
    target = [sum(durations[:i]) / sum(durations) for i in range(1, len(refs))]
    lengths = [max(1, len(plain(part))) for part in parts]
    cuts = min(
        combinations(range(1, len(parts)), len(refs) - 1),
        key=lambda candidate: sum(
            abs(sum(lengths[:cut]) / sum(lengths) - expected)
            for cut, expected in zip(candidate, target)
        ),
    )
    bounds = (0, *cuts, len(parts))
    return [" ".join(parts[bounds[i]:bounds[i + 1]]) for i in range(len(refs))]


def align_english(jp, english):
    groups = [[] for _ in jp]
    orphans = []
    spanning = []
    for cue in english:
        overlaps = [min(cue[1], ref[1]) - max(cue[0], ref[0]) for ref in jp]
        matched = [
            i for i, overlap in enumerate(overlaps)
            if overlap >= 250 and overlap / max(1, jp[i][1] - jp[i][0]) >= 0.2
        ]
        parts = split_for_refs(cue[2], [jp[i] for i in matched])
        if parts:
            for i, part in zip(matched, parts):
                groups[i].append((cue[0], cue[1], part))
            continue
        if len(matched) > 1:
            spanning.append((jp[matched[0]][0], jp[matched[-1]][1], cue[2]))
            continue
        best = max(range(len(jp)), key=overlaps.__getitem__)
        if overlaps[best] > 0:
            groups[best].append(cue)
            continue
        centers = [abs((cue[0] + cue[1]) - (ref[0] + ref[1])) for ref in jp]
        best = min(range(len(jp)), key=centers.__getitem__)
        (groups[best] if centers[best] <= 3000 else orphans).append(cue)

    output = []
    merged_groups = 0
    for ref, group in zip(jp, groups):
        if not group:
            continue
        group.sort()
        merged = merge_group(group)
        if len(merged) == 1:
            output.append((ref[0], ref[1], merged[0]))
            merged_groups += len(group) > 1
        else:
            output.extend(group)
    output.extend(orphans)
    output.extend(spanning)
    return dedupe_adjacent(sorted(output)), merged_groups, len(orphans)


def normalize_short_pairs(jp, english, minimum=400, max_gap=500):
    jp, english = list(jp), list(english)
    i = 0
    while i < len(jp):
        start, end, text = jp[i]
        own = [k for k, cue in enumerate(english) if cue[:2] == (start, end)]
        if end - start >= minimum:
            i += 1
            continue

        neighbors = []
        for j in (i - 1, i + 1):
            if not 0 <= j < len(jp):
                continue
            ns, ne, _ = jp[j]
            paired = [k for k, cue in enumerate(english) if cue[:2] == (ns, ne)]
            gap = max(0, ns - end, start - ne)
            if gap <= max_gap:
                neighbors.append((gap, not bool(paired), j != i + 1, j, paired))

        if neighbors:
            _, _, _, j, paired = min(neighbors)
            lo, hi = sorted((i, j))
            merged_jp = (
                jp[lo][0], jp[hi][1], merge_texts((jp[lo][2], jp[hi][2]))
            )
            indexes = set(own + paired)
            jp[lo:hi + 1] = [merged_jp]
            if indexes:
                merged_en = (
                    merged_jp[0], merged_jp[1],
                    merge_texts(english[k][2] for k in sorted(indexes, key=lambda k: english[k][:2])),
                )
                english = [cue for k, cue in enumerate(english) if k not in indexes]
                english.append(merged_en)
                english.sort()
            i = max(0, lo - 1)
            continue

        next_starts = [cue[0] for cue in jp[i + 1:] + english if cue[0] >= end]
        new_end = min([start + minimum, *next_starts]) if next_starts else start + minimum
        if new_end - start < minimum:
            previous_ends = [cue[1] for cue in jp[:i] + english if cue[1] <= start]
            new_start = max([end - minimum, *previous_ends]) if previous_ends else end - minimum
        else:
            new_start = start
        jp[i] = (new_start, new_end, text)
        english = [
            (new_start, new_end, cue[2]) if k in own else cue
            for k, cue in enumerate(english)
        ]
        english.sort()
        i += 1

    while True:
        short = next((cue for cue in english if cue[1] - cue[0] < minimum), None)
        if short is None:
            break
        start, end, _ = short
        group = {k for k, cue in enumerate(english) if cue[:2] == (start, end)}
        others = [cue for k, cue in enumerate(english) if k not in group]
        next_start = min((cue[0] for cue in others if cue[0] >= end), default=start + minimum)
        previous_end = max((cue[1] for cue in others if cue[1] <= start), default=0)
        if start + minimum <= next_start:
            timing = (start, start + minimum)
        elif end - minimum >= previous_end:
            timing = (end - minimum, end)
        else:
            neighbor = min(
                others,
                key=lambda cue: max(0, cue[0] - end, start - cue[1]),
            )
            indexes = group | {
                k for k, cue in enumerate(english) if cue[:2] == neighbor[:2]
            }
            merged = (
                min(english[k][0] for k in indexes),
                max(english[k][1] for k in indexes),
                merge_texts(english[k][2] for k in sorted(indexes, key=lambda k: english[k][:2])),
            )
            english = [cue for k, cue in enumerate(english) if k not in indexes] + [merged]
            english.sort()
            continue
        english = [
            (*timing, cue[2]) if k in group else cue
            for k, cue in enumerate(english)
        ]
        english.sort()

    return jp, english


def ass_time(value):
    value = max(0, value)
    hours, remainder = divmod(value, 3_600_000)
    minutes, remainder = divmod(remainder, 60_000)
    seconds, millis = divmod(remainder, 1000)
    return f"{hours}:{minutes:02}:{seconds:02}.{millis // 10:02}"


def write_ass(path, title, cues, japanese):
    if japanese:
        style = "Style: Dialogue,Noto Sans CJK JP,58,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,-1,0,0,0,100,100,1,0,1,4,0,2,0,0,40,128"
    else:
        style = "Style: Dialogue,Noto Sans,46,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,3,0,2,40,40,40,1"
    header = f"""[Script Info]
Title: {title}
ScriptType: v4.00+
WrapStyle: 0
ScaledBorderAndShadow: yes
YCbCr Matrix: TV.709
PlayResX: 1280
PlayResY: 720

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
{style}

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    events = "".join(
        f"Dialogue: 0,{ass_time(start)},{ass_time(end)},Dialogue,,0,0,0,,{text}\n"
        for start, end, text in cues
    )
    path.write_text(header + events, encoding="utf-8")


def main():
    cwd = Path.cwd()
    videos = sorted(cwd.glob("*.mkv"))
    japanese = sorted(Path("/tmp/sonny-boy-kitsunekko-extract/Sonny Boy").glob("*.srt"))
    english = sorted(Path("/tmp/sonny-boy-kitsunekko-extract/en").glob("*.ass"))
    offsets = [200, 130, 170, 170, 200, 220, 140, 220, 200, 90, 230, 80]
    assert len(videos) == len(japanese) == len(english) == 12
    jp_dir, en_dir = cwd / "subs.jp", cwd / "subs.en"
    jp_dir.mkdir()
    en_dir.mkdir()

    for video, jp_path, en_path, offset in zip(videos, japanese, english, offsets):
        jp = [
            (start + offset, end + offset, text)
            for start, end, text in repair_invalid(load_srt(jp_path))
        ]
        en = load_dialogue(en_path)
        aligned, merged, orphans = align_english(jp, en)
        write_ass(jp_dir / f"{video.stem}.ja.ass", video.stem, jp, True)
        write_ass(en_dir / f"{video.stem}.en.ass", video.stem, aligned, False)
        print(
            f"{video.stem}: offset=+{offset}ms jp={len(jp)} en={len(en)}->{len(aligned)} "
            f"merged_groups={merged} orphans={orphans}"
        )


if __name__ == "__main__":
    main()

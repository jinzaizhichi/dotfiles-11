from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sonny_process import align_english, dedupe_adjacent, normalize_short_pairs, split_for_refs


def test_splits_one_english_cue_across_two_japanese_cues():
    japanese = [
        (105_410, 107_250, 'おはよう 太一'),
        (107_370, 108_420, 'まだ眠そうだね'),
    ]
    english = [(105_870, 108_750, 'Morning, Taichi. Still sleepy?')]

    aligned, _, _ = align_english(japanese, english)

    assert aligned == [
        (105_410, 107_250, 'Morning, Taichi.'),
        (107_370, 108_420, 'Still sleepy?'),
    ]


def test_keeps_many_english_cues_merged_to_one_japanese_cue():
    japanese = [(1_000, 4_000, '一 二')]
    english = [(1_000, 2_000, 'One.'), (2_000, 4_000, 'Two.')]

    aligned, _, _ = align_english(japanese, english)

    assert aligned == [(1_000, 4_000, r'One.\NTwo.')]


def test_groups_extra_english_fragments_across_japanese_cues():
    japanese = [
        (25_880, 27_800, 'えっ ああ…'),
        (27_800, 29_090, 'ありがとう'),
    ]
    english = [(25_890, 29_050, 'Huh? Oh. Thanks.')]

    aligned, _, _ = align_english(japanese, english)

    assert aligned == [
        (25_880, 27_800, 'Huh? Oh.'),
        (27_800, 29_090, 'Thanks.'),
    ]


def test_merges_short_paired_cue_with_nearest_paired_neighbor():
    japanese = [(1_000, 1_130, 'あっ？'), (1_130, 2_500, 'いや おやすみ')]
    english = [(1_000, 1_130, 'Huh?'), (1_130, 2_500, 'Nothing. Good night.')]

    japanese, english = normalize_short_pairs(japanese, english)

    assert japanese == [(1_000, 2_500, r'あっ？\Nいや おやすみ')]
    assert english == [(1_000, 2_500, r'Huh?\NNothing. Good night.')]


def test_extends_isolated_short_pair_to_minimum_duration():
    japanese = [(1_000, 1_040, 'あの…'), (4_000, 6_000, '話')]
    english = [(1_000, 1_040, 'Um...'), (4_000, 6_000, 'Talk.')]

    japanese, english = normalize_short_pairs(japanese, english)

    assert japanese[0] == (1_000, 1_400, 'あの…')
    assert english[0] == (1_000, 1_400, 'Um...')


def test_merges_short_unpaired_japanese_cue_into_paired_neighbor():
    japanese = [(1_000, 1_500, 'こんにちは'), (1_500, 1_600, 'うん')]
    english = [(1_000, 1_500, 'Hello. Yeah.')]

    japanese, english = normalize_short_pairs(japanese, english)

    assert japanese == [(1_000, 1_600, r'こんにちは\Nうん')]
    assert english == [(1_000, 1_600, 'Hello. Yeah.')]


def test_extends_short_english_only_orphan():
    japanese = [(4_000, 6_000, '話')]
    english = [(1_000, 1_210, 'Huh?'), (4_000, 6_000, 'Talk.')]

    japanese, english = normalize_short_pairs(japanese, english)

    assert english[0] == (1_000, 1_400, 'Huh?')


def test_dedupes_adjacent_text_across_ass_rounding_boundary():
    cues = [(1_000, 2_000, 'Again!'), (2_251, 3_000, 'Again!')]

    assert dedupe_adjacent(cues) == [(1_000, 3_000, 'Again!')]


def test_extends_indivisible_english_across_all_japanese_refs():
    japanese = [
        (76_040, 78_090, '質量が１のものからは'),
        (78_170, 80_090, r'１のものしか\N生み出せない'),
    ]
    english = [(76_110, 80_200, 'Only one thing can be created from something else of a certain mass.')]

    aligned, _, _ = align_english(japanese, english)

    assert aligned == [
        (76_040, 80_090, 'Only one thing can be created from something else of a certain mass.')
    ]


def test_dedupe_extends_retained_cue_across_removed_repeat():
    cues = [
        (1_000, 2_000, r'Get out of there!\NGet up and run!'),
        (2_100, 3_000, 'Get out of there!'),
    ]

    assert dedupe_adjacent(cues) == [
        (1_000, 3_000, r'Get out of there!\NGet up and run!')
    ]


def test_does_not_count_ass_comment_as_sentence_for_splitting():
    refs = [(1_000, 2_000, '思うのをやめた'), (2_000, 3_000, '重みをなくしたのだ')]
    text = (
        'She lost weight. '
        '{Note: More word play. "Omoi" means both "weight" and "feelings."}'
    )

    assert split_for_refs(text, refs) is None


if __name__ == '__main__':
    test_splits_one_english_cue_across_two_japanese_cues()
    test_keeps_many_english_cues_merged_to_one_japanese_cue()
    test_groups_extra_english_fragments_across_japanese_cues()
    test_merges_short_paired_cue_with_nearest_paired_neighbor()
    test_extends_isolated_short_pair_to_minimum_duration()
    test_merges_short_unpaired_japanese_cue_into_paired_neighbor()
    test_extends_short_english_only_orphan()
    test_dedupes_adjacent_text_across_ass_rounding_boundary()
    test_extends_indivisible_english_across_all_japanese_refs()
    test_dedupe_extends_retained_cue_across_removed_repeat()
    test_does_not_count_ass_comment_as_sentence_for_splitting()
    print('11 tests passed')

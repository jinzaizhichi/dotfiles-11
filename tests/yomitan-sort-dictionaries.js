const assert = require('node:assert/strict');
const {sortDictionaries} = require('../japanese/yomitan/sort-dictionaries.js');

const other = {name: 'Other', enabled: false, styles: 'unchanged'};
const result = sortDictionaries([
    {name: 'NHK', enabled: true},
    other,
    {name: 'KANJIDIC [2026-214]', enabled: true},
    {name: 'CC100', enabled: true},
    {name: 'JPDBv2㋕', enabled: true},
    {name: '日本語文法辞典(全集)', enabled: true},
    {name: '旺文社国語辞典 第十一版 画像無し', enabled: true},
    {name: '新和英', enabled: true},
    {name: 'Jitendex.org [2026-07-09]', enabled: true},
]);

assert.deepEqual(result.dictionaries.map(({name}) => name), [
    'Jitendex.org [2026-07-09]',
    '新和英',
    '旺文社国語辞典 第十一版 画像無し',
    '日本語文法辞典(全集)',
    'JPDBv2㋕',
    'CC100',
    'KANJIDIC [2026-214]',
    'NHK',
    'Other',
]);
assert.deepEqual(result.dictionaries.map(({priority}) => priority), [90, 80, 70, 60, 50, 40, 30, 20, 10]);
assert.deepEqual(result.missing, []);
assert.deepEqual(result.unknown, ['Other']);
assert.equal(result.dictionaries.at(-1).enabled, false);
assert.equal(result.dictionaries.at(-1).styles, 'unchanged');
assert.throws(
    () => sortDictionaries([{name: 'NHK'}, {name: 'NHK'}]),
    /matches multiple installed dictionaries/,
);

# Yomitan Dictionary Sorter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a JavaScript snippet that sorts the currently active Yomitan profile's dictionaries into the repository's chosen eight-dictionary order.

**Architecture:** Keep dictionary ordering in a pure CommonJS-testable function. In a browser, use Yomitan's `Application` and `SettingsController` modules to load the active profile, replace its dictionary array, and report missing or unknown dictionaries.

**Tech Stack:** JavaScript, Node.js built-in `assert`, Yomitan options-page modules

## Global Constraints

- Affect only the active Yomitan profile.
- Preserve all dictionary properties except `priority`.
- Match versioned Jitendex and KANJIDIC names without pinning dates.
- Keep unknown dictionaries afterward in their existing relative order.
- Do not add dependencies.
- Do not create commits because the repository index contains unrelated staged changes.

---

### Task 1: Add and document the sorter

**Files:**
- Create: `japanese/yomitan/sort-dictionaries.js`
- Create: `tests/yomitan-sort-dictionaries.js`
- Modify: `japanese/yomitan/README.md`

**Interfaces:**
- Produces: `sortDictionaries(dictionaries: Array<object>): {dictionaries: Array<object>, missing: Array<string>, unknown: Array<string>}`
- Uses in Yomitan: `Application.main`, `SettingsController.getOptionsFull`, `SettingsController.getOptions`, and `SettingsController.modifyProfileSettings`

- [ ] **Step 1: Write the failing test**

```js
const assert = require('node:assert/strict');
const {sortDictionaries} = require('../japanese/yomitan/sort-dictionaries.js');

const other = {name: 'Other', enabled: false, styles: 'unchanged'};
const result = sortDictionaries([
    {name: 'NHK', enabled: true},
    other,
    {name: 'KANJIDIC [2026-212]', enabled: true},
    {name: 'CC100', enabled: true},
    {name: 'JPDBv2㋕', enabled: true},
    {name: '日本語文法辞典(全集)', enabled: true},
    {name: '小学館例解学習国語 第十二版', enabled: true},
    {name: '新和英', enabled: true},
    {name: 'Jitendex.org [2026-07-09]', enabled: true},
]);

assert.deepEqual(result.dictionaries.map(({name}) => name), [
    'Jitendex.org [2026-07-09]',
    '新和英',
    '小学館例解学習国語 第十二版',
    '日本語文法辞典(全集)',
    'JPDBv2㋕',
    'CC100',
    'KANJIDIC [2026-212]',
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node tests/yomitan-sort-dictionaries.js`

Expected: FAIL because `japanese/yomitan/sort-dictionaries.js` does not exist.

- [ ] **Step 3: Implement the minimal sorter and browser integration**

Create `japanese/yomitan/sort-dictionaries.js` with eight named regular expressions, a pure `sortDictionaries` function, and a browser-only `run` function. The browser function must:

```js
const [{Application}, {SettingsController}] = await Promise.all([
    import('./js/application.js'),
    import('./js/pages/settings/settings-controller.js'),
]);

await Application.main(true, async (application) => {
    const controller = new SettingsController(application);
    const {profileCurrent} = await controller.getOptionsFull();
    controller.profileIndex = profileCurrent;
    const current = await controller.getOptions();
    const result = sortDictionaries(current.dictionaries);
    await controller.modifyProfileSettings([{action: 'set', path: 'dictionaries', value: result.dictionaries}]);
});
```

Guard browser execution with `if (typeof window !== 'undefined')` and export the pure function with `module.exports` when CommonJS is available. Throw before saving if one matcher finds multiple dictionaries or if the output length differs from the input length. Log missing configured dictionaries, unknown dictionaries, and the final order.

- [ ] **Step 4: Run the focused checks**

Run: `node tests/yomitan-sort-dictionaries.js`

Expected: PASS with no output.

Run: `node --check japanese/yomitan/sort-dictionaries.js`

Expected: exit 0.

- [ ] **Step 5: Document console usage**

Append this instruction to `japanese/yomitan/README.md`:

```markdown
After importing the dictionaries, open Yomitan's options-page developer console, paste `sort-dictionaries.js`, and press Enter. It orders the active profile and leaves unrecognized dictionaries at the end.
```

- [ ] **Step 6: Run repository verification**

Run: `./tests/bootstrap.sh`

Expected: exit 0.

Run: `git diff --check`

Expected: exit 0.

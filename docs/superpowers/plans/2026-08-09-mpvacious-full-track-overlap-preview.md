# Full-Track Overlap Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Include future secondary cues that overlap the selected primary timing window and preview the exact exported text in the OSD.

**Architecture:** Keep upstream's `collector` and `sub_list` responsible for joining, deduplication, and observed-cue overlap. Add one isolated full-track cache that returns text for the same `Subtitle` timing-window interface, then route card export and OSD preview through one observer resolver.

**Tech Stack:** Lua 5.1/LuaJIT, mpv Lua API, existing mpvacious subprocess/executable helpers, existing module-owned `run_tests()` convention.

## Global Constraints

- Do not cherry-pick or extract commit `4b95adb`; rewrite against current upstream.
- Do not modify PR #176 or include its commits in this feature branch.
- Do not open the draft PR until PR #176 is merged or otherwise resolved and this branch is rebased on the resulting `upstream/master`.
- Add no configuration option unless the maintainer requests one during draft-PR discussion.
- Card creation remains cache-only; it must never wait for a subprocess.
- Failure to load a complete track must retain upstream's observed-cue behavior.

---

### Task 1: Full secondary-track cache

**Files:**
- Create: `mpvacious/subtitles/full_track.lua`
- Modify: `tests/run.lua`

**Interfaces:**
- Consumes: `Subtitle`, `sub_list.new()`, `encoder.executables.ffmpeg`, `helpers.subprocess`
- Produces: `full_track.new(run_subprocess, read_file)` returning `refresh(track_list, media_path)` and `get_overlapping_text(window, delay)`

- [ ] **Step 1: Create a clean branch from current upstream**

```bash
git fetch upstream
git switch -c feat/full-track-secondary-overlap upstream/master
```

- [ ] **Step 2: Write failing module-owned tests**

Add `full_track.run_tests()` cases proving:

```lua
local window = Subtitle:from_text('', 1, 5)
h.assert_equals(cache.get_overlapping_text(window, 0), 'First line Second line')
h.assert_equals(cache.get_overlapping_text(window, 1), 'Delayed line')
```

Cover SRT parsing, ASS parsing, external-file synchronous loading, embedded-track asynchronous loading, stale callback rejection after a track change, and `nil` while no cache is ready.

Register only the module in `tests/run.lua`:

```lua
'subtitles.full_track',
```

- [ ] **Step 3: Run tests and verify the module is missing**

Run: `luajit tests/run.lua`

Expected: failure loading `subtitles.full_track`.

- [ ] **Step 4: Implement the cache against the merged timing-window API**

The public lookup must shift the selected window by subtitle delay and delegate joining/deduplication to `sub_list`:

```lua
local function get_overlapping_text(window, delay)
    if not loaded_subs then
        return nil
    end
    delay = delay or 0
    local shifted = Subtitle:from_text('', window.start - delay, window['end'] - delay)
    return loaded_subs.get_overlapping_text(shifted)
end
```

`refresh()` must synchronously parse readable external `.srt`, `.ass`, and `.ssa` files; otherwise it must asynchronously request the selected embedded stream as SRT through the existing ffmpeg executable resolver. Capture a generation number before starting the subprocess and discard callbacks whose generation no longer matches.

Return exactly:

```lua
return {
    refresh = refresh,
    get_overlapping_text = get_overlapping_text,
}
```

- [ ] **Step 5: Run the full suite**

Run: `luajit tests/run.lua`

Expected: all module tests pass.

- [ ] **Step 6: Commit the isolated cache**

```bash
git add mpvacious/subtitles/full_track.lua tests/run.lua
git commit -m "feat: cache complete secondary subtitle track"
```

---

### Task 2: Shared export and OSD resolver

**Files:**
- Modify: `mpvacious/subtitles/observer.lua`
- Modify: `mpvacious/main.lua`

**Interfaces:**
- Consumes: `full_track.new()`, `sub_list.get_overlapping_text(window)`
- Produces: `subs_observer.get_selected_secondary_text()` returning the exact text `collect_from_current()` will export

- [ ] **Step 1: Write failing observer tests**

Add module-owned cases for one resolver with cache preference and observed fallback:

```lua
h.assert_equals(resolve_secondary_text(cached, observed, window, 0), 'Future line')
h.assert_equals(resolve_secondary_text(empty_cache, observed, window, 0), 'Current line')
```

Also assert that `collect_from_current().secondary` and `get_selected_secondary_text()` return the same value for the same timing window.

- [ ] **Step 2: Run tests and verify failure**

Run: `luajit tests/run.lua`

Expected: failure because the shared resolver/accessor does not exist.

- [ ] **Step 3: Implement one observer resolver**

```lua
local function resolve_secondary_text(cache, observed, window, delay)
    local text = cache.get_overlapping_text(window, delay)
    if text ~= nil then
        return text
    end
    return observed.get_overlapping_text(window)
end
```

Build the current selection window once from `dialogs.get_text()` and `get_timing('start'/'end')`. Use the resolver from both `collect_from_current()` and the new public `get_selected_secondary_text()`. Preserve `all_secondary_dialogs` as the observed fallback for quick multi-line collection.

Initialize one cache in the observer and refresh it when `track-list` changes. Do not start or await work from either card creation or OSD rendering.

- [ ] **Step 4: Replace the raw OSD secondary list**

In `menu:print_selection()`, keep primary rendering unchanged and replace the loop over `recorded_secondary_subs()` with one resolved preview:

```lua
local secondary_text = subs_observer.get_selected_secondary_text()
if not h.is_empty(secondary_text) then
    osd:text(wrap_selected_for_osd(secondary_text)):newline()
end
```

If PR #176 is not yet present on upstream while developing, temporarily use `escape_for_osd()` locally. Before publishing, rebase after #176 and use its merged selected-text formatter rather than copying it.

- [ ] **Step 5: Run the full suite**

Run: `luajit tests/run.lua`

Expected: all tests pass.

- [ ] **Step 6: Commit the shared integration**

```bash
git add mpvacious/subtitles/observer.lua mpvacious/main.lua
git commit -m "feat: preview complete overlapping secondary text"
```

---

### Task 3: Rebase, install, and open the discussion PR

**Files:**
- Update live checkout: `configs/xdg/mpv/scripts/mpvacious/`
- No additional source files

**Interfaces:**
- Consumes: Tasks 1-2
- Produces: tested local installation and a draft upstream PR

- [ ] **Step 1: Rebase after PR #176 is resolved**

```bash
git fetch upstream
git rebase upstream/master
```

Resolve OSD formatting by calling the merged formatter; do not duplicate PR #176 code.

- [ ] **Step 2: Verify the publishable diff**

```bash
luajit tests/run.lua
git diff --check upstream/master...HEAD
git diff --stat upstream/master...HEAD
```

Expected: all tests pass; only the full-track cache, observer integration, module registration, and OSD preview are present.

- [ ] **Step 3: Install the exact tested files locally**

Apply the branch versions of changed mpvacious files to the ignored live checkout under `configs/xdg/mpv/scripts/mpvacious/`, then run its `luajit tests/run.lua` and compare each installed file with the branch.

- [ ] **Step 4: Manually verify the original scenario**

Open a Japanese cue whose timing spans at least two English cues, open the mpvacious menu before the later English cue appears, and confirm the OSD already shows both English cues. Create/update the card and confirm its secondary field exactly matches the preview.

- [ ] **Step 5: Push and open a draft PR**

Use this PR description:

```markdown
## Problem

One primary subtitle cue can span multiple secondary cues. PR #173 aligns
already-observed cues by timing, but pressing Ctrl+M before a later secondary
cue appears cannot include that future cue.

## Proposed behavior

Cache the selected complete secondary track asynchronously, use every cue that
overlaps the selected primary timing window, and show the exact resolved text
in the OSD before export. If the complete track cannot be loaded, retain the
existing observed-cue behavior. Card creation never waits for extraction.

## Discussion

This is a rewrite of the behavior omitted with commit 4b95adb; that commit was
not reused. Does this look-ahead behavior belong upstream? If so, should it be
always enabled with graceful fallback, or exposed as a configuration option?

Draft: feedback on the behavior and architecture is requested before merge.
```

Keep the PR in draft state until the maintainer confirms the behavior belongs upstream.

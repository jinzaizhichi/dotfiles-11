# Yomitan Dictionary Sorter

## Goal

Provide a JavaScript file that can be pasted into the developer console on Yomitan's options page to order the dictionaries in the currently selected profile.

## Behavior

The script orders these dictionaries:

1. Jitendex
2. 新和英
3. 小学館例解学習国語 第十二版
4. 日本語文法辞典(全集)
5. JPDB frequency
6. CC100 frequency
7. KANJIDIC
8. NHK2016 pitch accent

Versioned Jitendex and KANJIDIC titles are matched without pinning their dates. The script preserves every dictionary's existing options, including whether it is enabled. Dictionaries outside the configured order remain afterward in their existing relative order and are reported in the console.

## Implementation

Store the console script at `japanese/yomitan/sort-dictionaries.js`. Reuse Yomitan's options-page `Application` and `SettingsController` modules to read and update only the selected profile. Before saving, verify that the dictionary count is unchanged and that no configured matcher selected multiple dictionaries. Assign descending priorities to the resulting array and print its final order.

## Verification

Keep the ordering operation as a small pure function so it can be checked with sample dictionary objects outside Yomitan. Also run the repository bootstrap checks and JavaScript syntax validation.

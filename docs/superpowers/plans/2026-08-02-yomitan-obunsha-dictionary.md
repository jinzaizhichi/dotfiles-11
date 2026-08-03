# Yomitan Obunsha Dictionary Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the laggy 小学館 monolingual dictionary with the no-image 旺文社国語辞典 第十一版 archive.

**Architecture:** Reuse the existing manifest downloader and dictionary sorter. Change only the slot-03 archive and its references.

**Tech Stack:** Bash, JSON, JavaScript, ZIP

## Global Constraints

- Keep the existing eight-dictionary order.
- Use Google Drive file `1WhJk0gsgL2z_A6cYqIB7185EZd5GPvxs`.
- Use the no-image archive.

---

### Task 1: Replace the dictionary

**Files:**
- Modify: `japanese/yomitan/dictionaries.txt`
- Modify: `japanese/yomitan/settings.json`
- Modify: `japanese/yomitan/sort-dictionaries.js`
- Modify: `tests/yomitan-sort-dictionaries.js`
- Modify: `japanese/yomitan/README.md`
- Replace: `japanese/yomitan/dictionaries/03 *.zip`

- [x] **Step 1: Change the sorter test expectation to 旺文社 and run it to observe failure**
- [x] **Step 2: Update the sorter, manifest, settings export, and documentation**
- [x] **Step 3: Download the archive and verify `index.json` and its title**
- [x] **Step 4: Run sorter, bootstrap, syntax, and reference checks**

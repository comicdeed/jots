---
name: vala-code-review
description: >-
  Comprehensive, senior-level code review for Vala, GTK4, and Granite desktop applications.
  Audits memory management (reference cycles, weak references, GLib source removal), UTF-8 safety,
  Pango markup escaping, Vala/GTK4 idioms, and architectural boundaries.
---

# Senior Vala & GNOME Engineering Code Review

This skill defines the rigorous code review process for Vala, GTK4, and Granite applications (such as Jots). When activated, the agent operates as a Senior Vala / GNOME Systems Engineer prioritizing correctness, maintainability, memory safety, and performance.

---

## 🎯 Review Process

1. **Diff Scope Analysis**:
   - Inspect the complete changeset between the target base branch (`develop` or `main`) and `HEAD` (`git diff <base>...HEAD`).
   - Catalog all modified, added, and removed files.

2. **Systematic Checklist Auditing**:
   - Cross-examine the changes against each category in the [Audit Checklist](#-audit-checklist).

3. **Canary Test Suite Verification**:
   - Verify that new or modified unit tests are registered in the test runner (`tests/Main.vala`).
   - Run the test suite within the Flatpak sandbox:
     ```bash
     flatpak run --command=jots-unit-tests io.github.comicdeed.jots.devel
     ```

4. **Structured Review Report Output**:
   Produce a structured report with:
   - **Executive Summary**
   - **Strengths & Architecture Highlights**
   - **Detailed Findings & Recommendations** (Ranked by severity: 🔴 High, 🟡 Medium, 🟢 Low / Nit) with exact file/line references and concrete code fixes.
   - **Verdict / Sign-off Recommendation** (`APPROVED`, `REQUEST CHANGES`, or `BLOCKED`).

---

## 🔍 Audit Checklist

### 1. Memory Management & Signal Lifecycles
* [ ] **Circular References**: Ensure bidirectional dependencies (e.g., coordinators and services) use `weak` or `unowned` references to prevent reference-counting memory leaks.
* [ ] **GLib Source Removal**: All `GLib.Timeout.add()` / `GLib.Idle.add()` timers must be cleared (`Source.remove()`) on widget destruction (`~Destructor` / `dispose`).
* [ ] **Signal Disconnections & Unparenting**: Popovers and temporary floating widgets must be properly unparented (`popover.unparent()`) when their parent container is torn down.
* [ ] **Action Hijacking**: Ensure custom child widgets (e.g. checkbuttons, color pills) embedded in list rows do not intercept parent container clicks or activate unintended window actions.

### 2. UTF-8 & Character Slicing Safety
* [ ] **Byte vs. Character Offsets**: Vala `string.substring()` and `string.length` operate on *byte* offsets. Ensure string slicing never cuts mid-sequence through multibyte UTF-8 codepoints (emojis, umlauts, CJK).
* [ ] **Character Boundary Alignment**: Verify boundary adjustments step backward through continuation bytes (`(((uint8) str[pos]) & 0xC0) == 0x80`).
* [ ] **Null-Safe Collation**: Ensure `(a.title ?? "").collate(b.title ?? "")` protects against `null` strings during sorting.

### 3. Pango Markup & XML Entity Safety
* [ ] **Escaping Order**: Never apply regex replacements or string transformations on already-escaped XML strings (`Markup.escape_text`). Doing so corrupts entities (e.g., `&amp;` -> `&<b>amp</b>;`).
* [ ] **Highlighting Strategy**: Tokenize or find match intervals directly on unescaped text, escape matched and non-matched chunks independently, and enclose matches in `<b>...</b>`.

### 4. Vala & GTK4 Idioms & Architecture
* [ ] **GObject Properties**: Use standard Vala properties (`get; construct set;`) rather than ad-hoc getter/setter methods where applicable.
* [ ] **Boundary Decoupling**: Use lightweight interfaces or delegates (e.g., `ActiveNotesProvider`) rather than passing monolithic window managers into persistence or utility layers.
* [ ] **Guardrail Validation**: Validate MCP and D-Bus parameters against system limits (`MAX_NOTE_TITLE_LENGTH`, `MAX_NOTE_CONTENT_LENGTH`, `MAX_SEARCH_RESULTS`).
* [ ] **Deprecation Avoidance**: Check for modern GTK4 / Granite 7 replacements (e.g., `Granite.HeaderLabel.Size`, `Granite.CssClass`).

### 5. Test Rigor & Edge Cases
* [ ] **Boundary Conditions**: Tests cover empty strings, whitespace-only inputs, max-length limits, and special regex characters (`- [ ]`, `*`, `+`, `()`).
* [ ] **Identifier Uniqueness**: Use-case identifiers follow domain numbering without collisions (e.g., `/SearchService/UC_80_10_...`).

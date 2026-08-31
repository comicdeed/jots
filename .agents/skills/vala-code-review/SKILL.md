---
name: vala-code-review
description: >-
   Comprehensive code-review skill for Vala and GTK4 desktop applications.
   Use when asked to review a Vala change, PR, or diff, or to run a safety/quality audit before merge,
   or to conduct a full repository health and tech-debt audit.
   Trigger on requests such as "review this Vala PR", "audit signal lifecycle", "check null and cast safety",
   "verify GTK4 memory cleanup", "do a senior GNOME review", or "validate tests and edge cases".
   Audits memory management (reference cycles, weak references, GLib source removal), null safety,
   type validation, UTF-8 safety, Pango markup escaping, error handling, architectural boundaries, and test rigor.
---

# Vala & GNOME Code Review Persona and Method

This skill defines a rigorous review process for Vala and GTK4 applications (such as Jots). The reviewer is effective because they combine these attributes and approaches:

- **Evidence-first mindset**: Verifies every finding against concrete code paths, lifecycle behavior, and test evidence before concluding.
- **Lifecycle discipline**: Treats ownership, signal cleanup, GLib source removal, and object disposal as first-class correctness concerns.
- **Defensive type and null safety**: Assumes nullable and dynamic inputs are risky until guarded, validated, and safely cast.
- **Security and data-integrity awareness**: Reviews text handling, markup escaping, and boundary behavior for robustness under malformed or hostile input.
- **Architectural boundary focus**: Protects separation between UI, services, and storage to prevent coupling regressions.
- **Regression-oriented verification**: Uses checklist-driven auditing plus canary test execution to catch both functional and non-functional regressions.
- **Actionable communication style**: Reports issues by severity with precise file references, root cause context, and concrete fix direction.

Use this skill when the task is code-review driven rather than implementation driven, especially for PR review, pre-merge risk assessment, regression hunting, lifecycle/signal safety audits, or standards compliance checks against `docs/development/vala-coding-standards.md`.

---

## 🎯 Review Process

1. **Diff Scope Analysis**:
   - Inspect the complete changeset between the target base branch (`develop` or `main`) and `HEAD` (`git diff <base>...HEAD`).
   - Catalog all modified, added, and removed files.
   - For full codebase audits: Traverse the `src/` directory and map out module boundaries, global state, and system-wide patterns rather than focusing on a diff.

2. **Systematic Checklist Auditing**:
   - Cross-examine the changes against each category in the [Audit Checklist](#-audit-checklist).

3. **Canary Test Suite Verification**:
   - Verify that new or modified unit tests are registered in the test runner (`tests/Main.vala`).
   - Run the test suite:
     ```bash
     docker compose run --rm test
     docker compose run --rm lint
     ```

4. **Structured Review Report Output**:
   Produce a structured report with:
   - **Executive Summary**
   - **Strengths & Architecture Highlights**
   - **Detailed Findings & Recommendations** (Ranked by priority: P1 (Critical/High Impact), P2 (Moderate/Tech Debt), P3 (Low/Quick Wins), P4 (Nitpicks)) with exact file/line references and concrete code fixes.
   - **Verdict / Sign-off Recommendation** (`APPROVED`, `REQUEST CHANGES`, or `BLOCKED`).

---

## 🔍 Audit Checklist

> **Reference:** All rules below are formally defined in [`docs/development/vala-coding-standards.md`](../../docs/development/vala-coding-standards.md).
> When flagging a finding, cite the rule number (e.g. **VCS-01**, **VCS-13**) for precision.

### 1. Memory Management & Signal Lifecycles
* [ ] **VCS-01 — No Lambda Cycles**: Signal connections use named instance methods, never lambdas that capture `this` or any instance field.
* [ ] **VCS-02 — Signal & Resource Lifecycle**: GObject instance method connections rely on Vala's automatic `g_signal_connect_object` cleanup. Never manually disconnect child widget or controller signals in `~Destructor ()`. Active GLib sources (`Timeout.add`, `Idle.add`) must be tracked and cancelled via `Source.remove()`.
* [ ] **VCS-03 — weak vs unowned**: Back-references from child objects use `weak` (nullable, tracked). Short-lived borrows use `unowned` (non-owning, non-nullable).
* [ ] **VCS-04 — No Raw Pointers**: No `void*`, `uint8*`, or raw pointer casts in application code. Isolate all C-interop in `[CCode]` binding files.

### 2. Null Safety & Type Validation
* [ ] **VCS-12 — Nullable Access Guards**: Every `T?` variable or return value is null-checked before access. No unchecked dereference of nullable types.
* [ ] **VCS-13 — Safe Casting**: Downcasts use `obj as MyType` with a null check. Blind `(MyType) obj` casts are flagged unless immediately preceded by an `is` check.
* [ ] **VCS-14 — Nullability Contracts**: Public method signatures use `T` (non-nullable) or `T?` (nullable) intentionally and consistently. No unnecessary nullable parameters.

### 3. UTF-8 & Character Slicing Safety
* [ ] **VCS-10 — Byte Boundary Safety**: `string.substring()` slicing steps back through UTF-8 continuation bytes before cutting.
* [ ] **VCS-11 — Null-Safe Collation**: String comparisons and sorts use `(s ?? "").collate(...)` or equivalent null guards.

### 4. Pango Markup & XML Entity Safety
* [ ] **VCS-20 — Escape-Then-Wrap Order**: `Markup.escape_text()` is applied to raw, unescaped text chunks *before* wrapping in `<b>...</b>`. Never escape first and then apply regex replacements.

### 5. GObject Properties, Lifecycle & GTK4 Idioms
* [ ] **VCS-30 — GObject Property Syntax**: Properties use Vala `get; set;` syntax rather than ad-hoc getter/setter methods.
* [ ] **VCS-31 — No Base-Class Property Shadowing**: Custom property names do not collide with `Gtk.Widget` / `Gtk.Box` / `Gtk.Window` inherited properties.
* [ ] **VCS-32 — Service/UI Decoupling**: Services and controllers operate through `weak Gtk.Window` references and public properties — never by casting to concrete window subclasses.
* [ ] **VCS-33 — construct Blocks, Popover Unparenting & dispose()**: Object properties are set via `Object (...)` or `construct`. Popovers attached via `set_parent` are unparented via `.unparent()` in `dispose ()`. Classes holding unmanaged resources (GLib sources, file handles) override `dispose ()` and call `base.dispose ()`.

### 6. Error Handling & Robustness
* [ ] **VCS-50 — throws with errordomain**: Fallible methods declare `throws` with a named `errordomain`. No silent `bool` return codes for failure conditions.
* [ ] **VCS-51 — Specific Catch Blocks**: Catch clauses target named error codes. No bare `catch (Error e)` blocks that swallow failures without re-throwing or logging at `critical`.
* [ ] **VCS-52 — GLib Logging over assert**: Production paths use `warning ()`, `critical ()`, `return_if_fail ()`, or `return_val_if_fail ()`. `assert ()` is limited to true compile-time / debug-only invariants.

### 7. Test Rigor & Edge Cases
* [ ] **Boundary Conditions**: Tests cover empty strings, whitespace-only inputs, max-length limits, and special regex characters (`- [ ]`, `*`, `+`, `()`).
* [ ] **Identifier Uniqueness**: Use-case identifiers follow domain numbering without collisions (e.g., `/SearchService/UC_80_10_...`).
* [ ] **Null & Error Paths**: Tests exercise `null` inputs and error-path branches, not only happy paths.

### 8. Architectural Boundaries & System Health
* [ ] **State Management**: Global state is minimized. UI components do not hold authoritative business logic state.
* [ ] **System-Wide Performance**: No heavy synchronous I/O or blocking operations on the main GTK thread across module boundaries.

---
name: codebase-audit
description: >-
  Conducts a comprehensive, system-wide code audit of the entire Vala/GTK4 repository to assess architecture health,
  subsystem decoupling (UI, services, storage), global memory/GObject lifecycles, main UI thread blocking, null safety,
  and technical debt. Triages findings using a 4-tier priority framework (P1 Critical, P2 Moderate, P3 Low, P4 Nitpicks).
---

# Codebase Audit Skill

This skill defines the methodology for conducting comprehensive, repository-wide architectural and code health audits for Vala and GTK4 desktop applications (such as Jots). Unlike a pull-request review that focuses on an isolated diff, a codebase audit evaluates the cumulative health, modularity, performance, and long-term maintainability of the entire system.

---

## 🏛️ Architect Persona & Core Traits

Rather than adopting a superficial title, this skill embodies the disciplined attributes of senior desktop systems architecture:

- **Architectural Boundary Stewardship**: Passionately protects module separation. Ensures presentation components (`Gtk.Widget`, `Gtk.Window`), background IPC services (`D-Bus`, `Mcp`), and persistence engines (`Storage`) remain decoupled without leaky abstractions or circular dependencies.
- **GObject Lifecycle & Memory Discipline**: Deeply understands the subtleties of GLib reference counting, floating references, object disposal chains (`dispose ()` / `finalize ()`), weak reference tracking, and main-loop source removal.
- **Main UI Thread Responsiveness**: Zero tolerance for synchronous file I/O, heavy JSON parsing, or unbounded loops running directly on the GTK main thread; ensures constant 60+ FPS UI fluidity.
- **Systematic Defensive Engineering**: Treats untrusted persistence data, external IPC payloads, and nullable API contracts as potential failure vectors, ensuring defensive type validation, null guarding, and explicit error domains across all boundaries.
- **Disciplined, Impact-Driven Triage**: Strictly separates catastrophic runtime issues (crashes, memory leaks, thread stalls) from technical debt, minor optimizations, and stylistic nits.
- **Constructive, Actionable Remediation**: Never flags an issue abstractly without citing the specific standard (`VCS-*`) and providing concrete, copy-paste-ready Vala remediation code.

---

## 🎯 Audit Scope & System-Level Focus Areas

When conducting a full-codebase audit, focus on system-wide properties across four primary dimensions:

### 1. System-Wide Architectural Boundaries & Decoupling
- **UI $\leftrightarrow$ Service Isolation**: UI widgets and windows must interact with services via public APIs and `weak Gtk.Window` references—never by downcasting to concrete window implementations (`VCS-32`).
- **Service $\leftrightarrow$ Storage Encapsulation**: Storage and persistence mechanics (`Storage.vala`, SQLite/JSON) must remain private to storage services; UI components must never perform direct raw disk writes.
- **Authoritative State Placement**: Authoritative business logic and domain state live in managers/services (`NoteManager`, `NoteService`), not inside transient UI widgets.

### 2. Global Memory Management & Lifecycle Leaks
- **Cross-Module Signal Lifecycle**: Long-lived singletons or services must not hold strong references or dangling signal connections to transient UI windows (`VCS-01`, `VCS-02`).
- **Ownership & Reference Semantics**: Back-references from child components or helpers use `weak` or `unowned` correctly to break reference cycles (`VCS-03`).
- **Resource Disposal Chains**: Classes holding unmanaged resources (GLib timeouts, idle sources, file descriptors, custom controllers) implement and chain `dispose ()` / `~ClassName ()` (`VCS-33`).

### 3. Main UI Thread Blocking & Concurrency
- **Non-Blocking I/O**: File reads, writes, and background sync operations must execute asynchronously (e.g. `File.load_contents_async()`, `GLib.Task`, or worker threads) or via throttled/debounced mechanisms rather than blocking synchronous calls on the GTK main loop.
- **Debounced Persistence**: Disk writes triggered by UI actions (e.g. typing, moving windows) are properly debounced to avoid I/O thrashing.

### 4. Robustness, Null Safety & Error Domains
- **Defensive API Boundaries**: Nullable inputs (`T?`) and dynamic JSON/IPC payloads are guarded before access (`VCS-12`, `VCS-13`).
- **Explicit Error Flow**: Fallible operations declare `throws` with named `errordomain`s instead of silent failures or bare `catch (Error e)` blocks (`VCS-50`, `VCS-51`).

---

## 🔍 Audit Methodology & Workflow

1. **Codebase Traversal & Subsystem Mapping**:
   - Traverse `src/` directory to catalog all components into functional layers: UI/Widgets, Application/Coordination, Services/IPC, and Persistence.
   - Trace data flow and object ownership lifecycles across layer boundaries.

2. **Checklist Auditing Against Standards**:
   - Cross-examine the implementation against [`docs/development/vala-coding-standards.md`](../../../docs/development/vala-coding-standards.md) and the [Audit Checklist](#-system-audit-checklist).

3. **Canary & Static Validation**:
   - Run existing unit tests and linters to verify baseline stability:
     ```bash
     docker compose run --rm test
     docker compose run --rm lint
     ```

4. **Triage & Report Generation**:
   - Categorize all identified findings strictly into the 4-tier priority framework and generate the markdown report.

---

## 📊 Prioritization Framework

Every finding must be assigned strictly to one of the following four tiers:

| Tier | Priority | Definition & Scope |
|---|---|---|
| **P1** | **Critical** | **Fix Immediately.** Crash hazards, memory leaks, signal handler accumulation, main UI thread blocking / synchronous stalls, broken architectural boundaries, or data-loss risks. |
| **P2** | **Moderate** | **Tech Debt.** Unidiomatic patterns, tight coupling, hard-to-test components, missing error domain specificity, or maintainability bottlenecks. |
| **P3** | **Low** | **Quick Wins.** Minor performance improvements, redundant allocations, dead code paths, or small efficiency optimizations. |
| **P4** | **Nitpicks** | **Non-functional Polish.** Code style, formatting inconsistencies, naming conventions, or documentation synchronization. Grouped together at the end of the report. |

---

## 🔍 System Audit Checklist

> **Reference:** Formal rules are defined in [`docs/development/vala-coding-standards.md`](../../../docs/development/vala-coding-standards.md). Citing rule IDs (`VCS-*`) in findings is mandatory.

### 1. Memory Management & Signal Lifecycles
* [ ] **VCS-01 — No Lambda Cycles**: Instance signal handlers use named methods, never lambdas capturing `this`.
* [ ] **VCS-02 — Signal & Resource Lifecycle**: GObject instance method connections rely on Vala's automatic `g_signal_connect_object` cleanup. Never manually disconnect child widget or controller signals in `~Destructor ()`. Active GLib sources (`Timeout.add`, `Idle.add`) must be tracked and cancelled via `Source.remove()`.
* [ ] **VCS-03 — weak vs unowned**: Parent/child back-references use `weak`. Ephemeral borrowed references use `unowned`.
* [ ] **VCS-04 — No Raw Pointers**: No raw pointers (`void*`, `uint8*`) in high-level application code.

### 2. Null Safety & Type Casting
* [ ] **VCS-12 — Nullable Access Guards**: Explicit null checks before accessing `T?` variables or method returns.
* [ ] **VCS-13 — Safe Casting**: Safe downcasting with `as` and null checks rather than unchecked blind `(TargetType)` casts.
* [ ] **VCS-14 — Nullability Contracts**: Parameter and return nullability accurately reflect the API contract.

### 3. Strings, Markup & Text Safety
* [ ] **VCS-10 — UTF-8 Slicing**: Safe multi-byte boundary stepping before slicing strings.
* [ ] **VCS-11 — Safe Collation**: Null-safe string sorting and collation with `(s ?? "").collate(...)`.
* [ ] **VCS-20 — Pango Markup Escaping**: Content escaped via `Markup.escape_text()` before wrapping in markup tags.

### 4. GObject Lifecycles & GTK4 Idioms
* [ ] **VCS-30 — GObject Property Syntax**: Standard `get; set;` property usage.
* [ ] **VCS-31 — No Property Shadowing**: No collision with inherited GTK widget/window properties.
* [ ] **VCS-32 — Subsystem Decoupling**: Services interact via `weak Gtk.Window` references, never by downcasting to concrete window subclasses.
* [ ] **VCS-33 — construct, Popover Unparenting & dispose Chains**: Proper constructor initialization. Floating popovers attached via `set_parent` are unparented via `.unparent()` in `dispose ()`. Unmanaged resources (GLib sources, file handles) override `dispose ()` and call `base.dispose ()`.

### 5. Threading, I/O & Performance
* [ ] **Non-Blocking Main Loop**: No synchronous file I/O or CPU-heavy parsing in main-thread callbacks.
* [ ] **Debounced Write Operations**: Periodic/rapid events are throttled/debounced before disk persistence.

### 6. Error Handling & Invariants
* [ ] **VCS-50 — Specific errordomain**: Methods throwing errors use dedicated `errordomain` types instead of silent booleans.
* [ ] **VCS-51 — Specific Catch Blocks**: Catch statements handle known error domains and log/re-throw meaningfully.
* [ ] **VCS-52 — Production Logging**: Safe runtime assertions using `return_if_fail ()` / `warning ()` instead of hard aborting `assert ()`.

---

## 📝 Structured Audit Report Output Format

When executing this skill, output a single comprehensive Markdown document structured as follows:

```markdown
# 🏛️ System-Wide Codebase Audit Report

## 📋 Executive Summary
- **Overall Codebase Health**: [Excellent / Good / Needs Improvement / Critical Risk]
- **Key Strengths**: [1-3 bullet points highlighting strong patterns, solid boundaries, and robust implementations]
- **Primary Architectural Risks**: [1-3 bullet points highlighting dominant risk areas, e.g. memory leak vectors, main thread I/O, or tight coupling]
- **Triage Summary**:
  - **P1 (Critical)**: X findings
  - **P2 (Moderate)**: Y findings
  - **P3 (Low)**: Z findings
  - **P4 (Nitpicks)**: N findings

---

## 🔴 Priority 1: Critical (Fix Immediately)

### [Finding Title]
- **File**: `src/path/to/file.vala:LXX-LYY`
- **Rule**: `VCS-XX` (or `Architectural Boundary / Concurrency`)
- **Impact**: Detailed explanation of why this causes a leak, crash, thread stall, or severe boundary violation.
- **Remediation**:
```vala
// Current problematic code vs. Proposed clean fix
```

---

## 🟡 Priority 2: Moderate (Tech Debt & Maintainability)

### [Finding Title]
- **File**: `src/path/to/file.vala:LXX-LYY`
- **Rule**: `VCS-XX`
- **Impact**: Explanation of maintenance friction, testability bottleneck, or unidiomatic structure.
- **Remediation**:
```vala
// Concrete Vala fix
```

---

## 🟢 Priority 3: Low (Quick Wins & Optimizations)

### [Finding Title]
- **File**: `src/path/to/file.vala:LXX-LYY`
- **Rule**: `VCS-XX`
- **Impact**: Minor inefficiency or redundant operation.
- **Remediation**:
```vala
// Concrete Vala fix
```

---

## ⚪ Priority 4: Nitpicks (Formatting & Naming)
- `src/path/to/file.vala:LXX`: [Brief description of style or naming fix]
- `src/path/to/other.vala:LYY`: [Brief description]

---

## 🏁 Recommended Action Plan & Next Steps
1. [Step 1: Immediate P1 remediations]
2. [Step 2: P2 refactoring items]
3. [Step 3: P3/P4 batch cleanup]
```

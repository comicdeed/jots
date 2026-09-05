# UI and UX Guidelines

A compact, evolving reference for interface decisions in Jots.

---

## 1. Purpose and Scope

This guide defines shared UI and UX principles for contributor-facing design and implementation decisions. It is intentionally concise and should expand only when repeated decisions need permanent guidance.

---

## 2. Design Principles

* Keep Jots fast, calm, and local-first.
* Prefer clear defaults over proliferating settings.
* Favor reversible actions and explicit system state.
* Keep controls close to the workflow they affect.
* Prefer lightweight GTK-native patterns over heavy abstractions.

### UI Responsiveness Rules

The GTK main loop must remain responsive during all user-visible operations.

1. External commands (for example Git) must execute asynchronously or in background workers.
2. File or network work that can exceed instant latency must never block the UI thread.
3. Long-running work must publish status updates so users understand progress.

---

## 3. Settings & Preferences Policy

Add a new persistent preference only when one default cannot serve materially different user needs.

Before adding a new preference, verify all of the following:

1. The need is frequent, not edge-case only.
2. Behavior cannot be auto-detected or inferred reliably.
3. Existing controls cannot absorb the behavior clearly.
4. The added state has a clear owner and test plan.

---

## 4. Information Architecture Rules

* Group by user intent, not implementation internals.
* Keep high-frequency controls one interaction away.
* Place advanced or future-facing controls behind clear section labels.
* Preserve stable ordering between releases to reduce relearning.

---

## 5. States and Feedback

* Disabled controls must state why they are disabled.
* Long-running operations must expose status text, not silent waiting.
* Error messages should provide the next local action when possible.

---

## 6. Accessibility Baseline

* Every interactive row must have a clear visible label.
* Keyboard traversal must follow top-to-bottom visual order.
* Avoid color-only communication for status.

---

## 7. UI Change Checklist

For any PR that changes UI behavior or information architecture:

1. Verify this guide still applies or update it minimally.
2. Update the user guide when user-visible behavior changes.
3. Include concise before/after screenshots or equivalent behavior notes.

---

## 8. Canvas and Chrome Styling Standards

### Scrolled Window Canvas Edges & Overflow Overlays
* **Zero Fog Overlays**: In GTK4, `GtkScrolledWindow` allocates a default ~40px bounding box for `undershoot` gadgets regardless of CSS `min-height`, which causes background gradients to render as heavy, unnatural bands over text. Sticky note canvases must set `undershoot` and `overshoot` elements to `background: none; border: none;`, relying on clean transparent floating scrollbars.
* **Minimal Floating Scrollbars**: Scrollbar sliders must be thin (4-5px), transparent when idle, and subtly tinted to `alpha(currentColor, 0.25)` so they float cleanly over any theme color without visual clutter.

### Header Bar & Window Title Interactions
* **Respect Native Window Gestures**: Never replace `Gtk.HeaderBar` with custom drag controllers (`begin_move_drag`) to suppress window manager double-click maximization. Custom window drag grabs interfere with child focus and cursor placement in `Gtk.EditableLabel`.
* **Header Dismissal**: When the title is in active edit mode, intercepting clicks on the empty header background via `headerbar.pick (x, y)` allows dismissing the edit mode cleanly (`editing = false`) without capturing or distorting standard titlebar double-click gestures.
* **Pill-Shaped Title Focus**: Active title editing should use subtle rounded pill backgrounds (`border-radius: 6px`) rather than harsh rectangular bounding boxes, and override text shadows in dark mode (`text-shadow: none`) to keep title text crisp.

### Action Bar & Chrome Normalization
* **Relative Color Contrast (`alpha(currentColor, ...)` vs. hardcoded `rgba`)**: Interactive surface highlights (hover, focus, active editing pills) on tinted or themed windows must always use `alpha(currentColor, <alpha>)` instead of hardcoded `rgba(0,0,0,...)` or `rgba(255,255,255,...)`. Hardcoded white/black breaks when switching between pastel (light), vibrant (dark mode default with dark text), and ultra-dark (dark mode with light text). `currentColor` automatically adapts highlight contrast across all palettes.
* **Border-Free Hover Highlights**: Action bar buttons (`Gtk.Button` and `Gtk.MenuButton`) must share a single CSS normalization baseline that strips default GTK4/Adwaita hover borders, box-shadows, and background gradients (`box-shadow: none; border: none; outline: none;`). Hover and focus states must strictly use borderless `alpha(currentColor, 0.2)` with `border-radius: 6px`.
* **Shallow, Resilient CSS Selectors for Icon Color Inheritance**: Never use rigid DOM-path selectors (e.g. `.themedbutton > button > box > image`) for icon recoloring. Use robust class-scoped selectors (`actionbar image`, `.themedbutton image`, `.themedbutton button image`) ensuring runtime palette changes cascade immediately without requiring app restarts.

---

## 9. Component Modularization (The Multi-Element Factory Principle)

When a container or view includes **two or more UI elements sharing the same visual role or interaction pattern** (e.g., action bar buttons, preference rows, dialog entries, menu items, or toolbar tools):

1. **Centralized Factory Construction**: Instantiate them through a dedicated helper factory method (e.g. `create_action_button()`, `create_menu_button()`, `create_preference_row()`) or a reusable sub-widget component rather than manual, inline property configuration.
2. **Single Source of Truth for Properties**: Common dimensions, framing (`has_frame = false`), style classes (`STYLE_THEMEDBUTTON`), accessibility labels, and accelerator tooltips must be configured in the factory to guarantee absolute visual and behavioral parity.
3. **Encapsulate Hierarchy Asymmetries**: When elements wrap internal sub-hierarchies (e.g. `Gtk.MenuButton` containing a nested `Gtk.Button` vs. standalone `Gtk.Button`), encapsulate the structural details inside the factory and normalize their CSS selectors so external callers and themes treat them uniformly.


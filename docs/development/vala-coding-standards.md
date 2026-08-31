# Vala Coding Standards for Jots

This guide distils the recurring issues found across code reviews on this codebase into standing rules. Read it before writing any new widget, service, or signal connection.

---

## 1. Signal Lifecycle — The Most Common Source of Memory Leaks

### Rule VCS-01 · Never Connect Signals with Lambdas That Capture `this`

**Why it matters:** A lambda that references `this` (directly or implicitly through any field or method) creates a strong reference from the signal source back to the connecting object. Combined with GObject's reference-counting, this forms a cycle that prevents both objects from ever being freed.

❌ **Wrong — creates a reference cycle:**
```vala
switch_widget.notify["active"].connect (() => {
    toggled (switch_widget.active);   // captures switch_widget AND this
});

popover.readonly_toggled.connect ((active) => {
    this.is_readonly = active;        // captures this
});
```

✅ **Correct — use a named instance method:**
```vala
switch_widget.notify["active"].connect (on_switch_active_changed);

private void on_switch_active_changed () {
    toggled (switch_widget.active);
}
```

**When lambdas *are* safe:** Lambdas that capture only local variables or primitive values (not `this`, not fields) are fine.

---

### Rule VCS-02 · Vala Signal Lifecycles & GTK4 Widget Ownership

Understand how `valac` and GTK4 manage signal connections to avoid both memory leaks and fatal double-disconnection crashes:

1. **Automatic Lifetime Management (`g_signal_connect_object`)**:
   When connecting an instance method of a target GObject to a signal (e.g. `source.signal.connect (this.on_signal)` or `source.signal.connect (controller.on_event)`), the Vala compiler generates:
   ```c
   g_signal_connect_object (source, "signal-name", (GCallback) on_signal, self, 0);
   ```
   `g_signal_connect_object` tracks `self` via a weak reference and **automatically unhooks the signal handler the moment `self` is finalized**.
   - ❌ **Do NOT manually call `disconnect ()` in `~Destructor ()` for standard instance methods on child widgets or GObjects.** Calling `disconnect` in `finalize` attempts to remove an already-cleared handler ID, emitting `GLib-GObject-CRITICAL **: instance ... has no handler with id` and corrupting GObject's internal signal handler table.

2. **GTK4 Widget & EventController Ownership**:
   - In GTK4, container widgets own their child widgets and attached `Gtk.EventController`s (`GestureClick`, `EventControllerKey`, `EventControllerScroll`, etc.).
   - When a parent widget or window is destroyed/disposed, GTK4 recursively destroys and disconnects all attached controllers. Never add manual `.disconnect ()` calls for internal child widgets or controllers in `~Destructor ()`.

3. **When Explicit Disconnection IS Required**:
   - **GLib Event Loop Sources**: Raw timers and idles (`Timeout.add`, `Idle.add`) return raw `uint source_id`s managed by `GMainContext`, not GObject. Store them (`private uint timeout_id = 0;`) and always cancel them (`if (timeout_id != 0) { Source.remove (timeout_id); timeout_id = 0; }`) in `dispose ()` or `~Destructor ()`.
   - **External Long-Lived Objects with Dynamic Lifecycles**: If a widget needs to disconnect from a long-lived service or static singleton *before* the widget itself is destroyed, retain the `ulong handler_id` and disconnect explicitly.

**Teardown Checklist for Widgets & Windows:**
- [ ] Active `GLib.Timeout.add()` / `GLib.Idle.add()` source IDs are cancelled with `GLib.Source.remove()`.
- [ ] Popovers attached via `popover.set_parent (widget)` are unparented via `popover.unparent()` inside `public override void dispose ()` (see `VCS-33`).
- [ ] No redundant `.disconnect()` calls in `~Destructor ()` on child widgets or controllers owned by the container.

---

### Rule VCS-03 · Use `weak` for Nullable Back-References, `unowned` for Borrows

These are **not interchangeable**:

| Keyword | Semantics | When to use |
|---|---|---|
| `weak` | Nullable tracked reference. Does **not** increment the ref-count. Becomes `null` when the referent is freed. | Back-references from child objects to parent GObjects (e.g. controller → window). |
| `unowned` | Non-nullable untracked borrow. No ref-count change. The compiler does not zero it on free. | Short-lived borrows of stack values, string literals, `unowned string` parameters, `unowned` array elements. |

```vala
// Child controller holding a back-reference to its owning window
private weak Gtk.Window window;      // ← weak: safe if window is freed first

// Method borrowing a string without taking ownership
private void log_title (unowned string title) { ... }

// Iterating an unowned slice of a list
unowned List<NoteData> items = note_list.data;
```

**Never** use a plain (strong) reference for a back-reference — it will create a retention cycle.

---

### Rule VCS-04 · No Raw Pointer Usage Outside C-Binding Layers

Raw pointer types (`void*`, `uint8*`, type casts through `(void*)`) bypass GObject reference counting entirely. They must only appear inside explicit C-interop wrappers (e.g. `[CCode]`-annotated bindings).

❌ **Wrong — raw pointer in application logic:**
```vala
void* raw = (void*) my_object;
```

✅ **Correct — use typed references, `weak`, or `unowned` instead.**

If a C library API demands a raw pointer, isolate it inside a dedicated binding file and never let it escape into application code.

---

### Rule VCS-05 · Stateless Modifier Event Inspection

Never track keyboard modifiers (e.g. <kbd>Ctrl</kbd>, <kbd>Shift</kbd>, <kbd>Alt</kbd>) using mutable static or instance boolean variables updated across `key-pressed` and `key-released` signals. Popover focus shifts, Alt-Tab window changes, and modal grabs can cause `key-released` signals to be dropped by the window manager, leaving modifier states permanently stuck (e.g. perpetual scroll zoom).

❌ **Wrong — stateful modifier tracking across signals:**
```vala
private static bool is_control_pressed = false;

key_controller.key_pressed.connect ((keyval) => {
    if (keyval == Gdk.Key.Control_L) is_control_pressed = true;
});
key_controller.key_released.connect ((keyval) => {
    if (keyval == Gdk.Key.Control_L) is_control_pressed = false; // often dropped!
});
```

✅ **Correct — query event modifier state directly on demand:**
```vala
scroll_controller.scroll.connect ((dx, dy) => {
    var state = scroll_controller.get_current_event_state ();
    bool is_ctrl = (state & Gdk.ModifierType.CONTROL_MASK) != 0;
    if (is_ctrl) {
        // perform zoom
    }
});
```

---

## 2. Null Safety & Type Validation

### Rule VCS-12 · Check All Nullable Types Before Access

Any variable or return value typed `T?` (nullable) **must** be explicitly null-checked before dereferencing. The Vala compiler enforces this for owned types but may not catch all cases with `unowned` or `weak` references.

❌ **Wrong — unchecked nullable access:**
```vala
NoteData? data = storage.load (id);
string title = data.title;           // crash if data is null
```

✅ **Correct — explicit null guard:**
```vala
NoteData? data = storage.load (id);
if (data == null) {
    warning ("Note %s not found", id);
    return;
}
string title = data.title;
```

For short-lived expressions, the null-coalescing operator is acceptable:
```vala
string label = note.title ?? _("Untitled");
```

---

### Rule VCS-13 · Use Safe Casting (`as`) — Never Blind Casting

Direct casting `(MyType) obj` will **abort the process** at runtime if `obj` is not actually `MyType`. Always use `as` for downcasts and immediately null-check the result.

❌ **Wrong — blind cast, will crash at runtime on type mismatch:**
```vala
var win = (StickyNoteWindow) widget;
win.is_readonly = true;
```

✅ **Correct — safe cast with null guard:**
```vala
var win = widget as StickyNoteWindow;
if (win == null) {
    return;
}
win.is_readonly = true;
```

The only place a direct cast is acceptable is after an explicit `is` check in the same scope:
```vala
if (widget is StickyNoteWindow) {
    var win = (StickyNoteWindow) widget;   // safe: type already confirmed
}
```

---

### Rule VCS-14 · Define Nullability Contracts in Public APIs

Public method signatures must make their nullability intent explicit. A non-nullable parameter is a contract: callers must not pass `null`. A nullable return type is a contract: callers must handle the `null` case.

```vala
// Contract: id must never be null; may return null if not found
public NoteData? find_note (string id) { ... }

// Contract: both arguments are required
public void save_note (string id, string content) { ... }
```

Never accept `string?` when `string` is sufficient — it forces every caller to null-check unnecessarily.

---

## 3. UTF-8 & String Safety

### Rule VCS-10 · Never Slice Strings by Byte Index Without Boundary Checks

Vala's `string.substring(start, len)` and `string.length` operate on **byte** offsets, not Unicode character offsets. Slicing mid-sequence through a multibyte codepoint (emoji, umlauts, CJK) corrupts the string and can crash Pango rendering.

❌ **Wrong:**
```vala
string snippet = content.substring (0, 200);  // may cut mid-emoji
```

✅ **Correct — step back through UTF-8 continuation bytes:**
```vala
int pos = 200;
while (pos > 0 && (((uint8) content[pos]) & 0xC0) == 0x80) {
    pos--;
}
string snippet = content.substring (0, pos);
```

### Rule VCS-11 · Null-Safe String Comparisons

Always guard against `null` when comparing or sorting strings:

```vala
// Sorting
list.sort ((a, b) => (a.title ?? "").collate (b.title ?? ""));

// Equality
if ((note.title ?? "") == "") { ... }
```

---

## 4. Pango Markup & XML Safety

### Rule VCS-20 · Escape Before Marking Up — Never the Reverse

The correct order is:
1. Find match intervals on the **raw, unescaped** string.
2. Split the string into matched and unmatched chunks.
3. `Markup.escape_text()` **each chunk separately**.
4. Wrap matched chunks in `<b>...</b>`.
5. Concatenate.

❌ **Wrong — escaping then applying regex corrupts entities:**
```vala
string escaped = Markup.escape_text (content);
// Applying bold regex on escaped string will corrupt &amp; → &<b>amp</b>;
escaped = escaped.replace (query, "<b>%s</b>".printf (query));
```

✅ **Correct — escape chunks independently:**
```vala
var builder = new StringBuilder ();
// For each interval [start, end]:
builder.append (Markup.escape_text (content.substring (prev, start - prev)));
builder.append ("<b>");
builder.append (Markup.escape_text (content.substring (start, end - start)));
builder.append ("</b>");
```

---

## 5. GObject Properties, Lifecycle & GTK4 Idioms

### Rule VCS-30 · Prefer Standard GObject Properties Over Custom Getters/Setters

Use Vala's property syntax so that GSettings binding, notify signals, and GObject introspection work correctly:

```vala
// Preferred
public bool monospace { get; set; default = false; }

// Acceptable when side-effects are needed
private bool _monospace;
public bool monospace {
    get { return _monospace; }
    set {
        _monospace = value;
        update_css ();
    }
}
```

### Rule VCS-31 · Avoid Property Name Collisions with GTK Widget Base Class

Check `Gtk.Widget`, `Gtk.Box`, `Gtk.Window` property lists before naming your own. Common collisions seen in this codebase:

| Collision to avoid | Use instead |
|---|---|
| `is_sensitive` on a `Gtk.Box` subclass | `row_sensitive` |
| `visible` on a `Gtk.Widget` subclass | `note_visible` / `always_visible` |
| `name` on a `Gtk.Widget` subclass | `note_id` / `label_text` |

### Rule VCS-32 · Decouple Services From UI Layers

Controllers (`ScribblyController`, `ZoomController`, `ColorController`) **must not** import or cast to concrete window types. They should operate through:
- Weak `Gtk.Widget` / `Gtk.Window` references.
- Public properties set by the owner (e.g. `scribbly_controller.always_visible = true`).

This keeps services testable without GTK widgets.

### Rule VCS-33 · Use `construct` Blocks and Override `dispose()` for Unmanaged Resources

**Object initialisation:** Set GObject properties via `Object (...)` or a `construct` block, not in the body of a parameterised constructor. This ensures properties are set before any `construct`-dependent logic runs.

```vala
// Preferred — properties set atomically before construct runs
public ToggleRow (string label_text) {
    Object (
        orientation: Gtk.Orientation.HORIZONTAL,
        spacing: SPACING_DOUBLE,
        hexpand: true
    );
}
```

**Unmanaged resource cleanup & GtkPopover Unparenting:** Override `dispose ()` when the widget manages popovers or timer sources. In GTK4, floating popovers attached via `popover.set_parent (widget)` must be unparented during `dispose ()` *before* the container widget finalizes.

```vala
public override void dispose () {
    if (search_popover != null) {
        search_popover.unparent ();
        search_popover = null;
    }

    if (timeout_id != 0) {
        GLib.Source.remove (timeout_id);
        timeout_id = 0;
    }
    base.dispose ();   // ← always call base
}
```

**`dispose ()` vs `~ClassName ()` Lifecycle:**
- Use `public override void dispose ()` for GTK4 widget teardown (e.g. `popover.unparent ()`) and canceling active GLib timer sources while the widget hierarchy is still intact.
- Use `~ClassName ()` only for lightweight logging or resetting unmanaged non-GObject native memory. Never call `unparent ()` or `.disconnect ()` on child GObjects in `~ClassName ()`.

---

### Rule VCS-34 · Guard Custom TextBuffer Mutations in Read-Only Mode

Setting `Gtk.TextView.editable = false` only disables interactive keyboard entry at the view level; the underlying in-memory `Gtk.TextBuffer` remains fully mutable to programmatic calls. Any custom handlers or shortcuts that call `buffer.insert()` or `buffer.delete()` directly (e.g. list auto-continuation on <kbd>Enter</kbd>, smart paste, formatting toggles, or emoji popover insertion) **must** check `if (!editable) return;` / `if (!textview.editable) return;` before touching the buffer.

❌ **Wrong — custom handler mutates buffer directly without checking view state:**
```vala
private bool on_key_pressed (uint keyval, ...) {
    if (keyval == Gdk.Key.Return) {
        buffer.insert_at_cursor ("\n- ", -1); // bypasses textview.editable = false!
        return true;
    }
    return false;
}
```

✅ **Correct — guard all programmatic modifications:**
```vala
private bool on_key_pressed (uint keyval, ...) {
    if (!editable) {
        return false;
    }
    if (keyval == Gdk.Key.Return) {
        buffer.insert_at_cursor ("\n- ", -1);
        return true;
    }
    return false;
}
```

---

## 6. Error Handling & Robustness

### Rule VCS-50 · Use `throws` with an Explicit `errordomain`

Methods that can fail must declare `throws` with a named `errordomain`. This forces callers to handle failures explicitly and enables granular catch logic.

❌ **Wrong — failure is silent or requires inspecting a `bool` return:**
```vala
public bool load_note (string id) {
    // returns false on failure, reason unknown
}
```

✅ **Correct — typed error propagation:**
```vala
errordomain StorageError {
    NOT_FOUND,
    CORRUPT,
    IO_ERROR
}

public NoteData load_note (string id) throws StorageError {
    if (!file.query_exists ()) {
        throw new StorageError.NOT_FOUND ("Note %s not found".printf (id));
    }
    // ...
}
```

---

### Rule VCS-51 · Catch Specific Errors — Never Swallow Failures

Catch blocks must handle or re-throw named error codes. A bare `catch (Error e)` that only prints and continues silently hides bugs.

❌ **Wrong — swallowing all errors indiscriminately:**
```vala
try {
    data = storage.load_note (id);
} catch (Error e) {
    // silently ignored
}
```

✅ **Correct — handle specific cases, propagate or log the rest:**
```vala
try {
    data = storage.load_note (id);
} catch (StorageError.NOT_FOUND e) {
    data = get_default_cheatsheet_data ();
} catch (StorageError e) {
    critical ("Storage failure loading %s: %s", id, e.message);
}
```

---

### Rule VCS-52 · Use GLib Logging — Never `assert()` in Production Paths

`assert ()` aborts the process unconditionally in all build types, including Flatpak releases. Use GLib logging mechanics instead so failures are reported without crashing.

| Severity | Macro | Behaviour |
|---|---|---|
| Fatal precondition (dev only) | `assert ()` | Abort (only for true invariants in debug builds) |
| Critical internal bug | `critical ()` | Logs + continues (does not abort in release) |
| Recoverable warning | `warning ()` | Logs at WARNING level |
| Precondition with early return | `return_if_fail (cond)` | Returns from void function if `cond` is false |
| Precondition with return value | `return_val_if_fail (cond, val)` | Returns `val` if `cond` is false |

```vala
// ✅ Correct — graceful failure in production
public void open_note (string? id) {
    return_if_fail (id != null);      // exits early, logs, does not crash
    // ...
}

// ❌ Wrong — crashes the Flatpak in production
public void open_note (string? id) {
    assert (id != null);
}
```

---

## 7. Architectural Guardrails

### Rule VCS-40 · Enforce Constant Limits at Boundaries

All user-supplied content must be clamped **at ingestion**, not at display:

```vala
// In NoteManager / NoteService / McpProtocol
if (content.length > MAX_NOTE_CONTENT_LENGTH) {
    content = content.substring (0, MAX_NOTE_CONTENT_LENGTH);
}
```

Constants live in `src/Constants.vala`. Never hard-code limits inline.

### Rule VCS-41 · Storage Layer Is Private

`Storage.vala` is the single source of truth for persistence. No other class reads or writes note files directly. External callers go through `NoteManager` → `Storage`.

---

## Quick Reference Card

| Rule | Summary |
|---|---|
| **VCS-01** | No lambdas capturing `this` in signal connections |
| **VCS-02** | Every `connect()` has a matching `disconnect()` in `~Destructor` |
| **VCS-03** | `weak` for nullable back-refs; `unowned` for non-owning borrows |
| **VCS-04** | No raw pointers (`*`) outside C-binding layers |
| **VCS-05** | Inspect event controller modifier states statelessly; never store mutable key booleans |
| **VCS-12** | Check all `T?` nullable values before access |
| **VCS-13** | Use safe `as` casting; never blind `(Type)` downcasts |
| **VCS-14** | Public API signatures declare nullability contracts explicitly |
| **VCS-10** | String slicing checks UTF-8 byte boundaries |
| **VCS-11** | Null-guard all string comparisons and sorts |
| **VCS-20** | Escape text chunks *before* wrapping in Pango markup |
| **VCS-30** | Use GObject property syntax; bind to GSettings where applicable |
| **VCS-31** | Never shadow a `Gtk.Widget` base-class property name |
| **VCS-32** | Services must not cast to concrete window types |
| **VCS-33** | Use `Object(...)` / `construct` for init; `dispose()` for unmanaged resources |
| **VCS-34** | Guard custom `TextBuffer` programmatic mutations when view `editable == false` |
| **VCS-40** | Clamp all user content to `MAX_*` constants at ingestion |
| **VCS-41** | All file I/O routes through `Storage.vala` only |
| **VCS-50** | `throws` with a named `errordomain` for fallible methods |
| **VCS-51** | Catch specific error codes; never swallow failures silently |
| **VCS-52** | GLib logging (`warning`, `critical`, `return_if_fail`) not `assert()` in production paths |

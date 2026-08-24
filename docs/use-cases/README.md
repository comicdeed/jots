# Jots Use-Case Library

Functional contracts, behavioral specifications, and edge cases across the Jots application.

---

## Numbering Scheme & Conventions

All use cases follow a hierarchical decimal structure to allow additions without renumbering existing references:

`UC-[DOMAIN].[FEATURE].[SCENARIO]`

* **`DOMAIN` (2 digits)**: Major subsystem or functional boundary.
* **`FEATURE` (2 digits)**: Specific capability within the domain, incremented by 10 (`10`, `20`, `30`...).
* **`SCENARIO` (2 digits)**: Concrete execution path, incremented by 10 (`10`, `20`...). Odd numbers (`11`, `21`...) denote error handling and boundary edge cases.

---

## Domain Navigation

| Domain | Document | Scope & Key Behaviors |
| :--- | :--- | :--- |
| **`UC-10`** | [10-note-lifecycle.md](10-note-lifecycle.md) | Window spawning (`Ctrl+N`), first-run fallback, note deletion (`Ctrl+W`), and undo restoration (`Ctrl+R`). |
| **`UC-20`** | [20-data-persistence.md](20-data-persistence.md) | JSON serialization/deserialization, disk storage I/O, legacy data migration, and debounced auto-saving. |
| **`UC-30`** | [30-text-editing.md](30-text-editing.md) | Custom `TextBuffer` formatting, bullet prefixes (`-`, `*`, `1.`), hanging indentation, and keypress handling (`Enter`/`Backspace`). |
| **`UC-40`** | [40-hyperlink-content.md](40-hyperlink-content.md) | `HyperTextView` URL and email detection, Unicode-safe offset calculations, debounce buffer scans, and `Ctrl+Click` interactions. |
| **`UC-50`** | [50-theming-appearance.md](50-theming-appearance.md) | The 10 pastel color themes, random theme generation, dark mode styling overrides, and environment variable flags. |
| **`UC-60`** | [60-global-settings.md](60-global-settings.md) | GSettings bindings, action bar hiding (`Ctrl+T`), scribbly blur effect (`Ctrl+H`), and XDG autostart portal integration. |

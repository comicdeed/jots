# Documentation Style Guide

This project follows the [GNOME Developer Documentation Style Guidelines](https://developer.gnome.org/documentation/guidelines/devel-docs.html). All technical documentation, use-case specifications, and docstrings must adhere to these conventions.

---

## 1. Voice and Tone

* **Get to the point**: Present the primary information first in the most prominent location. Make steps and decisions obvious up front.
* **Direct and conversational**: Write clearly and approachably. Avoid kindergarten preambles, marketing fluff, and cutesy filler.
* **Keep it simple**: Use short, scannable sentences. Layer information progressively so readers can stop once they have what they need.
* **Eliminate conversational noise**: Do not use placeholder phrases (*"please note"*, *"at this time"*), internet slang (*"tl;dr"*), or trivializing language (*"simply"*, *"just"*, *"easily"*, *"quickly"*). Avoid exclamation marks in technical copy.

---

## 2. Inclusive & Global Audience

* **Global clarity**: Assume English may not be the reader's first language. Write in short sentences, avoid idioms, and prefer lists/tables over dense paragraphs with multiple clauses.
* **Active voice**: Favor active voice over passive constructions (*"NoteManager creates the window"* rather than *"The window is created by NoteManager"*).
* **Pronouns**: Use second person (*you*) or direct imperative. Avoid first-person pronouns (*I*, *we*, *us*, *our*) except when referring to the project/organization. Use singular *they/their* when gender is unspecified.

---

## 3. Formatting & Typography

* **Capitalization**: Use Title Case only for top-level page headers (`# Title`). Use sentence-style capitalization for all section headings (`## Section heading`) and table headers.
* **Numbers**: Spell out numbers zero through nine; use digits for numbers 10 and above. Always use numerals for dimensions, units, and code constants (`250px`, `100ms`, `5`).
* **Code & symbols**:
  * Use inline code formatting (`` `code` ``) for class names, method names, signals, properties, file paths, and CSS classes.
  * Use *italics* for parameter names and placeholders.
  * Never pluralize type names directly in code style (write "`StickyNoteWindow` instances", not "`StickyNoteWindows`").
* **Dates & times**: Use ISO-8601 (`YYYY-MM-DD`) for numeric dates.

---

## 4. API & Code Comment Conventions

* **Callable descriptions**: Start with a present-tense verb describing the action, using the symbol name as the unstated subject:
  * Getter returning boolean: *"Checks whether..."*
  * Getter returning value: *"Retrieves the..."* or *"Gets the..."*
  * Setter: *"Sets the..."*
  * State update: *"Updates the..."*
  * Deletion: *"Removes the..."* or *"Deletes the..."*
  * Constructor: *"Creates a new..."*
* **Parameters & return values**: Keep descriptions concise:
  * Boolean state: *"true if...; false otherwise"* (lowercase, unformatted in text).

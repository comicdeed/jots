# UI and UX Guidelines

A compact, evolving reference for interface decisions in Jots.

---

## 1. Purpose and Scope

This guide defines shared UI and UX principles for contributor-facing design and implementation decisions. It is intentionally concise and should expand only when repeated decisions need permanent guidance.

---

## 2. Core Ethos

* Keep Jots fast, calm, and local-first.
* Prefer clear defaults over growing preference surfaces.
* Favor reversible actions and explicit system state.
* Keep controls close to the workflow they affect.
* Prefer lightweight GTK-native patterns over heavy abstractions.

### Responsiveness Pillar

The GTK main loop must remain responsive during all user-visible operations.

1. External commands (for example Git) must execute asynchronously or in background workers.
2. File or network work that can exceed instant latency must never block the UI thread.
3. Long-running work must publish status updates so users understand progress.

---

## 3. Preference Surface Rule

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

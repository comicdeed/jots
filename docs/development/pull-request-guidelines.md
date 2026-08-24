# Pull Request Guidelines

Guidelines and standards for preparing, scoping, and submitting Pull Requests to Jots.

---

## 1. Scope & Focus

* **Single logical change**: Each Pull Request must focus on a single self-contained improvement, bugfix, or feature.
* **One-paragraph rule**: If the entire scope of the changes cannot be explained in a single concise paragraph, the PR is too broad. Break it down into smaller, sequential pull requests.
* **Cohesive commit breakdown**: Group changes into cohesive, single-purpose commits.

---

## 2. Issue Alignment (Recommended)

Before starting work on a non-trivial modification, open or link an Issue to discuss the design and scope. While small bugfixes or typo corrections do not strictly require an issue, aligning on issues first prevents wasted effort.

---

## 3. Honest Attribution (Human-AI Disclosure)

To calibrate review effort and maintain transparency, every Pull Request description **must** include the Honest Attribution markdown block:

```markdown
## 🤖 Authorship & Attribution
* **Human Contributions**: [e.g. Architecture design, manual testing, logic review]
* **AI Tools**: [e.g. Gemini, Copilot, Claude]
* **AI Contributions**: [e.g. Boilerplate code, unit test cases, CSS styling]
```

### Review Calibration:
Review efforts are calibrated based on this attribution. AI-generated code undergoes stricter manual verification for regressions, performance traps, and hallucinations.

---

## 4. Human Responsibility

The human contributor is ultimately and solely responsible for all submitted changes:

* Fully read and understand all code, docstrings, and comments before submission.
* Verify all logic for hallucinations, regressions, and side effects.
* Run local test suites and manual validation before requesting review.

---

## 5. Automated Verification & Documentation Freshness

Before opening or merging a Pull Request:
* All automated canary tests in `tests/` must pass (`jots-unit-tests`).
* Code must build cleanly against Flatpak manifests without compiler warnings or regressions.
* Desktop metadata and AppStream XML must pass validation (`desktop-file-validate`, `appstreamcli validate`).
* **User Guide & Use-Case Freshness**: If the PR alters user-facing behavior, UI shortcuts, or settings, verify that [`docs/user-guide.md`](../user-guide.md) and [`docs/use-cases/`](../use-cases/) are updated to match.

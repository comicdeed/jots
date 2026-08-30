---
name: release-notes
description: Use when asked to prepare or update Jots release notes, AppStream <release> entries, or GitHub release text; analyzes commit ranges for Beta vs Stable releases and produces concise, user-experience-first notes with technical changes in a separate section.
---

# Release Notes Generation Skill

This skill defines the standard procedure for analyzing git commits, filtering development noise, and generating concise, user-focused release notes in both **AppStream XML** and **GitHub Markdown** formats for **Jots** (`io.github.comicdeed.jots`).

---

## 🎯 Core Principles

1. **User-Centric Focus**: Highlight tangible user benefits, new features, shortcuts, styling, and genuine bug fixes. Completely exclude internal refactors, test additions, code review cleanup, and CI maintenance commits.
2. **Human, Experience-First Tone**: Write in clear, natural language that describes what people can now do, feel, or notice. Avoid robotic changelog phrasing, implementation jargon, and commit-message style fragments.
3. **Separate Technical Notes**: If important technical changes must be called out, place them in a distinct section labeled **Technical Notes** (or **Technical Changes**) after user-facing highlights.
4. **Strict Conciseness**: Maximum 15–20 lines total. Keep descriptions crisp and high-impact.
5. **Single Source of Truth**: The `<release>` block in `data/jots.metainfo.xml.in.in` is the canonical source of truth, from which GitHub Releases and app store listings are derived.

### Language and Tone Rules (Mandatory)
* Lead with outcomes for everyday users, not architecture details.
* Prefer verbs tied to user action and comfort: "find", "focus", "organize", "read", "move faster", "feel smoother".
* Keep wording plain and approachable; assume non-technical readers.
* Avoid mechanical templates like "Added X", "Implemented Y", "Refactored Z" unless unavoidable.
* Mention keyboard shortcuts only when they improve discoverability.
* Only include technical depth when it materially affects trust, reliability, privacy, compatibility, or integrations.

### Required Section Order
1. **What is better for users** (default section; always present)
2. **Technical Notes** (optional, but required when significant technical changes are included)

---

## 🚀 Release Lifecycle & Workflow Reference

This skill operates as **Step 3** of the official Jots release process. Always consult the full guides:
* **Release Workflow Guide**: [`docs/development/release-workflow.md`](../../../docs/development/release-workflow.md)
* **Agent Development Guidelines**: [`AGENTS.md`](../../../AGENTS.md)

### Release Branch Execution Flow
1. **Cut Branch**: `git checkout -b release/X.Y.Z[-beta.N] develop`
2. **Bump Version**: Update `version: 'X.Y.Z[-beta.N]'` in `meson.build`.
3. **Generate Notes (This Skill)**: Add curated `<release>` entry to `data/jots.metainfo.xml.in.in`.
4. **Sync Docs**: Update [`docs/user-guide.md`](../../../docs/user-guide.md) if user-facing shortcuts or UI features changed.
5. **Commit & PR**: Commit `chore(release): prepare X.Y.Z[-beta.N] release` and open PR to `main`.
6. **Automated Release**: Merging into `main` automatically triggers GitHub Actions to create the tag, build multi-arch AppImages/Flatpaks, publish the GitHub Release, and back-merge `main` into `develop`.

---

## 🔍 Diff Scope Rules

### 1. For Beta Releases (`X.Y.Z-beta.N`)
* **Range**: `git log <last-tag>..HEAD`
* **Type**: `type="development"` in AppStream XML.
* **Objective**: Documents the **incremental delta** and fixes introduced since the previous beta or preceding release.

### 2. For Stable Releases (`X.Y.Z`)
* **Range**: `git log <last-stable-tag>..HEAD` *(e.g. `git log 0.9.0..HEAD` or `git log 1.0.0..HEAD`)*
* **Type**: Standard `<release version="X.Y.Z" date="YYYY-MM-DD">`.
* **Objective**: Compiles the **cumulative milestone changelog**, aggregating all features, improvements, and fixes built across all intermediate betas throughout the release cycle.

---

## 🛠️ Step-by-Step Procedure

### 1. Determine Base Tag and Target Version
```bash
# For Beta: find the immediately preceding tag (e.g. 1.1.0-beta.1)
PREV_TAG=$(git describe --tags --abbrev=0)

# For Stable: find the latest stable tag (sorted by tag commit date to prevent pre-fork legacy tag collision)
PREV_STABLE_TAG=$(git tag --sort=-creatordate | grep -v -E '(beta|alpha|rc)' | head -n 1)
```

### 2. Inspect Commit History
```bash
git log "${BASE_TAG}..HEAD" --oneline --no-merges
```

### 3. Categorize Changes
Group commits into standard high-signal categories:
* **`✨ What is better for users`**: Major user-visible improvements, smoother workflows, clearer interactions, and meaningful fixes.
* **`🎨 Design and comfort`**: Theming, contrast, readability, typography, and visual polish that improves day-to-day use.
* **`🔒 Reliability, privacy, and trust`**: Fixes that protect data, reduce surprises, or improve confidence.
* **`🛠️ Technical Notes`**: Important engineering changes worth surfacing for advanced users, packagers, or integrators.

*Omit all `chore:`, `ci:`, `test:`, `refactor:`, and internal code review commits.*

### 4. Cross-Reference Documentation
Check corresponding entries in:
* `docs/use-cases/` (Behavioral use cases)
* `docs/user-guide.md` (Shortcuts and manual)

---

## 📝 Output Formats

### 1. AppStream XML (`data/jots.metainfo.xml.in.in`)
```xml
        <release version="1.0.0-beta.1" type="development" date="2026-08-25">
            <description>
                <p>This beta focuses on making everyday note-taking faster, clearer, and more comfortable.</p>
                <p>What is better for users:</p>
                <ul>
                    <li>Search feels more immediate, helping you find the right note quickly.</li>
                    <li>Markdown notes remain plain and portable while rendering live for easier reading.</li>
                    <li>Theme and typography updates improve readability and reduce eye strain.</li>
                    <li>Migration from Jorts is safer with a non-destructive import flow.</li>
                    <li>Scribbly privacy behavior is more consistent when notes lose focus.</li>
                </ul>
                <p>Technical Notes:</p>
                <ul>
                    <li>Added a standalone native `jots-mcp` binary for MCP integrations over stdio JSON-RPC 2.0.</li>
                    <li>Improved search indexing and retrieval paths across active buffers and persisted Markdown files.</li>
                </ul>
            </description>
        </release>
```

### 2. GitHub Release Markdown Body
```markdown
# 🚀 Jots 1.0.0-beta.1 (Inaugural Beta)

Welcome to the inaugural beta release of **Jots** (`io.github.comicdeed.jots`) with improvements focused on everyday note-taking speed, clarity, and comfort.

*Jots is an independent fork and modern evolution of the classic Jorts application by Lains and community contributors.*

### ✨ What is better for users
* **Find notes faster**: Search now feels immediate, helping you jump to the right note without breaking focus.
* **Write in plain Markdown naturally**: Notes are saved as readable `.md` files with live rendering for structure and task lists.
* **Read more comfortably**: Theme and typography improvements increase contrast and reduce visual strain over long sessions.
* **Switch safely from Jorts**: Migration is non-destructive, so you can bring notes over with confidence.
* **Protect glance privacy**: Scribbly mode behaves more consistently when notes lose focus.

### 🛠️ Technical Notes
* Added a native `jots-mcp` server for Model Context Protocol integration over stdio JSON-RPC 2.0.
* Improved search indexing and retrieval paths for active windows and persisted Markdown notes.
```

---

## ✅ Quality Gate Before Finalizing Notes

Before publishing, verify all of the following:
* The first section is explicitly user experience driven.
* No purely internal change appears unless it impacts users directly.
* Any key technical architecture/runtime change is moved into **Technical Notes**.
* The wording sounds like a product update for users, not a commit digest for developers.

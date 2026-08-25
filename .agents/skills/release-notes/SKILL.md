---
name: release-notes
description: Curates high-signal, concise AppStream metadata and GitHub release notes for Jots, adhering to GNOME/elementary HIG and differentiating between incremental Beta and cumulative Stable release diffs.
---

# Release Notes Generation Skill

This skill defines the standard procedure for analyzing git commits, filtering development noise, and generating concise, user-focused release notes in both **AppStream XML** and **GitHub Markdown** formats for **Jots** (`io.github.comicdeed.jots`).

---

## 🎯 Core Principles

1. **User-Centric Focus**: Highlight tangible user benefits, new features, shortcuts, styling, and genuine bug fixes. Completely exclude internal refactors, test additions, code review cleanup, and CI maintenance commits.
2. **Strict Conciseness**: Maximum 15–20 lines total. Keep descriptions crisp and high-impact.
3. **Single Source of Truth**: The `<release>` block in `data/jots.metainfo.xml.in.in` is the canonical source of truth, from which GitHub Releases and app store listings are derived.

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
# For Beta: find the immediately preceding tag
PREV_TAG=$(git describe --tags --abbrev=0)

# For Stable: find the latest stable tag (excluding -beta, -alpha, -rc)
PREV_STABLE_TAG=$(git tag --list --sort=-v:refname | grep -v -E '(beta|alpha|rc)' | head -n 1)
```

### 2. Inspect Commit History
```bash
git log "${BASE_TAG}..HEAD" --oneline --no-merges
```

### 3. Categorize Changes
Group commits into standard high-signal categories:
* **`✨ Features`**: (`feat:` commits) Major new functionality, shortcuts, and capabilities.
* **`🎨 Design & UX`**: (`style:`, `feat(theme):` commits) Theming, contrast, typography, and styling improvements.
* **`🔒 Privacy & Fixes`**: (`fix:` commits) Bug fixes and security/privacy enhancements.

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
                <p>Inaugural Beta release of Jots — the next-generation lightweight sticky notes application, forked and evolved from Jorts 4.3.0.</p>
                <p>Major Highlights:</p>
                <ul>
                    <li>Full-Text Search: Real-time search popover querying live text buffers and saved notes with relevance scoring (Ctrl+F)</li>
                    <li>Markdown Storage &amp; Live Rendering: Individual Markdown file persistence with inline syntax rendering for headers, lists, checklists (- [ ]), and code blocks</li>
                    <li>Model Context Protocol (MCP) Server: Standalone native binary (jots-mcp) enabling AI assistants to securely read and create desktop sticky notes</li>
                    <li>Desaturated Dark Mode: High-contrast pastel color derivation optimized for dark themes and accessibility</li>
                    <li>Custom Typography: Configurable default and monospace note fonts in Preferences</li>
                    <li>Jorts Migration Helper: Non-destructive first-run prompt and Preferences tool to copy notes from existing Jorts installations</li>
                    <li>Scribbly Privacy Mode: Fixed dynamic font obfuscation when notes lose focus (Ctrl+H)</li>
                </ul>
            </description>
        </release>
```

### 2. GitHub Release Markdown Body
```markdown
# 🚀 Jots 1.0.0-beta.1 (Inaugural Beta)

Welcome to the inaugural beta release of **Jots** (`io.github.comicdeed.jots`), a lightweight, elegant desktop sticky notes application with native Markdown storage, full-text search, and AI assistant integration.

*Jots is an independent fork and modern evolution of the classic Jorts application by Lains and community contributors.*

### ✨ Highlights
* **Full-Text Search Engine**: Real-time popover search (`Ctrl+F` / `Ctrl+Shift+F`) querying active windows and saved Markdown notes.
* **Markdown Storage & Rendering**: Plaintext `.md` persistence with live syntax highlighting for `# Headings`, `- [ ]` task checklists, and code blocks.
* **Model Context Protocol (MCP) Server**: Standalone native binary (`jots-mcp`) over stdio JSON-RPC 2.0 for AI agent integration.
* **Desaturated Dark Mode & Typography**: High-contrast pastel surfaces and custom font configuration via Preferences.
* **Non-Destructive Jorts Migration**: One-click first-run prompt and Preferences tool to safely copy existing Jorts notes.
* **Scribbly Privacy Mode**: Fixed dynamic font obfuscation on unfocused notes (`Ctrl+H`).
```

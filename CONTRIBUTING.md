# Contributing to Jots

Welcome! Jots is a minimalist sticky notes application, and we welcome contributions of all kinds—whether authored manually, via AI/LLM assistants, or through hybrid workflows.

To keep the codebase stable and maintainable, we request that all contributors adhere to the guidelines below.

---

## 🧭 Code of Conduct
All interactions within this project must remain professional, objective, and respectful.
* Personal attacks, harassment, and toxic behavior are strictly prohibited.
* **Respectful Enforcement**: If a Pull Request or Issue is closed for violating project guidelines, the maintainers will provide a concise, respectful explanation of the reason.

---

## 🎯 Pull Request Guidelines

### 1. Focus on Single Changes (Functional Scope Rule)
Every Pull Request must be focused on a single logical change (one bugfix or one feature).
> [!IMPORTANT]
> If you cannot explain the entire scope of the changes in a single, short paragraph, the PR is too broad. Please break it up into smaller, sequential pull requests.

### 2. Issue Alignment (Recommended)
Before starting work on a major change or new feature, please open an Issue to discuss the design and scope. While small or trivial bugfixes do not require a pre-existing issue, aligning on issues first helps prevent wasted development effort.

### 3. Honest Attribution (Human-AI Disclosure)
To calibrate the review process, we require absolute transparency regarding the tools used. Every Pull Request description must include this attribution block:

```markdown
### 🤖 Authorship & Attribution
* **Human Contributions**: [e.g., Code architecture, manual QA, logic review]
* **AI/LLM Contributions**: [e.g., Boilerplate code, CSS styles, localization]
* **Tools & Models Used**: [e.g., Copilot, Gemini 2.0 Pro]
```

Review efforts are calibrated based on this attribution (AI-heavy or automated contributions undergo more thorough verification).

### 4. Ultimate Human Responsibility
While AI assistants and agents are welcome companions, **the human contributor is ultimately responsible for all submitted changes**.
> [!IMPORTANT]
> **Be in control of your tools.** You must fully review all AI-generated content (code, comments, issue/PR descriptions, translations) before submission. Check for hallucinations, run manual verification tests, read the code fully, and ensure you understand every aspect of the change. You own the final submission.

---

## 🛠️ Build and Development
For instructions on setting up your local build environment and compiling Jots, please refer to:
* **[Building Documentation](docs/development/building.md)**: Main project compilation and Flatpak guides.
* **[Developer Onboarding Guide](AGENTS.md)**: Workspace maps and developer guidelines.
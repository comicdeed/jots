# Idea Evaluation and Grading Framework

A standardized assessment matrix for evaluating proposed feature candidates, enhancements, and architectural changes in Jots.

---

## 1. Evaluation Dimensions

Proposed ideas are graded across three core dimensions on a 5-point scale (1 to 5):

### A. Impact & Value (1–5)
* **5 (Transformational)**: Delivers a major differentiator or headline capability (e.g. native MCP agent integration).
* **4 (High Value)**: Significantly improves daily usability, interoperability, or workflow efficiency for a large user segment.
* **3 (Moderate Value)**: Solves a common convenience issue or polishes existing workflows.
* **2 (Niche Value)**: Beneficial to a small minority with limited broad appeal.
* **1 (Minimal Value)**: Cosmetic novelty with negligible functional benefit.

### B. Architectural Alignment & Simplicity (1–5)
* **5 (Perfect Harmony)**: Upholds tactile minimalism, local-first privacy, zero UI friction, and clean system boundaries.
* **4 (Strong Alignment)**: Extends functionality without bloating core views or violating GTK/Granite design patterns.
* **3 (Acceptable)**: Introduces minor non-invasive complexity or secondary settings.
* **2 (Friction Prone)**: Adds persistent UI widgets, excessive preference toggles, or heavy dependencies.
* **1 (Antipattern)**: Compromises offline simplicity, introduces brittle remote dependencies, or shifts focus away from simple sticky notes.

### C. Implementation & Maintenance Complexity (1–5, Inverted)
* **5 (Trivial)**: Self-contained modification, zero maintenance overhead, minimal regression risk.
* **4 (Low-Moderate)**: Clear implementation path using standard GLib/GTK/Granite APIs with isolated test coverage.
* **3 (Moderate)**: Involves state schema migrations, background worker logic, or multi-component IPC.
* **2 (High)**: Requires complex asynchronous synchronization, heavy third-party libraries, or custom protocol parsing.
* **1 (Severe)**: Fragile reverse-engineered APIs, high ongoing maintenance burden, or platform fragmentation risk.

---

## 2. Composite Scoring and Tiers

The overall score is computed as:
$$\text{Composite Score} = (\text{Impact} \times 0.40) + (\text{Alignment} \times 0.35) + (\text{Complexity Score} \times 0.25)$$

| Tier | Score Range | Classification | Recommendation |
| :---: | :---: | :--- | :--- |
| 🟢 **Tier 1** | **4.2 – 5.0** | **Ready for Roadmap / Active Priority** | Immediate candidate for specification and implementation. |
| 🟡 **Tier 2** | **3.4 – 4.1** | **Planned / Backlog Exploration** | High-value candidate scheduled for future milestone cycles. |
| 🟠 **Tier 3** | **2.6 – 3.3** | **Under Evaluation / Incubating** | Requires architecture refinement or user demand validation. |
| 🔴 **Tier 4** | **1.0 – 2.5** | **Deferred / Not Recommended** | Out of scope, disproportionate complexity, or anti-minimalist. |

# Sample Models

This directory contains notes on the demo model assets used in the JFrog AI Catalog MCP Demo.

---

## Models Used in the Demo

### facebook/bart-large-cnn (APPROVED)

- **Purpose:** Primary "safe" model in Act 2; recommended choice in Act 1
- **Architecture:** BART (Bidirectional and Auto-Regressive Transformers)
- **Task:** Text and document summarization
- **Size:** ~2.3 GB
- **License:** MIT
- **HuggingFace URL:** https://huggingface.co/facebook/bart-large-cnn
- **JFrog AI Catalog status:** Approved, clean security scan
- **Why chosen:** Widely recognized, large enough to be credible, clean security record, good license

### microsoft/codebert-base (BLOCKED — Demo Security Threat)

- **Purpose:** The "blocked" model in Act 2 — demonstrates security enforcement
- **Architecture:** RoBERTa-based code model
- **Task:** Code understanding and search
- **Size:** ~499 MB
- **HuggingFace URL:** https://huggingface.co/microsoft/codebert-base
- **JFrog AI Catalog status:** BLOCKED (pre-seeded malicious scan result for demo)
- **Demo setup:** This model's blocked status is **pre-seeded** in the demo environment — the real model is clean. The blocked scan result is injected during `setup.sh` to create a realistic demo scenario.
- **Why chosen:** Well-known Microsoft model, believable as a target, lightweight enough for demo

### salesforce/codet5-base (APPROVED)

- **Purpose:** Second approved option in Act 1 — shows multiple clean candidates
- **Architecture:** T5-based code model
- **Task:** Code summarization and generation
- **Size:** ~892 MB
- **License:** Apache 2.0
- **HuggingFace URL:** https://huggingface.co/Salesforce/codet5-base
- **JFrog AI Catalog status:** Approved, clean security scan
- **Why chosen:** Code-specific model directly relevant to the "code review assistant" scenario

---

## Important Notes

**None of these models are actually malicious.** The demo uses real Hugging Face model names to make the scenario credible, but the blocked model status for `microsoft/codebert-base` is artificially seeded in the demo environment.

**Do not imply in customer demos** that the real `microsoft/codebert-base` model is malicious — that would be inaccurate. The talking point is: "We're using a well-known model as a stand-in for the kind of malicious payload JFrog has discovered in real Hugging Face models. JFrog's researchers found models like this with real CVSS 9.3 vulnerabilities."

**Reference the real research:** JFrog discovered malicious pickle payloads in Hugging Face models in 2025. That's the authentic security story.

---

## Screenshots Directory

`../screenshots/` should contain annotated screenshots of:
- `act1-discovery-results.png` — Act 1 MCP tool call output in Claude
- `act2-blocked-model.png` — AI Catalog blocked model view
- `act2-scan-evidence.png` — Xray scan evidence tab
- `act2-curation-policy.png` — Curation policy detail
- `act2-approved-model.png` — Clean model with evidence trail
- `act3-project-created.png` — ml-code-review project in Artifactory
- `act3-repositories.png` — 3 repositories visible in project
- `act4-shadow-ai.png` — Shadow AI panel with seeded entries

These screenshots serve as the visual fallback when live UI navigation is not possible.

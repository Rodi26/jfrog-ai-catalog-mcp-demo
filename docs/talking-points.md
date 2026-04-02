# Talking Points, Key Messages, and Q&A Prep

For sales engineers and solution architects presenting this demo.

---

## Core Message

> **JFrog AI Catalog is the "npm registry" equivalent for the AI era — a single, governed platform that brings the same trust model proven in software supply chains to AI assets: Hugging Face models, MCP servers, and agent skills.**

---

## Why This Matters (The Problem)

- AI adoption is accelerating faster than governance
- Data scientists pull models directly from Hugging Face — no scanning, no policy, no inventory
- Developers wire up OpenAI/Anthropic calls outside IT visibility
- Agents consume unvetted MCP servers from random GitHub repos
- This is the **same sprawl JFrog solved for open-source packages** — and JFrog AI Catalog is the solution

**Anchor stat:** JFrog researchers discovered 3 critical PickleScan zero-days in 2025 (CVSS 9.3) in publicly available Hugging Face models. This is not a theoretical risk.

---

## Key Differentiators

### 1. Evidence-based security (not just scanning)
JFrog's evidence engine eliminates 96% of false positives. When it flags a model, it's real — with file-level scan evidence, CVE data, and attack vector analysis. Competitor tools produce noisy results that teams ignore.

### 2. Complete supply chain lineage
Every model has a governance trail: when it was pulled, what was scanned, what policy applied, who approved it. Auditors love this. Most AI governance tools show you policies but not evidence.

### 3. The MCP Server (AI-native interface)
JFrog isn't just governing AI — it's AI-native itself. The JFrog MCP Server turns the entire platform into a conversational interface for AI coding assistants. Developers manage infrastructure, query security data, and set up pipelines in natural language.

### 4. Shadow AI detection
Automatic discovery of unmanaged AI consumption — without requiring app code changes. Same way Artifactory revealed open-source sprawl, AI Catalog reveals AI sprawl.

### 5. Unified with your existing toolchain
If you already use Artifactory and Xray, AI Catalog is an extension — same policies, same RBAC, same CI/CD integration. Not a separate product to evaluate and integrate.

---

## Competitive Angles

### vs. "just use Hugging Face directly"
Hugging Face has basic safety features, but no enterprise governance:
- No integration with your RBAC / IAM
- No organization-wide curation policies
- No lineage or evidence trail for compliance
- No shadow AI detection
- No integration with your existing Xray policies

JFrog Artifactory proxies Hugging Face — you get all the models, plus enterprise governance.

### vs. standalone AI security tools (e.g., Protect AI, Robust Intelligence)
- Point solutions; don't integrate with your artifact management
- No MCP Server / AI-native access
- Separate toolchain = separate compliance process
- JFrog brings it all together in one platform your team already knows

### vs. "we'll build our own governance layer"
- Time-to-value: JFrog AI Catalog is production-ready now
- Model scanning requires deep ML security research — JFrog has it; most teams don't
- Building your own means maintaining it; JFrog updates as new attack vectors emerge

---

## Audience-Specific Messages

### Security Engineers / CISOs
- AI Catalog gives you the same control over AI models as Xray gives you over open-source packages
- Shadow AI detection fills the governance gap before a breach
- Evidence-based blocking means fewer false positives and faster incident response
- Compliance: every model has a complete, auditable governance trail

### Platform Engineers / DevOps
- AI Catalog extends your existing Artifactory investment — same CLI, same pipelines
- Virtual repositories mean developers always pull from a single governed URL
- MCP Server automates JFrog administration through natural language
- GitHub Actions integration keeps AI governance in-pipeline without extra tooling

### Data Scientists / ML Engineers
- Governed Hugging Face access — all the models, with corporate approval
- Model cards in AI Catalog surface the security and licensing info you need before you integrate
- No friction: pull from the virtual repo URL, JFrog handles governance transparently

### Developer Advocates / SA Teams
- The MCP demo is memorable and differentiating: AI tooling governing AI tooling
- Reproducible scenario grounded in real JFrog security research
- 12-minute format fits customer discovery calls and conference demos

---

## Anticipated Objections

### "We don't use Hugging Face"
AI Catalog governs any AI asset: internal models, OpenAI/Anthropic API calls, NVIDIA NIM, Google Vertex. The Hugging Face scenario is illustrative — the governance model applies to whatever AI your team uses.

### "Our models are proprietary / air-gapped"
Artifactory's local repositories support fully air-gapped model storage. The same curation and Xray scanning works on internal models. JFrog never needs to reach an external registry.

### "The MCP Server is still in beta"
The official remote MCP Server is in open beta for SaaS. It's stable enough for demos and internal use. GA timeline: H1 2026. The underlying JFrog platform APIs are production-grade.

### "We're already locked into [other vendor]"
AI Catalog integrates with existing CI/CD tools (GitHub Actions, Jenkins, GitLab) and model frameworks (PyTorch, TensorFlow, Hugging Face `transformers`). It's additive — not a rip-and-replace.

### "How does this handle model drift / versioning?"
Artifactory tracks model versions exactly like container image tags. Xray scans each version independently. AI Catalog maintains a complete history per model version.

---

## What NOT to Say

- Don't call it a "model hub" — JFrog's positioning is AI supply chain governance, not model discovery
- Don't oversell Shadow AI detection depth — it varies by license tier and deployment model; confirm capabilities for the specific prospect
- Don't promise MCP Registry as GA — announced but confirm availability at demo time
- Don't claim the MCP Server is self-hosted-ready — it requires JFrog SaaS (for now)

---

## Follow-Up Materials

After the demo, offer:
- Trial access to JFrog SaaS with AI Catalog enabled
- JFrog AI Catalog documentation: https://jfrog.com/help/
- JFrog security research blog posts on Hugging Face malware
- JFrog MCP Server GitHub repo: https://github.com/jfrog/jfrog-mcp-server

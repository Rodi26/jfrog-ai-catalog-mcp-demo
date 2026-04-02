# FAQ — Anticipated Audience Questions

---

## About JFrog AI Catalog

**Q: How is JFrog AI Catalog different from just using Hugging Face directly?**

A: Hugging Face provides model discovery and basic safety checks, but no enterprise governance. JFrog AI Catalog adds:
- Organization-wide curation policies (not per-user settings)
- Xray security scanning with evidence-based results
- Complete lineage and audit trail for compliance
- Integration with your existing RBAC and IAM
- Shadow AI detection for unmanaged AI consumption
- A single governed URL for all AI assets (Artifactory virtual repository)

Hugging Face is the source; JFrog is the governance layer.

**Q: Does this only work with Hugging Face models?**

A: No. JFrog AI Catalog governs:
- Hugging Face models (via Artifactory HuggingFace package type)
- Internal/proprietary models (local repositories)
- External AI API providers: OpenAI, Anthropic, Google Gemini, AWS Bedrock, NVIDIA NIM
- MCP servers (via the MCP Registry, announced Q1 2026)

**Q: When was JFrog AI Catalog released?**

A: AI Catalog launched at JFrog swampUP in September 2025. Shadow AI detection was added in November 2025. The MCP Registry was announced at the same time with Q1 2026 availability.

**Q: What license tier is required?**

A: AI Catalog requires JFrog Enterprise X tier. Xray is included. Shadow AI detection features may vary by tier — confirm specifics with your JFrog account team for your prospect.

---

## About Security

**Q: What exactly can JFrog detect in Hugging Face models?**

A: JFrog Xray scans for:
- **Pickle exploits** — malicious code in Python serialization files (`.pkl`)
- **ONNX backdoors** — malicious operations injected into model graphs
- **TensorFlow Lambda layers** — arbitrary code execution via TF serialization
- **GGUF inference-stage exploits** — attacks targeting LLM quantized formats
- **CVEs** in model dependencies (NumPy, PyTorch, transformers, etc.)
- **License violations** — AGPL, commercial restrictions, missing licenses

**Q: Isn't this just VirusTotal for models?**

A: No — VirusTotal uses signature-based detection optimized for executables. JFrog's model scanning requires deep understanding of ML serialization formats, model graph structures, and inference-time attack vectors. JFrog's security research team discovered the PickleScan zero-days (CVSS 9.3) by analyzing Hugging Face repos at scale — this is original security research, not signature matching.

**Q: What's a pickle attack and why does it matter?**

A: Python's `pickle` module is used to serialize and deserialize Python objects — including ML models (PyTorch, scikit-learn). It can execute arbitrary code on deserialization. A malicious model file can run any code the attacker wants the moment you load it with `torch.load()`. JFrog scans for embedded pickle payloads before the model is ever loaded.

**Q: How does JFrog handle false positives?**

A: JFrog's evidence engine requires file-level proof of the specific attack vector before flagging a model. The system is designed to eliminate false positives — when it blocks a model, it shows you exactly what file, what payload, and what attack vector triggered the block.

**Q: What's the JFrog + Hugging Face security partnership?**

A: Announced in 2025, JFrog and Hugging Face formally partnered to scan all public Hugging Face repositories automatically when models are pushed. JFrog's security research directly informs Hugging Face's safety indicators.

---

## About the MCP Server

**Q: What is the JFrog MCP Server?**

A: The JFrog MCP Server is an official JFrog product that implements the Model Context Protocol (MCP) — an open standard for connecting AI assistants to external tools. It exposes 22 JFrog platform capabilities as MCP tools, making the entire JFrog platform queryable and controllable through natural language from AI coding assistants like Claude or Cursor.

**Q: Does the MCP Server need to be self-hosted?**

A: No. The official remote MCP Server is hosted by JFrog at `https://yourcompany.jfrog.io/mcp` — no installation required. There is an experimental self-hosted option (`mcp-jfrog` GitHub repo) but the official remote server is the recommended path for JFrog SaaS customers.

**Q: Is the MCP Server production-ready?**

A: The official remote MCP Server is in open beta for JFrog SaaS (as of early 2026). It's stable enough for demos and internal use. The underlying JFrog platform APIs are production-grade. GA is targeted for H1 2026.

**Q: Which AI coding assistants support it?**

A: Any MCP-compatible assistant: Claude Desktop, Cursor, VS Code with GitHub Copilot, Replit, Sourcegraph Cody. MCP is an open standard (donated to the Linux Foundation in December 2025) with broad adoption.

**Q: Does using the MCP Server mean my prompts are sent to JFrog?**

A: No. The MCP Server only receives the structured tool call parameters (e.g., "list repositories of type huggingface"). The natural language conversation stays in your AI assistant. JFrog never sees your prompts.

---

## About Shadow AI

**Q: How does Shadow AI detection work technically?**

A: Shadow AI detection uses two mechanisms:
1. **Network telemetry** (when AI Gateway is deployed): monitors outbound connections to known AI API endpoints
2. **Code scanning**: identifies hardcoded API keys and direct API call patterns in CI/CD artifacts

Detection is automatic once the AI Gateway is deployed — no application code changes required.

**Q: What can we do once Shadow AI is detected?**

A: AI Catalog surfaces the findings and offers a "Route through AI Gateway" action. Once routed:
- All calls go through the AI Gateway
- Usage is metered and attributed to teams/services
- Policies can be applied (allowed models, rate limits, cost caps)
- Full audit trail is maintained

**Q: Does Shadow AI detection cover all AI providers?**

A: JFrog tracks a curated list of known AI API providers including OpenAI, Anthropic, Google (Gemini, Vertex), AWS Bedrock, Cohere, Mistral, and NVIDIA NIM. The list is updated as new providers gain adoption.

---

## About the Demo

**Q: Is this demo against live infrastructure or simulated?**

A: The demo runs against a real JFrog SaaS instance. MCP tool calls are live API requests — no mocking. The blocked model's scan evidence is pre-seeded (to avoid waiting for live scan) but represents real scan data.

**Q: Can we try this ourselves?**

A: Yes — this repository includes everything needed:
1. Set up a JFrog SaaS trial (free 14-day) at https://jfrog.com/start-free/
2. Clone this repo and run `./scripts/setup.sh`
3. Configure MCP in Claude Desktop using `config/mcp/claude-desktop-config.json`
4. Run `./scripts/validate.sh` and you're ready

**Q: How long does setup take?**

A: About 15 minutes from zero to demo-ready. See `QUICKSTART.md`.

# Talking Points, Key Messages, and Q&A Prep

---

## The Single Most Important Message

> **In JFrog AI Catalog, a Project is the governance boundary. Every model allowance, every provider connection, every MCP server registration — is scoped to a Project. Developers never hold raw provider API keys. Everything routes through the JFrog AI Gateway or MCP Gateway, enforced at the project level.**

---

## The Core Problem

- AI adoption is accelerating faster than governance
- Data scientists pull models directly from Hugging Face — no policy, no inventory
- Developers hardcode OpenAI API keys — no rotation, no metering, no audit trail
- CI/CD jobs call Anthropic outside any governance boundary
- Agents consume MCP servers from random GitHub repos with no tool-level control

This is the same sprawl JFrog solved for open-source packages with Artifactory. The difference: when an open-source package has a CVE, the blast radius is a build. When an AI model has a malicious payload, the blast radius is a trained model in production or compromised inference infrastructure.

---

## Key Differentiators

### 1. Project-based governance (not global allow/block)

Unlike competitor tools that apply governance globally, JFrog AI Catalog governs at the Project level. Team A can use DeepSeek; Team B is restricted to OpenAI. This is not a configuration option — it is the fundamental architecture. Provider-project pairs are the atomic governance unit.

### 2. Developer tokens, not raw API keys

Developers get JFrog project-scoped tokens. The raw provider API key is stored in JFrog Secrets, referenced by a Connection, and used by the AI Gateway at proxy time. Developers cannot exfiltrate provider credentials. Access revocation is a single JFrog token invalidation.

### 3. Tool-level MCP governance

JFrog's MCP Registry governs not just which MCP servers are accessible, but which individual tools within each server a project can use. Regex-based allow/deny policies per server per project. A `delete_repository` call from a developer's AI assistant can be blocked without restricting read operations on the same server.

### 4. Evidence-based security scanning

JFrog's Xray doesn't just flag models — it provides file-level scan evidence: exactly which file, what type of payload, what attack vector. This eliminates false positives. When JFrog blocks a model, it shows you why. Grounded in real security research: JFrog discovered 3 critical PickleScan zero-days (CVSS 9.3) in Hugging Face models in 2025.

### 5. Shadow AI detection feeds into governance

Shadow AI detection doesn't just surface unmanaged calls — it provides a governance path. The "Allow to project" action brings unmanaged calls under the same Project governance model, without breaking existing developer workflows.

---

## Audience-Specific Messages

### Security Engineers / CISOs
- AI Catalog gives you the same control over AI models as Xray gives you over open-source packages — at the project level
- Provider credentials are stored in JFrog Secrets — no more API keys scattered across developer machines and CI jobs
- Complete audit trail: every model allowance, every AI Gateway call, every MCP tool invocation is logged per project
- Shadow AI detection fills the governance gap before a breach

### Platform Engineers / DevOps
- Provider Connections centralize credential management — rotate an API key in one place, update takes effect across all projects using that connection
- The AI Gateway is a proxy you don't have to build — JFrog handles routing, metering, and logging
- MCP Gateway with `PROJECT_KEY` integrates with your existing JFrog project structure
- GitHub Actions + OIDC integration keeps AI governance in-pipeline

### Data Scientists / ML Engineers
- Project-approved models appear in the Registry — one place to find what your team is authorized to use
- "Use Model" generates ready-to-use code snippets; the developer just replaces their endpoint and key
- All the HuggingFace models, with corporate governance transparently added
- Model card in the Registry shows security scan results, license, and approval history

### Developer Advocates / SA Teams
- The project-governance model is the differentiating story — not just "governance" but per-team governance with credential isolation
- The token-not-key architecture is memorable: "developers never hold provider API keys"
- Tool-level MCP policies are novel and compelling for technical audiences

---

## Competitive Angles

### vs. "just use OpenAI's organization controls"
OpenAI's organization-level access is all-or-nothing at the organization level. JFrog AI Catalog provides project-level granularity within your organization — different teams get different model access, with separate credential bindings and usage tracking. Additionally, JFrog governs not just OpenAI but every AI provider: HuggingFace, Anthropic, AWS Bedrock, NVIDIA NIM, and internal models.

### vs. standalone AI security tools
Point solutions (Protect AI, Robust Intelligence) scan models but don't integrate with your artifact management or provide the project-scoped credential model. JFrog AI Catalog brings security, governance, and access management together in the same platform your team already uses for software supply chain.

### vs. "we'll build our own AI gateway"
Building an AI proxy requires: credential management, per-project routing, usage metering, audit logging, provider SDK compatibility, and ongoing maintenance as providers update their APIs. JFrog has built and maintains this. Time-to-value: hours, not months.

### vs. cloud provider AI governance
AWS Bedrock, Azure AI, and GCP Vertex have governance within their own ecosystems. JFrog AI Catalog provides cross-cloud, cross-provider governance in one platform — including self-hosted models and Hugging Face, which cloud AI services don't govern.

---

## Anticipated Objections

### "We don't use HuggingFace"
AI Catalog governs any AI asset: OpenAI, Anthropic, Gemini, AWS Bedrock, NVIDIA NIM, custom models, and MCP servers. The HuggingFace scenario is illustrative — the project governance model applies to all of them.

### "How does the AI Gateway affect latency?"
The JFrog AI Gateway adds minimal latency — typically 10–30ms of proxy overhead. For LLM inference workloads where model response time is measured in seconds, this is negligible. The Gateway is hosted on JFrog SaaS infrastructure geographically close to major cloud regions.

### "Can we use this for self-hosted models?"
Yes. Local and remote MCP servers are supported. For model inference, NVIDIA NIM and similar self-hosted providers are supported via Artifactory local repositories and Xray scanning. The AI Gateway routes to any configured connection.

### "Is the MCP Gateway generally available?"
The MCP Registry reached GA in March 2026. The MCP Gateway (`jf mcp-gateway run`) is the developer-facing runtime. Confirm current availability with your JFrog account team for production use cases.

### "How do we migrate existing API keys?"
Existing API keys are added as JFrog Secrets and referenced by Connections during the transition. Developer code is updated to use the gateway endpoint and a JFrog project token instead of the raw key. JFrog provides migration guides.

---

## What NOT to Say

- Don't claim Shadow AI detection catches everything — it detects calls to known AI API providers and relies on AI Gateway telemetry where deployed
- Don't promise MCP Registry on self-hosted Artifactory — currently SaaS-only for the remote MCP server
- Don't imply the real `microsoft/codebert-base` model is malicious — the blocked state in the demo is seeded for illustrative purposes; the actual research is about other models discovered by JFrog's security team
- Don't undersell the Project model — it's not just an organizational label, it's the enforcement mechanism

---

## Follow-Up Materials

After the demo:
- JFrog AI Catalog docs: https://docs.jfrog.com/ai-ml/docs/jfrog-ai-catalog-overview
- Discover and allow models: https://docs.jfrog.com/ai-ml/docs/discover-and-allow-models
- Connect AI providers: https://docs.jfrog.com/ai-ml/docs/connect-ai-providers
- MCP Registry: https://docs.jfrog.com/ai-ml/docs/mcp-registry-overview
- Free trial: https://jfrog.com/start-free/

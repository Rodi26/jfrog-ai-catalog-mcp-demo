# FAQ — Anticipated Audience Questions

---

## About JFrog Projects and Governance

**Q: Why does JFrog AI Catalog use Projects as the governance unit?**

A: Projects allow fine-grained, team-level governance rather than organization-wide allow/block rules. Different teams have different AI needs — the data science team might need access to LLaMA 70B, while the product team only needs GPT-4o. JFrog Projects enforce this separation: each team gets access to exactly the AI assets they're authorized for, with separate credential bindings.

From JFrog's documentation: "Each model provider-project pair requires a unique connection." This is the core rule — there's no global connection; every provider relationship is project-scoped.

**Q: What's the difference between Discovery and Registry?**

A: 
- **Discovery** — the staging area for admins. All known AI assets appear here. Admins evaluate, check security scans, and decide what to allow.
- **Registry** — the developer view. Only assets explicitly allowed for their project. Developers browse and consume from here.

The flow is: Discovery (evaluate) → Allow (to specific project) → Registry (developer access).

**Q: Can one model be allowed in multiple projects?**

A: Yes. The same model (e.g., `facebook/bart-large-cnn`) can be allowed into multiple projects. Each "Allow" action creates a separate binding for the target project. If the provider connection already exists for that project, JFrog reuses it automatically.

**Q: Who can allow models and create connections?**

A: Only platform admins can allow models from Discovery and create Provider Connections. Developer self-service is limited to browsing the Registry and generating project-scoped tokens via "Use Model." This separation of duties is intentional — admins control the governance perimeter; developers consume within it.

---

## About Provider Connections and the AI Gateway

**Q: Why don't developers hold the raw API keys?**

A: Provider Connections store credentials as JFrog Secrets. When a developer calls the JFrog AI Gateway (`https://<org>.ml.jfrog.io/v1`) with a project-scoped token, the Gateway resolves the stored Connection credential and proxies the request to the actual provider. This means:
- Developer machines and CI jobs never hold provider API keys
- Key rotation is a single-place operation (update the JFrog Secret)
- Access revocation is a single JFrog token invalidation
- Usage is metered and logged at the Gateway for every call

**Q: How does the AI Gateway affect my code?**

A: Minimal change — it's OpenAI API-compatible. Replace `base_url` (from `https://api.openai.com/v1` to `https://<org>.ml.jfrog.io/v1`) and replace the API key with a JFrog project-scoped token. Standard OpenAI SDK, LangChain, LlamaIndex, and similar frameworks work unchanged.

**Q: Does the AI Gateway affect latency?**

A: Minimal — typically 10–30ms of proxy overhead. LLM inference takes seconds; the gateway overhead is negligible. The JFrog AI Gateway is hosted on SaaS infrastructure close to major cloud regions.

**Q: What happens if the AI Gateway goes down?**

A: The gateway is a managed JFrog SaaS service with the same SLA as the rest of the JFrog Platform. For offline use cases, JFrog supports local/cached models through Artifactory repositories which don't require the gateway.

---

## About MCP Governance

**Q: What is the JFrog MCP Registry?**

A: The MCP Registry is JFrog AI Catalog's catalog of approved MCP servers, governed per project. Admins add MCP servers to a project's Registry and define tool-level policies (allow/deny rules using regex). Developers access these servers through the JFrog MCP Gateway.

**Q: How does the MCP Gateway work?**

A: Developers install the MCP Gateway using `jf mcp-gateway run` with their `PROJECT_KEY`. The gateway intercepts all MCP tool calls from their AI coding assistant and enforces the project's tool policies — allowing approved tool calls through to the target MCP server, blocking denied calls before they execute.

**Q: What's the difference between the JFrog MCP Gateway and the JFrog MCP Server?**

A: Two distinct things:
- **JFrog MCP Gateway** (`jf mcp-gateway run`) — developer-facing runtime that enforces per-project MCP tool policies. Governs what MCP servers and tools developers can use.
- **JFrog MCP Server** (`jfrog-mcp`, available via Smithery) — exposes JFrog platform administration as MCP tools. Lets AI assistants query and manage JFrog itself (create repos, check policies, etc.).

The demo uses both: MCP Gateway for project-governed MCP access, and optionally jfrog-mcp for showing admin operations.

**Q: Can we define our own tool policies per MCP server?**

A: Yes. Tool policies are regex-based, defined per (MCP server, project) pair. Common patterns:
- `^get_.*` — allow all read/get operations
- `.*delete.*` — deny all delete operations
- `^create_issue$` — allow only issue creation, nothing else

The "Recommended" mode requires admins to explicitly define allow lists, preventing accidental tool exposure.

**Q: Is the MCP Registry generally available?**

A: The MCP Registry reached GA in March 2026. Confirm current availability with your JFrog account team for production use cases.

---

## About Security

**Q: What does JFrog scan for in AI models?**

A: JFrog Xray scans for:
- **Pickle exploits** — malicious code in Python serialization files
- **ONNX backdoors** — malicious operations in model graph structures
- **TensorFlow Lambda layers** — arbitrary code execution via TF serialization
- **GGUF inference-stage exploits** — attacks targeting quantized LLM formats
- **CVEs** in model dependencies
- **License violations** — AGPL, missing licenses, commercial restrictions

**Q: How does curation differ from Xray scanning?**

A: Xray scans artifacts and produces findings. Curation policies evaluate those findings and take automated action — blocking download before the artifact is served to any developer. Curation happens at ingest time, before models enter the cache. Xray scans produce the evidence; curation policies enforce the response.

**Q: Can we see audit trails per project?**

A: Yes. The Registry maintains a governance trail per model per project: when it was allowed, who approved it, what security scan was evaluated, what policy applied. AI Gateway logs show per-project, per-model call metering. MCP Gateway logs show per-project tool call execution.

---

## About Shadow AI

**Q: How does Shadow AI detection work?**

A: Shadow AI detection monitors outbound calls to known AI API provider endpoints through the AI Gateway (when deployed) or network telemetry. It identifies calls to providers not routed through the JFrog governance layer and surfaces them in the AI Catalog dashboard.

**Q: What happens after we "Allow to Project"?**

A: The Allow action creates a Provider Connection for the detected provider in the specified project. The next step is updating the caller (CI job, developer code) to use a JFrog project token and the AI Gateway endpoint instead of the provider's direct API. JFrog provides migration guides and code snippets for this transition. The goal is to bring the call under the same governance model as everything else — without breaking workflows.

---

## About Setup and Compatibility

**Q: Does this work with self-hosted Artifactory?**

A: The official JFrog AI Catalog features (Discovery, Connections, Registry, AI Gateway, MCP Registry) currently require JFrog SaaS. Self-hosted Artifactory supports HuggingFace repository proxying and Xray scanning for model artifacts, but the AI Catalog layer is SaaS-only for now.

**Q: What AI providers are supported?**

A: Supported providers for Provider Connections: OpenAI, Anthropic, AWS Bedrock, Google Vertex AI, NVIDIA NIM, HuggingFace, Cohere, Mistral, Azure OpenAI. The list grows as JFrog adds integrations.

**Q: Can we use this in CI/CD pipelines?**

A: Yes. The JFrog CLI supports the AI Catalog workflow in GitHub Actions, GitLab CI, and Jenkins. The recommended pattern is: jobs use JFrog project-scoped tokens (from a CI service account with project membership) to call the AI Gateway, instead of hardcoded provider API keys. GitHub Actions + OIDC integration is supported for keyless authentication.

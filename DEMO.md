# Demo Guide — From Discovery to Governance: AI Catalog with JFrog Projects

**For presenters.** Read this before every demo run.

---

## The Core Message

> *"In JFrog AI Catalog, a Project is the governance boundary for all AI consumption. You don't just block or allow AI assets globally — you authorize them per team, bind credentials per team, and issue project-scoped tokens. Developers never hold raw provider API keys. Everything routes through the JFrog AI Gateway."*

---

## Before You Present

- [ ] Run `./scripts/validate.sh` — all checks must pass
- [ ] Log into JFrog SaaS as Admin — navigate to **AI/ML > Discovery**
- [ ] Verify the demo project `ml-code-review` exists in **Administration > Projects**
- [ ] Verify connections exist for OpenAI and HuggingFace in **AI/ML > AI Catalog > Connections**
- [ ] Have `scripts/demo-prompts.txt` open in a side window
- [ ] Run `./scripts/reset.sh` if you've demoed before

**Personas:**
- **Admin persona:** You (presenting) — has admin rights, manages Discovery + Connections + MCP Registry
- **Developer persona:** Simulated — you'll show the developer's Registry view and token generation

---

## Demo Overview

**Title:** *From Discovery to Governance — AI Catalog with JFrog Projects*
**Duration:** ~14 minutes
**Primary surface:** JFrog AI Catalog UI (browser) + terminal
**Secondary:** Claude Code or Claude Desktop (for MCP Gateway demo)

---

## Act 1 — Project Setup + Provider Connection (2–3 min)

**Goal:** Show that a JFrog Project is the governance unit. Everything that follows is scoped to a project.

### 1.1 — Show the Project

**Navigate to:** Administration → Projects → `ml-code-review`

**Point out:**
- Project key: `ml-code-review`
- Admin privileges enabled
- This project represents the "ML Code Review" team

**Spoken:**

> *"In JFrog AI Catalog, the Project is the governance boundary. When we allow a model, we're allowing it for a specific project — not globally. When a developer gets a token to call an AI provider, it's scoped to this project. One team can use DeepSeek; another is restricted to OpenAI. All enforced through the Project."*

### 1.2 — Show Provider Connections

**Navigate to:** AI/ML → AI Catalog → Connections

**Point out:**
- Connection `ml-openai-connection` — bound to `ml-code-review` project, provider: OpenAI
- Connection `ml-huggingface-connection` — bound to `ml-code-review` project, provider: HuggingFace
- Notice: each connection is a unique `(provider, project)` pair

**Spoken:**

> *"A Connection stores the credentials for an AI provider — but it's bound to a project. The API key for OpenAI is stored as a JFrog secret. The connection links that secret to this specific project. Developers in this project can use OpenAI; developers in other projects cannot — unless they have their own connection."*

---

## Act 2 — Model Discovery & Allowance (3–4 min)

**Goal:** Show the admin workflow: discover a model, evaluate security, allow or block it for the project.

### 2.1 — Discover Models

**Navigate to:** AI/ML → Discovery

**Point out:**
- Discovery shows all known AI assets — models from HuggingFace, API models, MCP servers
- Status filter: unallowed (not yet in any project) vs. allowed (in at least one project)
- Search for "code summarization" or "bart"

**Spoken:**

> *"Discovery is where admins evaluate AI assets before authorizing them. Think of it as the staging area — before anything reaches developers, it has to come through here."*

### 2.2 — Examine the Blocked Model

**Click on:** `microsoft/codebert-base`

**Show:**
- Security scan result: critical severity, pickle payload detected
- Evidence tab: file name, attack vector (deserialization → RCE), CVSS 9.3
- Curation status: BLOCKED

**Spoken:**

> *"This model has a malicious pickle payload. Pickle is Python's serialization format — loading this model would execute arbitrary code. JFrog's security engine flagged it. Because of this finding, I would never allow this into any project."*

### 2.3 — Allow the Approved Model

**Click on:** `facebook/bart-large-cnn`

**Show:**
- Clean security scan — no findings
- License: MIT (approved)
- Click **"Allow"**

**In the Allow dialog:**
- Select project: `ml-code-review`
- System detects existing connection for HuggingFace in this project — no re-authentication needed
- Confirm

**Spoken:**

> *"I'm allowing this model specifically for the `ml-code-review` project. The connection is already set up — JFrog sees that HuggingFace is already connected to this project so it reuses the credential. The model now appears in the Registry for this project."*

### 2.4 — Show the Registry

**Navigate to:** AI/ML → Registry → filter by project: `ml-code-review`

**Point out:**
- `facebook/bart-large-cnn` is now visible here
- `microsoft/codebert-base` is absent — not allowed in this project
- This is what developers in the `ml-code-review` project see

**Spoken:**

> *"The Registry is the developer's view — only assets approved for their project. Developers don't see blocked models. They don't see models approved for other teams. They see exactly what they're authorized to use."*

---

## Act 3 — Developer Integration via AI Gateway (3 min)

**Goal:** Show that developers use project-scoped JFrog tokens and call the AI Gateway — never the provider's API key directly.

### 3.1 — Generate a Project Token

**Navigate to:** AI/ML → Registry → `facebook/bart-large-cnn` → click **"Use Model"**

**In the setup pane:**
- Authenticates with JFrog credentials
- Token generated: `jfrog-scoped-token-abc123...` (scoped to `ml-code-review`)
- Code snippet generated automatically

**Spoken:**

> *"The developer clicks 'Use Model' and authenticates with their JFrog account. They get a JFrog-issued token — not OpenAI's API key. JFrog acts as the gateway."*

### 3.2 — Show the Generated Code

**Display the Python snippet from the "Use Model" pane:**

```python
from openai import OpenAI

client = OpenAI(
    api_key="<jfrog-project-scoped-token>",          # JFrog token, not OpenAI key
    base_url="https://yourcompany.ml.jfrog.io/v1"   # JFrog AI Gateway
)

response = client.chat.completions.create(
    model="HuggingFace/facebook/bart-large-cnn",
    messages=[{"role": "user", "content": "Summarize this code: ..."}]
)
```

**Spoken:**

> *"Look at this code. The `api_key` is a JFrog token — not OpenAI's API key. The `base_url` is JFrog's AI Gateway. The developer's code never touches the upstream provider directly. All calls route through JFrog — where they're logged, metered, and policy-enforced."*

> *"If this developer leaves the company, or the team's project is decommissioned, you revoke the JFrog token. The AI provider's key is never exposed."*

---

## Act 4 — MCP Registry + Tool Policies (3 min)

**Goal:** Show that MCP servers are governed the same way — per project, with fine-grained tool-level policies.

### 4.1 — Show the MCP Registry

**Navigate to:** AI/ML → Registry → filter: MCP Servers → project: `ml-code-review`

**Point out:**
- `github-mcp` is in the project's MCP Registry
- Status: Active, project-scoped

**Spoken:**

> *"MCP servers go through the same governance flow. An admin discovers them, evaluates them, and adds them to a project's MCP Registry. Developers in this project can use these MCP servers — and nothing else."*

### 4.2 — Show Tool Policies

**Click on:** `github-mcp` → **Identified Tools** tab → **Tool Policy**

**Show:**
- Allow list: `^get_.*` (read operations), `^list_.*` (list operations)
- Deny list: `.*delete.*` (block all delete operations)

**Spoken:**

> *"This is tool-level governance. The team can use GitHub MCP's read and list tools — `get_file_contents`, `list_repositories`. But write tools, and especially `delete_*` tools, are blocked. The policy is regex-based, per project, per MCP server."*

### 4.3 — Show Developer MCP Gateway Setup

**Switch to terminal:**

```bash
# Developer runs this once — installs the JFrog MCP Gateway
export HOST_DOMAIN=yourcompany.jfrog.io
export PROJECT_KEY=ml-code-review
export CLIENT_ID=claude

bash <(curl -fL https://releases.jfrog.io/artifactory/jfrog-cli-plugins/mcp-gateway/latest/scripts/mcp-gateway.sh)
```

**Point out:** `PROJECT_KEY=ml-code-review` — the project key is the governance handle.

**Show the Claude Code `.mcp.json`:**
```json
{
  "mcpServers": {
    "JFrogMCPGateway": {
      "command": "jf",
      "args": ["mcp-gateway", "run"]
    }
  }
}
```

**Spoken:**

> *"The developer runs one command. `PROJECT_KEY` tells the gateway which project's approved MCP servers to expose. When Claude Code calls a tool, it goes through the JFrog MCP Gateway, which enforces the tool policies we just saw. A `delete_repository` call would be silently blocked."*

---

## Act 5 — Shadow AI → Project Allowance (2 min)

**Goal:** Show Shadow AI detection and the governance loop that brings unmanaged calls under project control.

**Navigate to:** AI/ML → Discovery → Shadow AI (or AI Gateway panel)

**Show:**
- "3 unmanaged AI API calls detected"
- Direct Anthropic API calls from a CI job (outside the Gateway)
- Gemini calls from a developer workstation

**Spoken:**

> *"Before AI Catalog, these were invisible. A CI job is calling Anthropic directly — bypassing the project governance entirely. The developer's machine is hitting Gemini with a hardcoded API key."*

**Show the "Allow" action on one of the shadow AI entries:**
- Click "Allow to Project"
- Select: `ml-code-review`
- System prompts: create a Connection for Anthropic in this project? → Yes
- Provide API key secret → Confirm

**Spoken:**

> *"The governance action here isn't to block and break the workflow — it's to bring the call under project governance. We're creating a connection for Anthropic in the `ml-code-review` project. From this point, calls route through the AI Gateway. The raw API key is replaced with a JFrog project token. The developer's code stays the same; the governance layer is inserted transparently."*

---

## Closing (1 min)

> *"Let's recap the governance model:"*
>
> *"A Project is the unit of governance. You allow models, connect providers, and register MCP servers at the project level — not globally. One team gets OpenAI; another gets HuggingFace models. Each team's tool policies are separate."*
>
> *"Developers get project-scoped JFrog tokens, not raw API keys. All calls route through the AI Gateway — logged, metered, policy-enforced. Same for MCP servers: the MCP Gateway enforces tool-level policies per project."*
>
> *"Shadow AI detection feeds back into this loop. When unmanaged calls are found, the path is 'allow to project' — not 'block and break.' The governance layer is inserted without disrupting existing workflows."*
>
> *"JFrog brings the same supply chain trust model that governs your software artifacts — to AI. One platform. Project-scoped. Total visibility."*

---

## After the Demo

```bash
./scripts/reset.sh   # restore demo state for next run
```

See [`docs/troubleshooting.md`](docs/troubleshooting.md) for recovery procedures.

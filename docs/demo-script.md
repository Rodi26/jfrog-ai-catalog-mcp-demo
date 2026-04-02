# Detailed Demo Script

Presenter reference with exact steps, expected UI states, and talking points for each act.

**Core governance model to keep in mind throughout:**
> Project = governance boundary. Every allow, every credential, every MCP server is scoped to a Project. Developers call the AI Gateway with JFrog project-scoped tokens — never raw provider keys.

---

## Setup (Before Audience Arrives)

1. Run `./scripts/validate.sh` — confirm all green
2. Log into JFrog SaaS as admin — navigate to **Administration → Projects**
3. Confirm `ml-code-review` project exists
4. Navigate to **AI/ML Settings → Connections** — confirm two connections exist
5. Navigate to **AI/ML → Discovery** — confirm models are visible
6. Have `scripts/demo-prompts.txt` open for Act 4 MCP Gateway commands
7. Run `./scripts/reset.sh` if this is not the first demo run of the day

---

## Introduction (1 minute)

**Spoken:**

> *"AI models and MCP servers are the new open-source packages. They carry the same supply chain risks — malicious payloads, license violations, vulnerable dependencies — and most organizations have zero governance over them."*

> *"JFrog AI Catalog solves this the same way Artifactory solved open-source sprawl: with a single, governed platform. The governance model is project-based — a team gets access to the AI assets they're authorized for, through credentials they never hold directly, enforced by the JFrog AI Gateway."*

> *"I'm going to show you a 14-minute walkthrough of the full governance loop: project setup, model allowance, developer integration, MCP server governance, and shadow AI. Let's start with the Project."*

---

## Act 1 — Project Setup + Provider Connections (2–3 min)

### Step 1.1 — Show the Project

**Navigate to:** Administration → Projects → `ml-code-review`

**UI elements to show:**
- Project key: `ml-code-review` (this is the `PROJECT_KEY` developers use)
- Display name: ML Code Review
- Admin privileges enabled

**Spoken:**
> *"A JFrog Project is the governance boundary. When we allow a model, we allow it for a specific project. When a developer gets access, it's scoped to this project. One team can use DeepSeek; another is restricted to OpenAI. Enforced through the Project."*

---

### Step 1.2 — Show Provider Connections

**Navigate to:** AI/ML Settings → Connections

**UI elements to show:**
- `ml-openai-connection` — project: `ml-code-review`, provider: OpenAI
- `ml-huggingface-connection` — project: `ml-code-review`, provider: HuggingFace

Click `ml-openai-connection` to show detail:
- Project binding: `ml-code-review`
- Provider: OpenAI
- API key secret: `openai-api-key` (stored as JFrog secret — key value is never visible)

**Spoken:**
> *"A Connection is the `(provider, project)` credential binding. The OpenAI API key is stored as a JFrog secret. The Connection links that secret to this specific project. Developers in `ml-code-review` can use OpenAI through the AI Gateway. Developers in other projects cannot — unless they have their own connection."*

> *"From the JFrog documentation: 'Each model provider-project pair requires a unique connection.' This is the rule. It's not optional; it's the enforcement mechanism."*

---

## Act 2 — Model Discovery & Allowance (3–4 min)

### Step 2.1 — Discovery Overview

**Navigate to:** AI/ML → Discovery

**Point out:**
- Filter bar at top: status (Unallowed / Allowed / Both), type (All / Custom / External / Package)
- Search for `bart` or `code summarization`
- All models shown here are candidates — none are in any project's Registry yet (unless previously allowed)

**Spoken:**
> *"Discovery is the staging area. Think of it as the 'evaluate before you authorize' zone. Models appear here from Hugging Face, from your own repos, and from connected API providers. Admins evaluate them here before allowing them into a project."*

---

### Step 2.2 — Show the Blocked Model

**Click on:** `microsoft/codebert-base`

**Point out:**
- Security scan result: Critical, Malicious Code
- Evidence tab: file `pytorch_model.bin`, pickle payload, deserialization → RCE vector
- CVSS: 9.3
- Curation policy: BLOCKED on ingest

**Spoken:**
> *"This model has a malicious pickle payload. Loading it with `torch.load()` executes arbitrary code. JFrog's security engine found this on ingest. Because of this, I would never allow this model into any project — it will stay blocked in Discovery."*

---

### Step 2.3 — Allow the Approved Model

**Click on:** `facebook/bart-large-cnn`

**Point out first:**
- Clean security scan: no findings
- License: MIT
- Source: HuggingFace

**Click "Allow"**

**In the Allow dialog:**
- Select project: `ml-code-review`
- *System check:* "HuggingFace connection for ml-code-review already exists — reusing ml-huggingface-connection"
- Confirm

**Spoken:**
> *"I'm allowing this model for the `ml-code-review` project. The system checks whether a HuggingFace connection already exists for this project — it does, so no new credentials are needed. The model is now in the Registry for this project."*

---

### Step 2.4 — Show the Registry

**Navigate to:** AI/ML → Registry → filter project: `ml-code-review`

**Point out:**
- `facebook/bart-large-cnn` is now visible — ALLOWED
- `microsoft/codebert-base` is absent — blocked, never allowed
- This is what the `ml-code-review` team sees when browsing approved AI assets

**Spoken:**
> *"The Registry is the developer's view. Only assets approved for their project. They don't see blocked models. They don't see assets approved for other teams."*

---

## Act 3 — Developer Integration via AI Gateway (3 min)

### Step 3.1 — Generate a Project-Scoped Token

**Navigate to:** AI/ML → Registry → `facebook/bart-large-cnn` → click **"Use Model"**

**In the "Use Model" pane:**
- Authenticate with JFrog credentials
- Token generated: `jfrog-token-ml-code-review-...` (project-scoped)
- Code snippets shown for Python, JavaScript, cURL

**Spoken:**
> *"The developer clicks 'Use Model.' They authenticate with their JFrog account. They get a JFrog-issued token — not OpenAI's API key. The token is scoped to the `ml-code-review` project."*

---

### Step 3.2 — Show the Generated Code Snippet

**Display the Python snippet:**

```python
from openai import OpenAI

client = OpenAI(
    api_key="<jfrog-project-scoped-token>",          # JFrog token — NOT the provider key
    base_url="https://yourcompany.ml.jfrog.io/v1"   # JFrog AI Gateway
)

response = client.chat.completions.create(
    model="HuggingFace/facebook/bart-large-cnn",
    messages=[{"role": "user", "content": "Summarize: ..."}]
)
```

**Spoken:**
> *"Look at this code. Standard OpenAI SDK — but the `api_key` is a JFrog token, and the `base_url` is the JFrog AI Gateway at `ml.jfrog.io`. The developer's code never touches HuggingFace or OpenAI directly. All calls route through JFrog — where they're logged, metered, and policy-enforced."*

> *"If this developer leaves the company, you revoke the JFrog token. The provider's API key is never compromised. If the connection's API key needs rotating, you rotate it in one place — the JFrog Secret — and every project that uses that connection gets the update automatically."*

---

## Act 4 — MCP Registry + Tool Policies (3 min)

### Step 4.1 — Show MCP Registry in Admin View

**Navigate to:** AI/ML → Registry → MCP Servers tab → project: `ml-code-review`

**Point out:**
- `github-mcp` — active, project-scoped
- `jfrog-mcp` — active, project-scoped
- No other MCP servers visible — only what the admin registered for this project

**Spoken:**
> *"MCP servers go through the same governance flow as models. An admin adds them to a project's MCP Registry. Developers in this project can use these — and nothing else."*

---

### Step 4.2 — Show Tool Policies

**Click on:** `github-mcp` → **Identified Tools** tab

**Show the tool list:** ~40 tools including `get_file_contents`, `list_repositories`, `create_repository`, `delete_repository`, etc.

**Navigate to:** Tool Policy configuration

**Show:**
- Allow list: `^get_.*`, `^list_.*`, `^search_.*`
- Deny list: `.*delete.*`, `.*push.*`, `.*merge.*`

**Spoken:**
> *"This is tool-level governance. The regex allow list: tools matching `get_*` and `list_*` are permitted — read operations. The deny list blocks `*delete*` — all delete operations are blocked regardless of other rules. This policy is per MCP server, per project. The data-science project might have different policies for the same MCP server."*

---

### Step 4.3 — Developer MCP Gateway Setup

**Switch to terminal:**

```bash
# One-time setup — run as developer
export HOST_DOMAIN=yourcompany.jfrog.io
export PROJECT_KEY=ml-code-review
export CLIENT_ID=claude

bash <(curl -fL https://releases.jfrog.io/artifactory/jfrog-cli-plugins/mcp-gateway/latest/scripts/mcp-gateway.sh)
```

**Highlight:** `PROJECT_KEY=ml-code-review` — the project is the governance handle

**Show the Claude Code config generated (`.mcp.json`):**
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
> *"The developer runs one install command with their `PROJECT_KEY`. The gateway knows which project's approved MCP servers to expose. When Claude Code calls a tool, it goes through the JFrog MCP Gateway, which enforces the tool policies we saw. A `delete_repository` call would be rejected. A `get_file_contents` call would go through."*

> *"The developer's AI coding assistant is now operating inside the project's governance boundary — the same boundary that governs which AI models they can call, which MCP servers they can access, and which tools within those servers they can execute."*

---

## Act 5 — Shadow AI → Project Allowance (2 min)

**Navigate to:** AI/ML → Discovery → Shadow AI panel (or AI/ML → AI Gateway → Shadow AI)

**Show:**
- "3 unmanaged AI API calls detected"
- `anthropic.com` calls from a CI job (not routed through AI Gateway)
- `generativelanguage.googleapis.com` calls from a developer workstation (direct Gemini)

**Spoken:**
> *"Before AI Catalog, these were invisible. A CI job is calling Anthropic directly — bypassing the project governance entirely. The developer's machine is hitting Gemini with a hardcoded API key."*

---

**Show the "Allow to Project" action on the Anthropic entry:**

Click "Allow" → in the dialog:
- Select project: `ml-code-review`
- System: "No Anthropic connection exists for ml-code-review — create one?"
- Yes: enter connection name `ml-anthropic-connection`, create API key secret
- Confirm

**Spoken:**
> *"The governance action here isn't 'block and break the workflow' — it's 'bring it under project governance.' We're creating an Anthropic connection for the `ml-code-review` project. From this point, the CI job's calls should route through the AI Gateway using a project token. The raw API key is replaced. The developer's code gets updated to use the gateway endpoint."*

> *"Same way JFrog solved open-source sprawl with Artifactory — one governed source, everything flows through — we're solving AI sprawl. One platform. Project-scoped. Total visibility."*

---

## Closing (1 min)

> *"Let's recap the governance model:"*
>
> *"A Project is the unit. You allow models, connect providers, and register MCP servers at the project level. Different teams get different AI access — enforced, not just configured."*
>
> *"Developers get project-scoped JFrog tokens, not raw API keys. All LLM calls route through the AI Gateway. MCP tool calls route through the MCP Gateway with project-scoped tool policies."*
>
> *"Shadow AI detection feeds back into this loop. Unmanaged calls get brought under project governance — not blocked."*
>
> *"JFrog AI Catalog brings the same supply chain trust model to AI. One platform. Project-scoped. Total visibility."*

---

## Q&A Preparation

See [`docs/faq.md`](faq.md) for full Q&A prep.

Key questions to expect:
- "How is this different from just using OpenAI's organization-level access controls?"
- "What if a team needs a model that's not yet in Discovery?"
- "How does the AI Gateway affect latency?"
- "Can we use this with self-hosted models?"
- "Is the MCP Gateway generally available?"

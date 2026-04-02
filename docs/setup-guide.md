# Full Setup Guide

Complete environment setup for the JFrog AI Catalog MCP Demo.

---

## Overview

Setup has two phases:
1. **Automated** — `./scripts/setup.sh` creates the JFrog Project, Artifactory repositories, and security policies
2. **Manual** — AI Catalog UI steps for Provider Connections, Model Allowances, and MCP Registry (these are not yet accessible via API in the current beta)

---

## Phase 1: JFrog SaaS Prerequisites

### Provision a JFrog SaaS Instance

1. Go to https://jfrog.com/start-free/ → select "JFrog Cloud" (SaaS)
2. Select **Enterprise X** trial (required for AI Catalog + Xray)
3. Your URL will be `https://yourname.jfrog.io`

### Enable AI Catalog and Xray

1. Log in as admin → Administration → AI Catalog → enable
2. Administration → Xray → Indexing → enable Machine Learning package type

### Generate an Admin Access Token

1. Administration → User Management → Access Tokens
2. Create token with Admin scope
3. Copy the token value (shown once)

---

## Phase 2: Automated Setup

```bash
git clone https://github.com/Rodi26/jfrog-ai-catalog-mcp-demo.git
cd jfrog-ai-catalog-mcp-demo

export JFROG_URL=https://yourcompany.jfrog.io
export JFROG_ACCESS_TOKEN=your-admin-token

./scripts/setup.sh
```

This creates:
- **JFrog Project** `ml-code-review` — the demo governance boundary
- **Artifactory repositories**: `jfrog-ai-demo-huggingface-remote`, `jfrog-ai-demo-models-local`, `jfrog-ai-demo-virtual`
- **Curation policy**: `block-malicious-ai-models`
- **Xray security policy**: `ai-catalog-security-policy`

---

## Phase 3: Manual UI Steps (AI Catalog)

### 3.1 — Create Provider Connections

Provider Connections bind a `(provider, project)` pair to stored credentials. Each connection is unique per pair.

**Navigate to:** AI/ML Settings → Connections → Create new connection

**Connection 1 — OpenAI for ml-code-review:**
- Name: `ml-openai-connection`
- Project: `ml-code-review`
- Provider: OpenAI
- API Key Secret: create new secret named `openai-api-key`, paste your OpenAI API key
- Save

**Connection 2 — HuggingFace for ml-code-review:**
- Name: `ml-huggingface-connection`
- Project: `ml-code-review`
- Provider: HuggingFace
- API Key Secret: create new secret named `huggingface-api-key`, paste your HuggingFace token
- Save

You should see both connections listed, both bound to `ml-code-review`.

---

### 3.2 — Discover and Allow Models

**Navigate to:** AI/ML → Discovery

#### Seed the blocked model (Act 2 security scenario)

The demo requires `microsoft/codebert-base` to show as blocked with scan evidence:
1. Search for `microsoft/codebert-base`
2. If not visible, it may not yet be indexed — proceed to allowing the clean models
3. If visible: do NOT allow it — it should remain blocked in Discovery with security findings

> **Note:** If your demo tenant doesn't show this model with a scan result, use screenshots from `demo-assets/screenshots/act2-blocked-model.png` as fallback for Act 2.

#### Allow the clean models

**Model 1 — facebook/bart-large-cnn:**
1. Search for `facebook/bart-large-cnn`
2. Click on it → review security scan (should be clean), license (MIT)
3. Click **"Allow"**
4. Select project: `ml-code-review`
5. System detects `ml-huggingface-connection` → click Confirm

**Model 2 — salesforce/codet5-base:**
1. Search for `salesforce/codet5-base`
2. Click → verify clean scan
3. Click **"Allow"** → project: `ml-code-review` → Confirm

**Verify:** Navigate to AI/ML → Registry → filter by `ml-code-review` → confirm both models appear.

---

### 3.3 — Register MCP Servers

**Navigate to:** AI/ML → Discovery → MCP Servers tab

#### Add github-mcp to the project

1. Search for `github-mcp` (or browse the MCP server catalog)
2. Click → review MCP Server Info + Identified Tools
3. Click **"Add to Registry"**
4. Select project: `ml-code-review`
5. Configure **Tool Policy** (select "Manual — Recommended"):
   - Allow list: `^get_.*`, `^list_.*`, `^search_.*`
   - Deny list: `.*delete.*`, `.*push.*`, `.*merge.*`
6. Configure required environment variables (e.g., `GITHUB_TOKEN`)
7. Click **"Save Configuration"**

#### Add jfrog-mcp (optional, for admin tools demo)

1. Search for `jfrog-mcp`
2. Add to Registry → project: `ml-code-review`
3. Tool policy: Allow: `jfrog_get_.*`, `jfrog_list_.*` | Deny: `.*delete.*`, `.*create.*`
4. Configure `JFROG_ACCESS_TOKEN` environment variable
5. Save

---

### 3.4 — Seed Shadow AI Entries (Act 5)

For the Shadow AI demo to work, your tenant needs detected external API calls.

**Option A (preferred):** If your JFrog instance has AI Gateway deployed, actual external calls will be detected automatically. Run some direct API calls from a test machine:

```bash
# Simulate shadow AI — run from a machine outside your AI Gateway
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "claude-3-haiku-20240307", "max_tokens": 10, "messages": [{"role": "user", "content": "ping"}]}'
```

**Option B (fallback):** Shadow AI detection may not be visible on all tenant configurations. Use screenshots from `demo-assets/screenshots/act4-shadow-ai.png` and narrate the scenario.

---

## Phase 4: MCP Gateway Setup (Developer Machine)

For Act 4, you need the JFrog MCP Gateway installed on the presenter's machine:

```bash
export HOST_DOMAIN=yourcompany.jfrog.io
export PROJECT_KEY=ml-code-review
export CLIENT_ID=claude

bash <(curl -fL https://releases.jfrog.io/artifactory/jfrog-cli-plugins/mcp-gateway/latest/scripts/mcp-gateway.sh)
```

The installer will:
1. Install JFrog CLI (if not present)
2. Install the `mcp-gateway` plugin
3. Authenticate your machine with the JFrog instance
4. Set `PROJECT_KEY=ml-code-review` as the active project
5. Configure Claude Code's `.mcp.json` to use the gateway
6. Print a magic link — click it to complete authorization

Verify:
```bash
jf mcp-gateway status
# Expected: connected, project: ml-code-review
```

---

## Phase 5: Validate Everything

```bash
./scripts/validate.sh
```

All checks should pass before presenting. See [`docs/troubleshooting.md`](troubleshooting.md) if any check fails.

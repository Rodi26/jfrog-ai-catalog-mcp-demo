# Demo Guide — From Pull to Production: Governing AI with JFrog

**For presenters.** Read this before every demo run.

---

## Before You Present

- [ ] Run `./scripts/validate.sh` — all checks must pass
- [ ] Open Claude Desktop (or Cursor) and confirm JFrog MCP tools are available
- [ ] Log into your JFrog SaaS instance in the browser — navigate to the AI Catalog
- [ ] Have `scripts/demo-prompts.txt` open in a separate editor window
- [ ] Run `./scripts/reset.sh` if you've demoed before — resets state to clean
- [ ] Test network connectivity to your JFrog SaaS instance

**Fallback:** If live MCP calls fail, use `demo-assets/expected-outputs/mcp-session-transcript.md` as the offline script reference. Screenshots in `demo-assets/screenshots/` show expected UI state.

---

## Demo Overview

**Title:** *From Pull to Production — Governing AI with JFrog*
**Duration:** ~12 minutes
**Primary tool:** Claude Desktop or Cursor with JFrog MCP Server
**Secondary:** JFrog AI Catalog UI (browser, for showing governance evidence)

---

## Act 1 — Model Discovery via MCP (3–4 min)

**Goal:** Show that the AI assistant can query JFrog for HuggingFace models, check their governance status, and surface security information — all in one conversation.

**Setup:** Claude Desktop or Cursor open, JFrog MCP configured.

### Paste this prompt:

```
I need to find Hugging Face models suitable for code summarization.
Show me what's available in JFrog, check their curation status, 
and flag any known vulnerabilities.
```

*(Copy from `scripts/demo-prompts.txt` — Act 1)*

### What will happen:

1. Claude calls `jfrog_get_package_info` with `packageType: "huggingface"` — lists available models
2. Claude calls `jfrog_get_package_curation_status` for each candidate — shows approved/blocked/inconclusive
3. Claude calls `jfrog_get_package_version_vulnerabilities` for flagged versions — shows CVE details
4. Claude presents a comparison table: safe models vs. blocked model

### Key talking points:

> *"The AI is querying real JFrog data — not a mock. Everything you see is live from your Artifactory instance."*

> *"Notice how it checked curation status automatically — this is how JFrog's curated repository policies enforce governance without the developer having to think about it."*

> *"One of these models is blocked. Let's look at why."*

---

## Act 2 — Security Deep-Dive (2–3 min)

**Goal:** Show the AI Catalog UI with scan evidence. Make the security threat concrete and the governance response automatic.

**Setup:** Switch to the JFrog AI Catalog browser tab.

### Navigate to:

1. AI Catalog → **Packages** → filter by type: HuggingFace
2. Click the **blocked model** (should be flagged with a red security indicator)
3. Open the **Scan Evidence** tab

### Show:
- File scan result: pickle file detected with code execution payload
- Severity: Critical
- **Curation policy** that triggered the block (show the rule)
- Switch to the **approved model** — show clean evidence trail, license info, approval timestamp

### Key talking points:

> *"JFrog's evidence engine eliminates 96% of false positives. When it flags something, it's real. This is based on JFrog's own security research — they discovered 3 critical PickleScan zero-days in 2025."*

> *"The policy automatically blocked the model from reaching any developer or production system. No human had to intervene."*

> *"Look at the clean model — you can see exactly when it was pulled, what was scanned, what policy applied, and who approved it. Complete lineage."*

---

## Act 3 — MCP Project Setup (2–3 min)

**Goal:** Show that the entire ML pipeline infrastructure can be set up via natural language. Compress 6 manual steps into one conversation turn.

**Setup:** Back to Claude Desktop or Cursor.

### Paste this prompt:

```
Create a new JFrog project called "ml-code-review" and set up 
repositories for a Python ML pipeline:
- a local repository for storing approved models
- a remote HuggingFace proxy repository 
- a virtual repository that aggregates both with "ml-" prefix

Use appropriate settings for a machine learning project.
```

*(Copy from `scripts/demo-prompts.txt` — Act 3)*

### What will happen:

1. `create_project` → `ml-code-review` project created with environment scoping
2. `create_local_repository` → local model store with machine-learning package type
3. `create_remote_repository` → HuggingFace proxy with caching enabled
4. `create_virtual_repository` → unified access URL aggregating both repos

### Key talking points:

> *"What just happened would normally take 6 manual steps across 3 UI screens. And everything is still fully governed — repos were created with the right package type, project scoping, and default policies."*

> *"This is how AI tooling governs AI tooling. The JFrog MCP Server is itself an AI asset — subject to the same governance as the models it manages."*

> *"Any developer or AI agent on your team can do this now, through the same governed interface."*

---

## Act 4 — Shadow AI (2 min)

**Goal:** Show that AI Catalog detects and surfaces unmanaged AI consumption happening outside the governed channel.

**Setup:** JFrog AI Catalog browser tab.

### Navigate to:
AI Catalog → **Shadow AI** (or equivalent panel in your tenant)

### Show:
- "3 unmanaged AI providers detected" (or similar count)
- Direct OpenAI calls from a service account
- Anthropic API calls from a CI job
- Gemini calls from a developer workstation
- "Route through AI Gateway" action available

### Key talking points:

> *"Before AI Catalog, these were invisible. Same way JFrog solved open-source sprawl with Artifactory, we're solving AI sprawl."*

> *"The same developer pulling a model from Hugging Face is also making direct calls to OpenAI from production code. Both are now visible in one place."*

> *"Shadow AI detection is automatic — no instrumentation required. JFrog learns from your network traffic and flags unmanaged consumption."*

---

## Closing (1 min)

> *"JFrog AI Catalog extends the same supply chain trust model to AI. From the model you pull from Hugging Face, to the MCP server your agent calls, to the shadow AI in your infrastructure. One platform. One policy. Total visibility."*

**End state to have visible:**
- Blocked model in AI Catalog with scan evidence
- Approved model with clean lineage and governance trail
- New `ml-code-review` project with 3 repositories
- Shadow AI panel showing governed external calls

---

## Timing Guide

| Act | Start | End | Buffer |
|-----|-------|-----|--------|
| Intro | 0:00 | 1:00 | — |
| Act 1: Discovery | 1:00 | 4:30 | 30s |
| Act 2: Security | 4:30 | 7:30 | 30s |
| Act 3: Setup | 7:30 | 10:30 | 30s |
| Act 4: Shadow AI | 10:30 | 12:30 | 30s |
| Close | 12:30 | 13:00 | — |

**Total:** ~13 minutes with buffers.

---

## If Something Goes Wrong

See [`docs/troubleshooting.md`](docs/troubleshooting.md).

**Quick recovery options:**

| Problem | Recovery |
|---------|----------|
| MCP call fails or times out | Use offline transcript from `demo-assets/expected-outputs/mcp-session-transcript.md` |
| UI not showing scan evidence | Use screenshots from `demo-assets/screenshots/` |
| Shadow AI panel not available | Skip Act 4 or show screenshots; explain as upcoming/tier-dependent |
| Blocked model not visible | Re-run `./scripts/reset.sh` to restore demo state |

---

## After the Demo

```bash
# Optional: reset state for the next run
./scripts/reset.sh
```

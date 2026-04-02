# Demo Offline Reference Transcript

Use this when the live JFrog AI Catalog UI is unavailable.

**When using offline mode:** Narrate each section as if walking through the live UI. Use screenshots from `../screenshots/` for visual support.

---

## Act 1 — Project Setup + Provider Connections

**Narrator:** "I'm in the JFrog Platform — navigating to Administration → Projects."

### Project view: ml-code-review

```
Project Key:    ml-code-review
Display Name:   ML Code Review
Description:    Demo project for the AI Catalog governance walkthrough
Members:        [admin, dev-team]
Admin Privileges: Manage Members ✓  Manage Resources ✓  Index Resources ✓
```

**Talking point:** *"A JFrog Project is the governance boundary. Everything we do — allowing models, connecting providers, registering MCP servers — is scoped to this project."*

---

### Connections: AI/ML Settings → Connections

```
Connections in ml-code-review:

┌────────────────────────────────────────────────────────────────────┐
│  Name                     │ Project         │ Provider    │ Status │
├────────────────────────────────────────────────────────────────────┤
│  ml-openai-connection     │ ml-code-review  │ OpenAI      │ Active │
│  ml-huggingface-connection│ ml-code-review  │ HuggingFace │ Active │
└────────────────────────────────────────────────────────────────────┘
```

**Detail view — ml-openai-connection:**
```
Name:           ml-openai-connection
Project:        ml-code-review
Provider:       OpenAI
API Key Secret: openai-api-key (stored securely — value not shown)
Created:        2026-04-01
Status:         Active
```

**Talking point:** *"Each connection is a unique (provider, project) pair. The API key is stored as a JFrog Secret. Developers never see it."*

---

## Act 2 — Model Discovery & Allowance

### Discovery view: AI/ML → Discovery

```
Filters: Status: [Unallowed ▼]  Type: [All ▼]  Search: [bart       ]

Results:
┌─────────────────────────────────────────────────────────────────────┐
│  Model                          │ Type      │ Status     │ Security │
├─────────────────────────────────────────────────────────────────────┤
│  facebook/bart-large-cnn        │ Package   │ Unallowed  │ ✅ Clean  │
│  microsoft/codebert-base        │ Package   │ Unallowed  │ 🚫 Critical│
│  salesforce/codet5-base         │ Package   │ Unallowed  │ ✅ Clean  │
└─────────────────────────────────────────────────────────────────────┘
```

---

### Blocked model detail: microsoft/codebert-base

```
Model:          microsoft/codebert-base
Provider:       HuggingFace
Size:           499 MB
Status:         BLOCKED (Curation Policy)
```

**Security Evidence tab:**
```
Severity:       Critical
CVSS Score:     9.3
Type:           Malicious Code
Category:       Pickle Deserialization
File:           pytorch_model.bin
Attack Vector:  Deserialization → Arbitrary Code Execution
Description:    A malicious pickle payload was detected embedded in the
                model binary. Loading this model with torch.load() would
                execute the embedded payload with the calling process
                privileges.
Policy:         block-malicious-ai-models (triggered on ingest)
Discovered:     2026-03-10T14:23:11Z
```

**Talking point:** *"This model has a real malicious payload. JFrog's evidence engine found it on ingest. Because of this, I would never allow this into any project."*

---

### Allow flow: facebook/bart-large-cnn

**Model detail view:**
```
Model:          facebook/bart-large-cnn
Provider:       HuggingFace
Size:           2.3 GB
License:        MIT ✅
Security:       Clean — no findings
Status:         Unallowed
```

**Allow dialog:**
```
Allow model: facebook/bart-large-cnn

Select Project: [ ml-code-review ▼ ]

Provider Connection:
  ✓ ml-huggingface-connection (already configured for this project)
    → No new credentials needed

[ Cancel ]  [ Allow ]
```

**After Allow:**
```
✅ facebook/bart-large-cnn is now allowed in project ml-code-review
   It will appear in the Registry for ml-code-review members.
```

---

### Registry view: AI/ML → Registry (project: ml-code-review)

```
Project: ml-code-review

Models:
┌─────────────────────────────────────────────────────────────────────┐
│  Model                       │ Provider    │ Status   │ License     │
├─────────────────────────────────────────────────────────────────────┤
│  facebook/bart-large-cnn     │ HuggingFace │ Allowed  │ MIT         │
│  salesforce/codet5-base      │ HuggingFace │ Allowed  │ Apache 2.0  │
└─────────────────────────────────────────────────────────────────────┘
Note: microsoft/codebert-base is NOT shown — blocked, never allowed.
```

**Talking point:** *"The Registry is what developers see. Only their project's approved assets. The blocked model is invisible to them."*

---

## Act 3 — Developer Integration via AI Gateway

### "Use Model" pane: facebook/bart-large-cnn

```
How to use facebook/bart-large-cnn

Your project token (scoped to ml-code-review):
  jfrog-ml-code-review-eyJ...  [Copy]

AI Gateway endpoint:
  https://yourcompany.ml.jfrog.io/v1

Code snippet:
```

```python
from openai import OpenAI

client = OpenAI(
    api_key="jfrog-ml-code-review-eyJ...",            # JFrog project token
    base_url="https://yourcompany.ml.jfrog.io/v1"    # JFrog AI Gateway
)

response = client.chat.completions.create(
    model="HuggingFace/facebook/bart-large-cnn",
    messages=[
        {"role": "user", "content": "Summarize this function: ..."}
    ]
)

print(response.choices[0].message.content)
```

**Talking point:** *"The developer gets a JFrog token — not the HuggingFace API key. The base_url is the JFrog AI Gateway. All calls are proxied through JFrog, using the stored Connection credential."*

---

## Act 4 — MCP Registry + Tool Policies

### MCP Registry view: project ml-code-review

```
MCP Servers in ml-code-review:

┌─────────────────────────────────────────────────────────────────────┐
│  Server       │ Type   │ Status │ Tools Available │ Deny Rules       │
├─────────────────────────────────────────────────────────────────────┤
│  github-mcp   │ Remote │ Active │ 24 (of 40)      │ .*delete.*, ...  │
│  jfrog-mcp    │ Remote │ Active │ 12 (of 22)      │ .*delete.*, ...  │
└─────────────────────────────────────────────────────────────────────┘
```

### Tool Policy: github-mcp

```
github-mcp — Tool Policy for ml-code-review

Available tools (40 total):
  get_file_contents, list_repositories, list_commits,
  search_repositories, get_pull_request, list_branches,
  create_repository ✗ (denied), delete_repository ✗ (denied),
  push_files ✗ (denied), merge_pull_request ✗ (denied), ...

Allow list (regex):
  ✓ ^get_.*       →  24 tools matched
  ✓ ^list_.*      →  (included above)
  ✓ ^search_.*    →  (included above)

Deny list (regex):
  ✗ .*delete.*    →  blocks delete_repository, delete_branch, etc.
  ✗ .*push.*      →  blocks push_files
  ✗ .*merge.*     →  blocks merge_pull_request
```

**Talking point:** *"Tool-level governance. The team can use GitHub read tools. Delete, push, and merge are blocked. Per project. Per MCP server."*

---

### MCP Gateway setup (terminal)

```bash
$ export HOST_DOMAIN=yourcompany.jfrog.io
$ export PROJECT_KEY=ml-code-review
$ export CLIENT_ID=claude

$ bash <(curl -fL https://releases.jfrog.io/artifactory/jfrog-cli-plugins/mcp-gateway/latest/scripts/mcp-gateway.sh)

Installing JFrog CLI...                  ✓
Installing mcp-gateway plugin...         ✓
Authenticating with yourcompany.jfrog.io ✓
Setting active project: ml-code-review   ✓
Configuring Claude Code...               ✓

Magic Link: https://yourcompany.jfrog.io/ml/mcp-gateway/auth?token=...
→ Open in browser to complete setup

Setup complete. Run: jf mcp-gateway run
```

**Talking point:** *"`PROJECT_KEY` is the governance handle. The gateway knows which MCP servers and which tool policies apply to this developer's project."*

---

## Act 5 — Shadow AI → Project Allowance

### Shadow AI panel

```
Shadow AI — Unmanaged AI API Calls Detected

┌─────────────────────────────────────────────────────────────────────────┐
│  Provider    │ Caller                  │ Calls │ Last Seen  │ Action    │
├─────────────────────────────────────────────────────────────────────────┤
│  Anthropic   │ CI job: build-service   │ 1,247 │ 5 min ago  │ [Allow]   │
│  Gemini      │ dev: alice@company.com  │  342  │ 2 hr ago   │ [Allow]   │
│  OpenAI      │ svc: analytics-api      │  891  │ 1 hr ago   │ [Allow]   │
└─────────────────────────────────────────────────────────────────────────┘
```

**Talking point:** *"A CI job is calling Anthropic directly — bypassing governance entirely. A developer's machine is hitting Gemini with a hardcoded API key."*

---

### "Allow to Project" dialog for Anthropic

```
Allow: Anthropic API (from CI job: build-service)

Select Project: [ ml-code-review ▼ ]

Provider Connection:
  No Anthropic connection found for ml-code-review
  → Create new connection?  [Yes ▼]

  Connection name:    ml-anthropic-connection
  API Key Secret:     [ anthropic-api-key ▼ ] (create new)

[ Cancel ]  [ Allow and Create Connection ]
```

**After Allow:**
```
✅ Anthropic allowed in ml-code-review
   Connection ml-anthropic-connection created.
   
   Next steps for the CI job:
   • Replace ANTHROPIC_API_KEY with a JFrog project token
   • Update base_url to: https://yourcompany.ml.jfrog.io/v1
   • Migration guide: docs.jfrog.com/ai-ml/docs/integrate-models-in-your-code
```

**Talking point:** *"The governance action is 'bring it under project governance' — not block and break. The call is now going to route through the AI Gateway, using the JFrog project token. The developer experience doesn't change; the governance layer is inserted."*

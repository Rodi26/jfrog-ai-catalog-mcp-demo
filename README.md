# JFrog AI Catalog MCP Demo

> **From Discovery to Governance — AI Catalog with JFrog Projects**

A full end-to-end demo repository showing how JFrog Projects are the central governance unit for AI assets: models, LLM API providers, and MCP servers.

---

## What This Demo Proves

In JFrog AI Catalog, **a Project is the governance boundary** for all AI consumption. You don't just block or allow AI assets globally — you authorize them per Project, bind credentials per Project, and issue project-scoped tokens that route through the JFrog AI Gateway. Developers never hold raw provider API keys; they hold JFrog tokens.

This demo shows:
- How admins **discover and allow** Hugging Face models into a Project
- How admins **connect AI providers** (OpenAI, Anthropic) with project-scoped credentials
- How developers get a **project-scoped JFrog token** and call the AI Gateway
- How **MCP servers are governed** through the Project's MCP Registry with tool-level policies
- How **Shadow AI** (unmanaged API calls) surfaces and is brought under Project governance

---

## Demo Acts (~14 minutes)

| Act | Title | Duration | What's Shown |
|-----|-------|----------|--------------|
| 1 | Project Setup + Provider Connection | 2–3 min | Admin creates `ml-code-review` project, connects OpenAI + HuggingFace |
| 2 | Model Discovery & Allowance | 3–4 min | Admin discovers models, blocks malicious, allows approved to the project |
| 3 | Developer Integration via AI Gateway | 3 min | Dev gets project token, calls JFrog AI Gateway — not OpenAI directly |
| 4 | MCP Registry + Tool Policies | 3 min | Admin adds MCP servers to project, defines allow/deny tool policies |
| 5 | Shadow AI → Project Allowance | 2 min | Unmanaged calls detected, admin allows them into the governed project |

---

## The Core Governance Model

```
┌─────────────────────────────────────────────────────────────┐
│                  JFrog Project: ml-code-review               │
│                                                              │
│  Allowed Models:                 Connected Providers:        │
│  ✅ facebook/bart-large-cnn       🔗 OpenAI (connection-1)   │
│  ✅ openai/gpt-4o                 🔗 HuggingFace             │
│  🚫 microsoft/codebert-base      🔗 Anthropic (connection-2) │
│     (blocked — pickle payload)                               │
│                                                              │
│  MCP Registry:                   Tool Policies:              │
│  📦 github-mcp                    Allow: ^get_.*, ^list_.*   │
│  📦 jfrog-mcp                     Deny:  .*delete.*          │
│                                                              │
│  Developer Access:                                           │
│  🎫 Project-scoped token (never the raw provider key)        │
│  🌐 https://<org>.ml.jfrog.io/v1 (AI Gateway endpoint)      │
└─────────────────────────────────────────────────────────────┘
         │                              │
         ▼                              ▼
  Developer calls AI Gateway    Developer runs MCP Gateway
  with JFrog token              jf mcp-gateway run
  (proxied to provider)         (PROJECT_KEY=ml-code-review)
```

---

## Repository Structure

```
jfrog-ai-catalog-mcp-demo/
├── README.md                          # This file
├── DEMO.md                            # Presenter demo guide (start here)
├── QUICKSTART.md                      # 15-minute setup guide
│
├── docs/
│   ├── architecture.md                # System diagram and governance model
│   ├── prerequisites.md               # Requirements checklist
│   ├── setup-guide.md                 # Full environment setup
│   ├── demo-script.md                 # Detailed script (per step)
│   ├── talking-points.md              # Key messages, Q&A prep
│   ├── troubleshooting.md             # Common failures and fallbacks
│   ├── faq.md                         # Anticipated audience questions
│   └── diagrams/
│
├── config/
│   ├── mcp/
│   │   ├── claude-mcp-gateway.json    # Claude Code MCP Gateway config
│   │   ├── claude-desktop-config.json # Claude Desktop (jfrog-mcp admin tools)
│   │   └── vscode-config.json
│   ├── artifactory/
│   │   ├── create-repos.sh            # HuggingFace remote repo setup
│   │   ├── curation-policy.json       # Block malicious models on ingest
│   │   └── project-setup.json         # Project + Connection definitions
│   └── xray/
│       └── security-policy.json
│
├── scripts/
│   ├── setup.sh                       # One-command setup (repos + project)
│   ├── reset.sh                       # Reset between demo runs
│   ├── validate.sh                    # Pre-demo checklist
│   └── demo-prompts.txt               # Copy-paste prompts per act
│
├── demo-assets/
│   ├── screenshots/
│   ├── sample-models/README.md
│   └── expected-outputs/
│       └── mcp-session-transcript.md  # Offline fallback
│
└── .github/
    └── workflows/
        └── validate-config.yml
```

---

## Quick Links

| Resource | Path |
|----------|------|
| Presenter guide | [`DEMO.md`](DEMO.md) |
| 15-minute setup | [`QUICKSTART.md`](QUICKSTART.md) |
| Detailed demo script | [`docs/demo-script.md`](docs/demo-script.md) |
| Copy-paste prompts | [`scripts/demo-prompts.txt`](scripts/demo-prompts.txt) |
| Governance architecture | [`docs/architecture.md`](docs/architecture.md) |
| Troubleshooting | [`docs/troubleshooting.md`](docs/troubleshooting.md) |

---

## Key JFrog AI Catalog Concepts

| Concept | Definition |
|---------|-----------|
| **Project** | The governance boundary. All AI assets are authorized per project. |
| **Connection** | A `(provider, project)` credential binding. Each pair is unique. |
| **Discovery** | Where admins browse and evaluate AI assets before allowing them |
| **Registry** | Where project-approved assets live — what developers see |
| **Allow** | Admin action that moves an asset from Discovery → Registry for a project |
| **AI Gateway** | JFrog proxy at `https://<org>.ml.jfrog.io/v1` — all LLM calls go here |
| **MCP Gateway** | `jf mcp-gateway run` — routes MCP tool calls through project policies |
| **Tool Policy** | Per-MCP-server regex rules: which tools are allowed/denied in a project |
| **Shadow AI** | Unmanaged external AI calls detected by AI Catalog |

---

## Prerequisites (Summary)

- JFrog SaaS with AI Catalog + Xray enabled (Enterprise X tier)
- Admin access token (Admin scope)
- JFrog CLI (`jf`) + `mcp-gateway` plugin installed
- Claude Desktop or VS Code Copilot

See [`docs/prerequisites.md`](docs/prerequisites.md) for details.

---

## Getting Started

```bash
git clone https://github.com/Rodi26/jfrog-ai-catalog-mcp-demo.git
cd jfrog-ai-catalog-mcp-demo
export JFROG_URL=https://yourcompany.jfrog.io
export JFROG_ACCESS_TOKEN=your-admin-token
./scripts/setup.sh
./scripts/validate.sh
open DEMO.md
```

---

## References

- [JFrog AI Catalog overview](https://docs.jfrog.com/ai-ml/docs/jfrog-ai-catalog-overview)
- [Discover and allow models](https://docs.jfrog.com/ai-ml/docs/discover-and-allow-models)
- [Connect AI providers](https://docs.jfrog.com/ai-ml/docs/connect-ai-providers)
- [Integrate models in your code](https://docs.jfrog.com/ai-ml/docs/integrate-models-in-your-code)
- [MCP Registry overview](https://docs.jfrog.com/ai-ml/docs/mcp-registry-overview)
- [Configure tool policies](https://docs.jfrog.com/ai-ml/docs/configure-tool-policies)
- [Introducing JFrog AI Catalog (blog)](https://jfrog.com/blog/introducing-jfrog-ai-catalog/)

## License

Apache 2.0

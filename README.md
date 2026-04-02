# JFrog AI Catalog MCP Demo

> **From Pull to Production — Governing AI with JFrog**

A full end-to-end demo repository showing how to go from **building** to **governing** to **executing** AI workflows using JFrog AI Catalog, Hugging Face models, and the JFrog MCP Server.

---

## What This Demo Proves

AI models are the new open-source packages. They carry the same supply chain risks — malicious payloads, license violations, vulnerable dependencies — and most organizations have zero governance over them. **JFrog AI Catalog changes that.**

This demo shows:
- How AI assets are discovered and governed through JFrog AI Catalog
- How Hugging Face models are scanned, approved, or blocked by Xray policy
- How the JFrog MCP Server turns JFrog into a conversational AI-native platform
- How Shadow AI (unmanaged external AI API calls) is detected and governed
- How a complete ML pipeline can be set up via natural language in one conversation

---

## Demo Acts (12 minutes)

| Act | Title | Duration | What's Shown |
|-----|-------|----------|--------------|
| 1 | Model Discovery via MCP | 3–4 min | Claude queries JFrog for HuggingFace models, checks curation + vulnerabilities live |
| 2 | Security Deep-Dive | 2–3 min | Blocked model with pickle payload; clean model approved with evidence trail |
| 3 | MCP Project Setup | 2–3 min | Natural language creates JFrog project + 3 repositories in one conversation |
| 4 | Shadow AI Detection | 2 min | Unmanaged OpenAI/Anthropic/Gemini calls surfaced for governance |

---

## Repository Structure

```
jfrog-ai-catalog-mcp-demo/
├── README.md                          # This file
├── DEMO.md                            # Presenter demo guide (start here before presenting)
├── QUICKSTART.md                      # 15-minute setup guide
│
├── docs/
│   ├── architecture.md                # System diagram and component relationships
│   ├── prerequisites.md               # JFrog license, SaaS access, tool versions
│   ├── setup-guide.md                 # Full environment setup
│   ├── demo-script.md                 # Detailed script with prompts and expected outputs
│   ├── talking-points.md              # Key messages, competitive angles, Q&A prep
│   ├── troubleshooting.md             # Common failures, fallback steps, offline mode
│   ├── faq.md                         # Anticipated audience questions with answers
│   └── diagrams/                      # Architecture and flow diagrams
│
├── config/
│   ├── mcp/
│   │   ├── claude-desktop-config.json # Claude Desktop MCP configuration
│   │   ├── cursor-config.json         # Cursor MCP configuration
│   │   └── vscode-config.json         # VS Code Copilot MCP configuration
│   ├── artifactory/
│   │   ├── create-repos.sh            # JFrog CLI repo creation script
│   │   ├── curation-policy.json       # Curation policy blocking malicious models
│   │   └── project-setup.json         # Project and repo layout definition
│   └── xray/
│       └── security-policy.json       # Xray security policy for AI assets
│
├── scripts/
│   ├── setup.sh                       # One-command environment setup
│   ├── reset.sh                       # Reset demo state between runs
│   ├── validate.sh                    # Pre-demo validation checklist
│   └── demo-prompts.txt               # Copy-paste MCP prompts for each act
│
├── demo-assets/
│   ├── screenshots/                   # Expected UI state per demo step
│   ├── sample-models/
│   │   └── README.md                  # Notes on demo model assets
│   └── expected-outputs/
│       └── mcp-session-transcript.md  # Offline fallback MCP session transcript
│
└── .github/
    └── workflows/
        └── validate-config.yml        # CI: validates JSON configs on PR
```

---

## Quick Links

| Resource | Path |
|----------|------|
| Demo guide (presenter) | [`DEMO.md`](DEMO.md) |
| 15-minute setup | [`QUICKSTART.md`](QUICKSTART.md) |
| Full environment setup | [`docs/setup-guide.md`](docs/setup-guide.md) |
| Detailed demo script | [`docs/demo-script.md`](docs/demo-script.md) |
| MCP copy-paste prompts | [`scripts/demo-prompts.txt`](scripts/demo-prompts.txt) |
| Troubleshooting | [`docs/troubleshooting.md`](docs/troubleshooting.md) |
| Architecture overview | [`docs/architecture.md`](docs/architecture.md) |

---

## Use Cases

This repository is designed for:
- **Internal demos** — SA and pre-sales walkthroughs
- **Customer demos** — Technical audience and executive presentations
- **Technical walkthroughs** — Deep-dive sessions with engineering teams
- **Workshops** — Hands-on enablement events
- **Enablement** — Onboarding new SAs and field engineers

---

## Prerequisites (Summary)

- JFrog SaaS instance with AI Catalog + Xray enabled (free trial available)
- Claude Desktop or Cursor with MCP support
- JFrog CLI (`jf`) installed
- Git, Node.js, Python 3.10+

See [`docs/prerequisites.md`](docs/prerequisites.md) for the full list.

---

## Getting Started

```bash
# 1. Clone the repo
git clone https://github.com/your-org/jfrog-ai-catalog-mcp-demo.git
cd jfrog-ai-catalog-mcp-demo

# 2. Run setup
./scripts/setup.sh

# 3. Validate the environment
./scripts/validate.sh

# 4. Open the demo guide
open DEMO.md
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Desktop / Cursor                   │
│                     (AI Coding Assistant)                    │
└──────────────────────────┬──────────────────────────────────┘
                           │ MCP Protocol
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   JFrog MCP Server                          │
│              (22 tools across 5 categories)                  │
└──────────────────────────┬──────────────────────────────────┘
                           │ JFrog Platform API
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  JFrog Platform (SaaS)                       │
│  ┌────────────────┐  ┌──────────────┐  ┌──────────────────┐ │
│  │  AI Catalog    │  │  Artifactory │  │      Xray        │ │
│  │  (governance)  │  │  (registry)  │  │  (security scan) │ │
│  └────────────────┘  └──────────────┘  └──────────────────┘ │
└──────────────────────────┬──────────────────────────────────┘
                           │ Proxy / Cache
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   Hugging Face Hub                           │
│              (source of ML models)                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Contributing

This is a demo repository. For improvements, open a PR or raise an issue.

## License

Apache 2.0

# Architecture Overview

## System Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Demo Environment                             │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │              AI Coding Assistant Layer                          │ │
│  │                                                                 │ │
│  │   ┌──────────────────┐       ┌─────────────────────────────┐   │ │
│  │   │  Claude Desktop  │  or   │  Cursor / VS Code Copilot  │   │ │
│  │   └────────┬─────────┘       └──────────────┬──────────────┘   │ │
│  │            │                                │                   │ │
│  │            └──────────────┬─────────────────┘                   │ │
│  │                           │ MCP Protocol (stdio / SSE)          │ │
│  └───────────────────────────┼─────────────────────────────────────┘ │
│                              │                                       │
│  ┌───────────────────────────▼─────────────────────────────────────┐ │
│  │                  JFrog MCP Server                               │ │
│  │                                                                 │ │
│  │   22 tools across 5 categories:                                 │ │
│  │   • Repository Management (create, list, configure)            │ │
│  │   • Build & Runtime (artifact queries, build info)             │ │
│  │   • Access Control (users, permissions, tokens)                │ │
│  │   • Catalog & Curation (AI Catalog, curation status)           │ │
│  │   • Xray Security (vulnerability, license, policy)             │ │
│  │                                                                 │ │
│  │   Hosted at: https://<platform>/mcp  (JFrog SaaS)              │ │
│  │   Auth: OAuth 2.0 (browser flow)                               │ │
│  └───────────────────────────┬─────────────────────────────────────┘ │
│                              │ JFrog REST API                        │
│  ┌───────────────────────────▼─────────────────────────────────────┐ │
│  │                  JFrog Platform (SaaS)                          │ │
│  │                                                                 │ │
│  │  ┌─────────────────┐  ┌──────────────────┐  ┌───────────────┐  │ │
│  │  │   AI Catalog    │  │   Artifactory    │  │     Xray      │  │ │
│  │  │                 │  │                  │  │               │  │ │
│  │  │ • Model cards   │  │ • HF remote repo │  │ • Pickle scan │  │ │
│  │  │ • Shadow AI     │  │ • Local model    │  │ • ONNX scan   │  │ │
│  │  │ • Curation      │  │   store          │  │ • CVE scan    │  │ │
│  │  │   policies      │  │ • Virtual repo   │  │ • License     │  │ │
│  │  │ • Evidence      │  │   (unified URL)  │  │   compliance  │  │ │
│  │  │   trail         │  │                  │  │               │  │ │
│  │  └─────────────────┘  └──────────────────┘  └───────────────┘  │ │
│  │                                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────┐   │ │
│  │  │                    AI Gateway                           │   │ │
│  │  │  • Routes external AI API calls (OpenAI, Anthropic)    │   │ │
│  │  │  • Shadow AI detection                                 │   │ │
│  │  │  • Usage metering and policy enforcement               │   │ │
│  │  └─────────────────────────────────────────────────────────┘   │ │
│  └───────────────────────────┬─────────────────────────────────────┘ │
│                              │ HTTPS proxy/cache                     │
│  ┌───────────────────────────▼─────────────────────────────────────┐ │
│  │                   Hugging Face Hub                              │ │
│  │              (public AI model registry)                         │ │
│  │         Models: facebook/bart-large-cnn, etc.                  │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Model Governance Flow

```
Developer / AI Agent asks for a model
         │
         ▼
   JFrog MCP Server
   (jfrog_get_package_info)
         │
         ▼
   Artifactory virtual repo
   (aggregates local + HF remote)
         │
    ┌────┴────┐
    │         │
    ▼         ▼
 Model      Model
 cached     not cached
 locally       │
    │          ▼
    │    Fetch from Hugging Face Hub
    │          │
    │          ▼
    │    Xray scans automatically
    │          │
    │    ┌─────┴──────┐
    │    │            │
    │    ▼            ▼
    │  CLEAN       MALICIOUS
    │    │            │
    │    ▼            ▼
    │  Curation    Curation
    │  APPROVED    BLOCKED
    │    │            │
    │    ▼            ▼
    │  Served to   Request
    │  developer   rejected
    │    │         + alert
    │    ▼
  Model card in
  AI Catalog with
  full evidence trail
```

---

## MCP Interaction Diagram

```
Presenter prompt (natural language)
         │
         ▼
  Claude / Cursor
  (LLM reasoning)
         │
         │ Selects tools based on intent
         ▼
  ┌─────────────────────────────────────┐
  │         JFrog MCP Server            │
  │                                     │
  │  Tool: jfrog_get_package_info       │──► Artifactory Package API
  │  Tool: jfrog_get_package_           │
  │         curation_status             │──► Curation Service API
  │  Tool: jfrog_get_package_version_   │
  │         vulnerabilities             │──► Xray REST API
  │  Tool: create_project               │──► Access Control API
  │  Tool: create_local_repository      │──► Artifactory Admin API
  │  Tool: create_remote_repository     │──► Artifactory Admin API
  │  Tool: create_virtual_repository    │──► Artifactory Admin API
  └─────────────────────────────────────┘
         │
         ▼
  Structured JSON results
         │
         ▼
  Claude synthesizes into
  natural language response
  with governance summary
```

---

## Component Roles

| Component | Role in Demo | How It's Accessed |
|-----------|-------------|-------------------|
| Claude Desktop / Cursor | AI assistant; primary demo interface | Direct UI |
| JFrog MCP Server | Bridge: turns JFrog into AI-native tools | MCP protocol |
| JFrog AI Catalog | Governance UI; shows evidence and policies | Browser |
| Artifactory | Model registry; stores and proxies HF models | JFrog CLI + MCP |
| Xray | Security engine; scans models for threats | Automatic + UI |
| AI Gateway | Controls external AI API consumption | AI Catalog UI |
| Hugging Face Hub | Source of ML models | Proxied through Artifactory |

---

## Key Design Decisions

### Why a virtual repository?
Developers always pull from the virtual URL (`jfrog-ai-demo-virtual`). Behind the scenes, Artifactory routes to local (approved models) or fetches from the HuggingFace remote proxy. The developer never needs to know where the model lives — they always get the governed version.

### Why pre-seed the blocked model?
Live Xray scans can take 30–60 seconds. Pre-seeding ensures the blocked model evidence is available instantly during the demo without waiting for scan completion. The `reset.sh` script restores this state.

### Why use MCP for repo setup (Act 3)?
It demonstrates that JFrog AI Catalog is itself AI-native — not just managing AI assets but being controlled by AI tooling. The MCP Server is the natural language interface to the entire JFrog platform.

### What's the Shadow AI detection source?
Shadow AI detection learns from network-level telemetry (when AI Gateway is deployed) or from code scanning. For the demo, entries are manually seeded via `scripts/setup.sh` to ensure they're visible on any tenant configuration.

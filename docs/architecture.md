# Architecture Overview

## The Project-Based Governance Model

The central design principle of JFrog AI Catalog is: **a Project is the governance boundary for all AI consumption.** Every significant action — allowing a model, connecting a provider, registering an MCP server, issuing developer access — is scoped to a JFrog Project.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    JFrog Project: ml-code-review                        │
│                                                                         │
│  ┌─────────────────────────┐    ┌────────────────────────────────────┐  │
│  │   Allowed Models        │    │   Provider Connections             │  │
│  │                         │    │                                    │  │
│  │  ✅ facebook/bart-large  │    │  ml-openai-connection              │  │
│  │  ✅ openai/gpt-4o        │    │  └─ Project: ml-code-review        │  │
│  │  🚫 ms/codebert-base     │    │  └─ Provider: OpenAI              │  │
│  │     (blocked — pickle)   │    │  └─ Secret: openai-api-key        │  │
│  └─────────────────────────┘    │                                    │  │
│                                 │  ml-huggingface-connection         │  │
│  ┌─────────────────────────┐    │  └─ Project: ml-code-review        │  │
│  │   MCP Registry          │    │  └─ Provider: HuggingFace         │  │
│  │                         │    └────────────────────────────────────┘  │
│  │  📦 github-mcp           │                                           │
│  │  └─ Allow: ^get_.*       │    ┌────────────────────────────────────┐  │
│  │  └─ Allow: ^list_.*      │    │   Developer Access                 │  │
│  │  └─ Deny:  .*delete.*    │    │                                    │  │
│  │                         │    │  🎫 Project-scoped JFrog token     │  │
│  │  📦 jfrog-mcp            │    │  🌐 https://<org>.ml.jfrog.io/v1  │  │
│  │  └─ Allow: all reads     │    │     (AI Gateway endpoint)         │  │
│  └─────────────────────────┘    └────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
         │                              │
         ▼                              ▼
  Developer calls AI Gateway     Developer runs MCP Gateway
  with JFrog project token       jf mcp-gateway run
  → JFrog proxies to provider    PROJECT_KEY=ml-code-review
  → Usage logged, metered        → Tool policies enforced
```

---

## System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Admin Surfaces                               │
│                                                                      │
│  ┌───────────────────┐  ┌────────────────┐  ┌────────────────────┐  │
│  │  AI/ML Discovery  │  │  Connections   │  │  MCP Registry      │  │
│  │  (staging area)   │  │  (per project) │  │  Admin             │  │
│  │  Browse, evaluate │  │  Provider +    │  │  Add, configure    │  │
│  │  Allow or block   │  │  Project pair  │  │  tool policies     │  │
│  └────────┬──────────┘  └───────┬────────┘  └─────────┬──────────┘  │
│           │                     │                      │             │
└───────────┼─────────────────────┼──────────────────────┼────────────┘
            │ Allow to project    │ Bind credential       │ Register in
            │                     │                       │ project
            ▼                     ▼                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    JFrog Platform (SaaS)                             │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                  JFrog Projects                              │   │
│  │                                                              │   │
│  │  Project: ml-code-review          Project: data-science      │   │
│  │  ├─ Allowed Models: bart, gpt-4o  ├─ Allowed Models: llama   │   │
│  │  ├─ Connections: OpenAI, HF       ├─ Connections: AWS        │   │
│  │  └─ MCP Registry: github, jfrog   └─ MCP Registry: s3-mcp    │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌────────────────┐  ┌──────────────────┐  ┌────────────────────┐   │
│  │   AI Gateway   │  │   Artifactory    │  │      Xray          │   │
│  │                │  │                  │  │                    │   │
│  │ ml.jfrog.io/v1 │  │ • HF remote repo │  │ • Model scanning   │   │
│  │ Proxies all    │  │ • Local store    │  │ • Pickle/ONNX/CVE  │   │
│  │ LLM API calls  │  │ • Virtual repo   │  │ • License check    │   │
│  │ Uses stored    │  │   (governed URL) │  │ • Evidence trail   │   │
│  │ Connection creds│  │                  │  │                    │   │
│  └────────┬───────┘  └──────────────────┘  └────────────────────┘   │
│           │                                                          │
└───────────┼──────────────────────────────────────────────────────────┘
            │ Proxied API calls
            ▼
┌──────────────────────────────────────────────────────────────────────┐
│               External AI Providers                                  │
│                                                                      │
│   OpenAI   Anthropic   AWS Bedrock   NVIDIA NIM   HuggingFace        │
│                                                                      │
│   (Credentials stored in JFrog; developers never hold raw keys)      │
└──────────────────────────────────────────────────────────────────────┘

         ▲                              ▲
         │                              │
┌────────┴───────────────────┐  ┌───────┴──────────────────────────────┐
│    Developer (LLM usage)   │  │    Developer (MCP tools)             │
│                            │  │                                      │
│  from openai import OpenAI │  │  export PROJECT_KEY=ml-code-review   │
│  client = OpenAI(          │  │  jf mcp-gateway run                  │
│    api_key="<jfrog-token>",│  │                                      │
│    base_url="ml.jfrog.io/v1│  │  Claude Code calls tools via         │
│  )                         │  │  MCP Gateway — policies enforced     │
└────────────────────────────┘  └──────────────────────────────────────┘
```

---

## Key Design Decisions

### Why the Provider-Project Pair is the Atomic Unit

From JFrog documentation: *"Each model provider-project pair requires a unique connection."* This is not just organizational labeling — it is the enforcement mechanism. A developer in project A cannot use a connection created for project B. Token generation, usage metering, and policy enforcement all derive from this binding.

### Why Developers Never Hold Raw API Keys

The JFrog AI Gateway acts as a proxy. Developers call `https://<org>.ml.jfrog.io/v1` with a JFrog-issued project-scoped token. JFrog resolves the stored Connection credential and proxies the request to the actual provider. This means:
- API key rotation happens in one place (the Connection/Secret), not across all developer environments
- Developer access is revoked by invalidating the JFrog token or removing the project allowance
- All usage is logged through the gateway, regardless of which provider is called

### Why the MCP Gateway Uses PROJECT_KEY

The JFrog MCP Gateway (`jf mcp-gateway run`) is the equivalent of the AI Gateway for MCP tools. The `PROJECT_KEY` environment variable determines which project's MCP Registry is exposed to the AI coding assistant. Only MCP servers added to that project's Registry are available; only tool calls matching the Allow list (and not the Deny list) are executed. The AI assistant cannot discover or call any MCP tool outside what the project's policy permits.

### The Discovery → Registry Flow

```
Discovery (Staging Area)          Registry (Developer View)
─────────────────────             ─────────────────────────
All known AI assets     →Allow→   Assets approved for a
• Unallowed models      (per      specific project
• Shadow AI             project)
• MCP servers
• API providers

Admin evaluates here              Developer consumes here
```

---

## Component Roles

| Component | Role | Primary User |
|-----------|------|-------------|
| AI/ML Discovery | Browse + evaluate all AI assets before approval | Admin |
| Connections | Store `(provider, project)` credential bindings | Admin |
| AI/ML Registry | Approved assets per project — the developer catalog | Developer |
| AI Gateway | Proxy for all LLM API calls; uses stored Connection creds | Developer (transparent) |
| MCP Registry | Per-project MCP server catalog with tool policies | Admin + Developer |
| MCP Gateway (`jf mcp-gateway run`) | Enforces per-project MCP tool policies at runtime | Developer |
| JFrog Xray | Security scanning engine — scans on ingest | Platform (automatic) |
| Curation Policies | Pre-ingest blocking rules — block before caching | Admin |
| Shadow AI Detection | Surfaces unmanaged AI API calls enterprise-wide | Admin visibility |

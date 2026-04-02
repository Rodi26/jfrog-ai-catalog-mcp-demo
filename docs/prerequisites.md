# Prerequisites

Everything you need before running this demo.

---

## JFrog Platform

### Required: JFrog SaaS instance

The JFrog MCP Server is currently available in **open beta for JFrog SaaS only**.
Self-hosted Artifactory does not yet support the official remote MCP endpoint.

| Requirement | Details |
|-------------|---------|
| Instance type | JFrog SaaS (Cloud) |
| Minimum tier | Enterprise X (for AI Catalog + Xray) |
| AI Catalog | Must be enabled (contact your JFrog rep or enable in trial) |
| Xray | Must be enabled with an active license |
| AI Gateway | Recommended for Shadow AI detection demo |

**Get a free trial:** https://jfrog.com/start-free/
- Select "JFrog Cloud" (SaaS)
- Request the Enterprise X trial for full AI Catalog access

### Required: JFrog Access Token

You need an **Admin-scoped access token** to:
- Create repositories
- Apply curation and Xray policies
- Configure the demo environment

Generate at: `https://yourcompany.jfrog.io/ui/admin/artifactory/user_management/access_tokens`

---

## CLI Tools

### JFrog CLI (`jf`)

Required for environment setup scripts.

```bash
# macOS (Homebrew)
brew install jfrog-cli

# Linux / macOS (direct)
curl -fL https://install-cli.jfrog.io | sh

# Verify
jf --version
# Expected: jf version 2.x.x
```

Authenticate after install:
```bash
jf config add jfrog-demo \
  --url https://yourcompany.jfrog.io \
  --access-token "$JFROG_ACCESS_TOKEN" \
  --interactive=false
```

### Git

```bash
git --version
# Expected: git version 2.x.x
```

### Python 3.10+

Required for test scripts.

```bash
python3 --version
# Expected: Python 3.10.x or higher
```

---

## AI Coding Assistant with MCP Support

You need **one** of the following:

### Option A: Claude Desktop (Recommended)

- Version: 0.10.0 or later (MCP support required)
- Download: https://claude.ai/download
- Platform: macOS or Windows
- MCP config location:
  - macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
  - Windows: `%APPDATA%\Claude\claude_desktop_config.json`

### Option B: Cursor

- Version: 0.44+ (MCP support)
- Download: https://cursor.com
- MCP config: `.cursor/mcp.json` in workspace or global settings

### Option C: VS Code with GitHub Copilot

- VS Code version: 1.90+
- GitHub Copilot extension: latest
- MCP config: `.vscode/mcp.json` in workspace

---

## Network Requirements

| Endpoint | Purpose | Required |
|----------|---------|----------|
| `https://yourcompany.jfrog.io` | JFrog platform API + MCP server | Yes |
| `https://huggingface.co` | Model source (proxied through Artifactory) | Setup only |
| `https://claude.ai` | Claude Desktop authentication | Yes (Option A) |

The demo runs against your JFrog SaaS instance. Network access from the presenter's machine to the JFrog URL is required for live MCP calls.

**Offline fallback:** If network is unavailable, use `demo-assets/expected-outputs/mcp-session-transcript.md`.

---

## Version Summary

| Tool | Minimum Version | Recommended |
|------|----------------|-------------|
| JFrog CLI | 2.50.0 | Latest |
| Claude Desktop | 0.10.0 | Latest |
| Cursor | 0.44.0 | Latest |
| Git | 2.30.0 | Latest |
| Python | 3.10 | 3.12+ |
| Node.js | 18.0 (optional) | 20 LTS |

---

## Checklist

Before running `./scripts/setup.sh`:

- [ ] JFrog SaaS instance provisioned with AI Catalog + Xray enabled
- [ ] Admin access token generated and available
- [ ] JFrog CLI installed and authenticated (`jf config show`)
- [ ] Claude Desktop (or Cursor) installed and running
- [ ] Network access to JFrog instance verified
- [ ] `JFROG_URL` and `JFROG_ACCESS_TOKEN` environment variables set

# Full Setup Guide

Complete environment setup for the JFrog AI Catalog MCP Demo.

---

## Overview

The setup process creates:
1. A HuggingFace remote repository in Artifactory (proxies Hugging Face Hub)
2. A local model repository (stores approved models)
3. A virtual repository (unified, governed access URL)
4. A curation policy (blocks malicious models automatically)
5. An Xray security policy (scans all AI assets)
6. Demo model references (pre-seeded for the blocked model scenario)
7. MCP client configuration (Claude Desktop / Cursor / VS Code)

---

## Step 1 — JFrog SaaS Setup

### 1.1 Provision a JFrog SaaS Instance

If you don't have one:
1. Go to https://jfrog.com/start-free/
2. Select "JFrog Cloud" (SaaS, not self-hosted)
3. Choose a region close to your demo location
4. Select Enterprise X trial (required for AI Catalog + Xray)
5. Complete registration — your URL will be `https://yourname.jfrog.io`

### 1.2 Enable AI Catalog and Xray

If AI Catalog is not already enabled on your instance:
1. Log into the JFrog Platform UI as admin
2. Navigate to Platform → Administration → AI Catalog
3. Enable AI Catalog
4. Navigate to Administration → Xray → Indexing
5. Ensure Xray indexing is enabled for the `Machine Learning` package type

### 1.3 Generate an Admin Access Token

1. Navigate to Administration → User Management → Access Tokens
2. Click "Generate Token"
3. Scope: Admin
4. Expiry: Set to longer than your demo period (or no expiry for a dedicated demo tenant)
5. Copy the token — you won't see it again

---

## Step 2 — Local Environment Setup

### 2.1 Clone the Repository

```bash
git clone https://github.com/your-org/jfrog-ai-catalog-mcp-demo.git
cd jfrog-ai-catalog-mcp-demo
```

### 2.2 Set Environment Variables

```bash
export JFROG_URL="https://yourcompany.jfrog.io"
export JFROG_ACCESS_TOKEN="your-admin-access-token"
export JFROG_USER="your-username"
```

Add these to your shell profile (`~/.zshrc` or `~/.bashrc`) for persistence.

### 2.3 Install JFrog CLI

```bash
# macOS
brew install jfrog-cli

# Linux / macOS (direct download)
curl -fL https://install-cli.jfrog.io | sh

# Verify
jf --version
```

### 2.4 Authenticate JFrog CLI

```bash
jf config add jfrog-demo \
  --url "$JFROG_URL" \
  --access-token "$JFROG_ACCESS_TOKEN" \
  --interactive=false

# Verify
jf config show
```

---

## Step 3 — Run Setup Script

```bash
./scripts/setup.sh
```

This is the one-command setup. It creates all repositories, applies policies, and seeds demo data.

**What it does (step by step):**

```bash
# Creates the HuggingFace remote repository
# Proxies public Hugging Face Hub, caches models locally in JFrog
jf rt repo-create RT --serverId=jfrog-demo \
  config/artifactory/create-repos.sh

# Applies the curation policy from config/artifactory/curation-policy.json
# Blocks models with critical severity or known malicious payloads

# Applies the Xray security policy from config/xray/security-policy.json
# Scans all Machine Learning package type artifacts

# Seeds the demo model references
# Pre-populates the blocked model scenario for Act 2
```

---

## Step 4 — Configure MCP Client

### Claude Desktop

#### macOS

```bash
# Back up existing config (if any)
cp ~/Library/Application\ Support/Claude/claude_desktop_config.json \
   ~/Library/Application\ Support/Claude/claude_desktop_config.json.bak 2>/dev/null

# Copy demo config
cp config/mcp/claude-desktop-config.json \
   ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

Edit the config to replace `YOUR_JFROG_URL`:
```bash
# Replace with your actual URL
sed -i '' "s|YOUR_JFROG_URL|$JFROG_URL|g" \
  ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

#### Windows

```powershell
$configPath = "$env:APPDATA\Claude\claude_desktop_config.json"
Copy-Item "config\mcp\claude-desktop-config.json" $configPath
(Get-Content $configPath) -replace 'YOUR_JFROG_URL', $env:JFROG_URL | Set-Content $configPath
```

**Restart Claude Desktop** after updating the config.

---

### Cursor

```bash
# Copy to workspace MCP config
mkdir -p .cursor
cp config/mcp/cursor-config.json .cursor/mcp.json

# Replace URL
sed -i '' "s|YOUR_JFROG_URL|$JFROG_URL|g" .cursor/mcp.json
```

Open Cursor → Settings → MCP → verify the JFrog server appears.

---

### VS Code with GitHub Copilot

```bash
# Copy to workspace
mkdir -p .vscode
cp config/mcp/vscode-config.json .vscode/mcp.json

# Replace URL
sed -i '' "s|YOUR_JFROG_URL|$JFROG_URL|g" .vscode/mcp.json
```

Reload VS Code. The JFrog MCP tools should appear in Copilot.

---

## Step 5 — Authorize MCP Connection

The JFrog MCP Server uses OAuth 2.0. On first use:

1. Open Claude Desktop (or Cursor)
2. Send any prompt that calls a JFrog tool, e.g.: `List my Artifactory repositories`
3. A browser window will open asking you to authorize the JFrog MCP Server
4. Log in with your JFrog credentials and approve
5. Return to your AI assistant — the tool call will complete

The OAuth token is cached for subsequent uses.

---

## Step 6 — Validate

```bash
./scripts/validate.sh
```

Expected output:
```
============================================
  JFrog AI Catalog MCP Demo - Pre-flight Validation
============================================

[✓] JFrog CLI authenticated (jfrog-demo)
[✓] Remote repository exists: jfrog-ai-demo-huggingface-remote
[✓] Local repository exists: jfrog-ai-demo-models-local
[✓] Virtual repository exists: jfrog-ai-demo-virtual
[✓] Curation policy active: block-malicious-ai-models
[✓] Xray security policy active: ai-catalog-security-policy
[✓] MCP config found: ~/Library/Application Support/Claude/claude_desktop_config.json
[✓] Demo model seeds present

============================================
  All checks passed. Demo environment ready!
============================================
```

---

## Step 7 — Test MCP Connection

Open Claude Desktop and send:
```
List the repositories in my JFrog instance that have the Machine Learning package type.
```

You should see the JFrog MCP tools called and a list including `jfrog-ai-demo-huggingface-remote`, `jfrog-ai-demo-models-local`, and `jfrog-ai-demo-virtual`.

---

## Resetting Between Demo Runs

```bash
./scripts/reset.sh
```

This deletes and recreates the demo repositories and policies, restoring state to pre-demo clean condition. Use between demo runs to ensure the blocked model and shadow AI scenarios are correctly seeded.

---

## Troubleshooting Setup

See [`docs/troubleshooting.md`](troubleshooting.md) for detailed troubleshooting steps.

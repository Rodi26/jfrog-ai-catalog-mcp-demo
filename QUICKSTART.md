# Quickstart — 15-Minute Setup

Get from zero to demo-ready in 15 minutes.

---

## Prerequisites

Before you start, make sure you have:

- [ ] A JFrog SaaS account with **AI Catalog + Xray** enabled
  - Free 14-day trial at https://jfrog.com/start-free/
  - Requires the **Enterprise X** tier or above for full AI Catalog features
- [ ] **JFrog CLI** (`jf`) installed — https://jfrog.com/getcli/
- [ ] **Claude Desktop** (preferred) or **Cursor** with MCP support
- [ ] **Git** and **Python 3.10+**
- [ ] Your JFrog platform URL (e.g. `https://yourcompany.jfrog.io`)
- [ ] A JFrog access token with Admin scope

See [`docs/prerequisites.md`](docs/prerequisites.md) for detailed version requirements.

---

## Step 1 — Clone the Repository (1 min)

```bash
git clone https://github.com/your-org/jfrog-ai-catalog-mcp-demo.git
cd jfrog-ai-catalog-mcp-demo
```

---

## Step 2 — Configure Environment Variables (2 min)

```bash
export JFROG_URL="https://yourcompany.jfrog.io"
export JFROG_ACCESS_TOKEN="your-access-token"
export JFROG_USER="your-username"
```

Or create a `.env` file:

```bash
cat > .env << 'EOF'
JFROG_URL=https://yourcompany.jfrog.io
JFROG_ACCESS_TOKEN=your-access-token
JFROG_USER=your-username
EOF
```

---

## Step 3 — Run Setup (5 min)

```bash
./scripts/setup.sh
```

This script will:
1. Verify JFrog CLI is installed and authenticated
2. Create demo repositories in Artifactory (HuggingFace remote + virtual)
3. Apply the demo curation policy
4. Apply the Xray security policy
5. Seed the demo with known model references

Expected output:
```
✓ JFrog CLI authenticated
✓ Creating HuggingFace remote repository: jfrog-ai-demo-huggingface-remote
✓ Creating local model repository: jfrog-ai-demo-models-local
✓ Creating virtual repository: jfrog-ai-demo-virtual
✓ Curation policy applied
✓ Xray security policy applied
✓ Demo environment ready
```

---

## Step 4 — Configure MCP Client (5 min)

### Claude Desktop

Copy the MCP configuration to Claude Desktop:

```bash
# macOS
cp config/mcp/claude-desktop-config.json \
   ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

Then edit the file and replace `YOUR_JFROG_URL` with your actual platform URL.

Restart Claude Desktop. You should see JFrog tools available in Claude.

### Cursor

Copy `config/mcp/cursor-config.json` to your Cursor MCP settings directory. See [`docs/setup-guide.md`](docs/setup-guide.md) for Cursor-specific instructions.

### VS Code Copilot

Copy `config/mcp/vscode-config.json` to `.vscode/mcp.json` in your workspace directory.

---

## Step 5 — Validate (2 min)

```bash
./scripts/validate.sh
```

All checks should pass:
```
✓ JFrog CLI authenticated
✓ Remote HuggingFace repo exists
✓ Local model repo exists
✓ Virtual repo exists
✓ Curation policy active
✓ Xray policy active
✓ MCP config file found for Claude Desktop
✓ Demo environment ready — good to go!
```

---

## Step 6 — Test MCP Connection

Open Claude Desktop (or Cursor) and send this prompt:

```
List the repositories available in my JFrog Artifactory instance.
```

You should see JFrog MCP tools being called and a list of repositories returned.

---

## You're Ready

Open [`DEMO.md`](DEMO.md) for the full presenter guide.

---

## Troubleshooting

See [`docs/troubleshooting.md`](docs/troubleshooting.md) for common issues.

**Quick fixes:**

| Problem | Fix |
|---------|-----|
| `jf` command not found | Install JFrog CLI from https://jfrog.com/getcli/ |
| Setup script fails on repo creation | Check your access token has Admin scope |
| MCP tools not showing in Claude | Restart Claude Desktop after updating config |
| Validation fails on policy check | Wait 30 seconds and re-run — policy propagation takes a moment |

# Troubleshooting

Common issues, fallback steps, and offline mode instructions.

---

## Quick Diagnosis

Run the validation script first:
```bash
./scripts/validate.sh
```

It checks all critical dependencies. Fix anything it reports red before investigating further.

---

## MCP Issues

### MCP tools not appearing in Claude Desktop

**Symptoms:** No JFrog tools visible in Claude; prompts don't trigger tool calls.

**Fix:**
1. Verify the config file exists:
   ```bash
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```
2. Check the JSON is valid (no trailing commas, correct braces):
   ```bash
   python3 -m json.tool ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```
3. Restart Claude Desktop completely (quit from menu bar, not just close window)
4. Verify `YOUR_JFROG_URL` is replaced with your actual platform URL
5. Check Claude Desktop version is 0.10.0+

### MCP calls failing with 401 Unauthorized

**Symptoms:** Tool calls appear but return auth errors.

**Fix:**
1. Re-authenticate the JFrog MCP Server in Claude Desktop
2. The remote MCP Server uses OAuth — a browser window should appear on first use
3. Ensure your JFrog account has the required permissions (read + admin for repo creation)
4. Check your access token hasn't expired

### MCP calls timing out

**Symptoms:** Tool calls start but take >30 seconds and timeout.

**Likely cause:** Network connectivity to JFrog SaaS.

**Fix:**
1. Test direct connectivity: `curl -I https://yourcompany.jfrog.io/artifactory/api/system/ping`
2. If on VPN, try disconnecting (some VPNs block outbound MCP traffic)
3. Fallback: use the offline transcript in `demo-assets/expected-outputs/mcp-session-transcript.md`

### `jfrog_get_package_info` returns empty results

**Symptoms:** Tool call succeeds but returns no models.

**Fix:**
1. Verify the HuggingFace remote repository exists:
   ```bash
   jf rt repo-list --type=remote | grep hugging
   ```
2. Re-run setup to create the remote repo:
   ```bash
   ./scripts/setup.sh
   ```
3. Check that models were seeded:
   ```bash
   jf rt search "jfrog-ai-demo-virtual/**"
   ```

---

## Setup Script Issues

### `setup.sh` fails: "jf: command not found"

Install JFrog CLI:
```bash
# macOS
brew install jfrog-cli

# Linux
curl -fL https://install-cli.jfrog.io | sh
```

### `setup.sh` fails: "403 Forbidden" on repo creation

Your access token doesn't have admin scope. Generate a new one:
1. Go to `https://yourcompany.jfrog.io/ui/admin/artifactory/user_management/access_tokens`
2. Create a token with "Admin" scope
3. Update `JFROG_ACCESS_TOKEN` in your environment

### `setup.sh` fails: "Repository already exists"

This is expected if you've run setup before. The script is idempotent — existing repos are skipped. Check the actual error message; only "already exists" errors are safe to ignore.

### Curation policy not applying

Curation policy application may take up to 60 seconds to propagate. Re-run `./scripts/validate.sh` after 60 seconds.

If still failing, apply manually:
1. Navigate to AI Catalog → Policies in the JFrog UI
2. Create a policy matching `config/artifactory/curation-policy.json`

---

## Demo State Issues

### Blocked model not showing in AI Catalog

The blocked model state needs to be pre-seeded. Run:
```bash
./scripts/reset.sh
```

This restores the demo state, including the seeded blocked model entry.

### Shadow AI panel is empty

**Option 1:** Shadow AI detection requires specific license tier. Confirm with your JFrog tenant admin.

**Option 2:** Use screenshots as fallback:
- `demo-assets/screenshots/shadow-ai-panel.png` (if available)
- Skip Act 4 and describe it verbally with the talking points from `docs/talking-points.md`

### Previously created demo repos are visible / polluted

Run reset to clean up:
```bash
./scripts/reset.sh

# Then re-run setup
./scripts/setup.sh
```

---

## Offline Fallback

If network or platform issues prevent live MCP calls, use the offline fallback:

1. **Open the offline transcript:**
   ```bash
   open demo-assets/expected-outputs/mcp-session-transcript.md
   ```
2. **Narrate the transcript** as if Claude were responding live
3. **Use screenshots** from `demo-assets/screenshots/` for the UI portions
4. **Key message:** "What you're seeing here is a recorded session — I'll show you live once we have network access, or we can schedule a follow-up."

The offline fallback covers all 4 acts. Screenshots are annotated with talking points.

---

## Environment Reset

Full reset procedure (start fresh):
```bash
# 1. Clean up all demo artifacts
./scripts/reset.sh

# 2. Re-validate from scratch
./scripts/validate.sh

# 3. If validation fails, re-run full setup
./scripts/setup.sh

# 4. Validate again
./scripts/validate.sh
```

---

## Getting Help

- JFrog Support: https://support.jfrog.com
- JFrog MCP Server issues: https://github.com/jfrog/jfrog-mcp-server/issues
- JFrog AI Catalog docs: https://jfrog.com/help/r/jfrog-platform-administration-documentation/jfrog-ai-catalog
- Claude Desktop MCP docs: https://modelcontextprotocol.io/docs/tools/claude-desktop

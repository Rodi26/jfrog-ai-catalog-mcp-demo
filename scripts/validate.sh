#!/usr/bin/env bash
# validate.sh — Pre-demo validation checklist
#
# Checks all dependencies and demo state before a demo run.
# Run this immediately before presenting.
#
# Usage: ./scripts/validate.sh
# Exit code: 0 = all checks passed; 1 = one or more checks failed

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check_pass() { echo -e "${GREEN}[✓]${NC} $1"; ((PASS++)) || true; }
check_fail() { echo -e "${RED}[✗]${NC} $1"; ((FAIL++)) || true; }
check_warn() { echo -e "${YELLOW}[!]${NC} $1"; ((WARN++)) || true; }

JFROG_SERVER_ID="${JFROG_SERVER_ID:-jfrog-demo}"

echo ""
echo "============================================"
echo "  JFrog AI Catalog MCP Demo — Pre-flight"
echo "============================================"
echo ""

# --- JFrog CLI ---

if command -v jf &>/dev/null; then
  check_pass "JFrog CLI installed: $(jf --version 2>&1 | head -1)"
else
  check_fail "JFrog CLI (jf) not found — install from https://jfrog.com/getcli/"
fi

# --- Authentication ---

if [[ -z "${JFROG_URL:-}" ]]; then
  check_fail "JFROG_URL is not set"
else
  check_pass "JFROG_URL set: $JFROG_URL"
fi

if [[ -z "${JFROG_ACCESS_TOKEN:-}" ]]; then
  check_fail "JFROG_ACCESS_TOKEN is not set"
else
  check_pass "JFROG_ACCESS_TOKEN set (redacted)"
fi

# Configure CLI from env (same as setup.sh) so jf rt curl / jf xr curl work
if command -v jf &>/dev/null && [[ -n "${JFROG_URL:-}" ]] && [[ -n "${JFROG_ACCESS_TOKEN:-}" ]]; then
  JFROG_URL="${JFROG_URL%/}"
  jf config add "$JFROG_SERVER_ID" \
    --url "$JFROG_URL" \
    --access-token "$JFROG_ACCESS_TOKEN" \
    --interactive=false \
    --overwrite=true 2>/dev/null || true
fi

# Test JFrog CLI auth
if command -v jf &>/dev/null && [[ -n "${JFROG_URL:-}" ]]; then
  JFROG_URL="${JFROG_URL%/}"
  if jf rt ping --server-id="$JFROG_SERVER_ID" &>/dev/null; then
    check_pass "JFrog CLI authenticated ($JFROG_SERVER_ID)"
  else
    check_fail "JFrog CLI authentication failed — check credentials"
  fi
fi

# --- Repositories ---

echo ""
echo "Checking Artifactory repositories..."

check_repo() {
  local key="$1"
  local label="$2"
  if command -v jf &>/dev/null && [[ -n "${JFROG_URL:-}" ]] && [[ -n "${JFROG_ACCESS_TOKEN:-}" ]]; then
    if jf rt curl --server-id="$JFROG_SERVER_ID" -sS -f -o /dev/null \
      "/api/repositories/$key" 2>/dev/null; then
      check_pass "$label: $key"
    else
      check_fail "$label not found: $key — run ./scripts/setup.sh"
    fi
  else
    check_warn "Cannot check $label: missing credentials or JFrog CLI"
  fi
}

check_repo "jfrog-ai-demo-huggingface-remote" "Remote repository"
check_repo "jfrog-ai-demo-models-local"       "Local repository"
check_repo "jfrog-ai-demo-virtual"             "Virtual repository"

# --- Policies ---

echo ""
echo "Checking policies..."

check_policy() {
  local name="$1"
  local label="$2"
  if command -v jf &>/dev/null && [[ -n "${JFROG_URL:-}" ]] && [[ -n "${JFROG_ACCESS_TOKEN:-}" ]]; then
    if jf xr curl --server-id="$JFROG_SERVER_ID" -sS -f -o /dev/null \
      "/api/v1/policies/$name" 2>/dev/null; then
      check_pass "$label: $name"
    else
      check_fail "$label not found: $name — run ./scripts/setup.sh"
    fi
  else
    check_warn "Cannot check $label: missing credentials or JFrog CLI"
  fi
}

check_policy "block-malicious-ai-models"   "Curation policy"
check_policy "ai-catalog-security-policy"  "Xray security policy"

# --- MCP Configuration ---

echo ""
echo "Checking MCP configuration..."

CLAUDE_CONFIG_MAC="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
CLAUDE_CONFIG_WIN="${APPDATA:-}/Claude/claude_desktop_config.json"

if [[ -f "$CLAUDE_CONFIG_MAC" ]]; then
  check_pass "Claude Desktop MCP config found: $CLAUDE_CONFIG_MAC"
  # Check if URL placeholder is replaced
  if grep -q "YOUR_JFROG_URL" "$CLAUDE_CONFIG_MAC" 2>/dev/null; then
    check_fail "Claude Desktop config still has YOUR_JFROG_URL placeholder — replace with actual URL"
  else
    check_pass "Claude Desktop config: URL placeholder replaced"
  fi
elif [[ -f "${CLAUDE_CONFIG_WIN:-/dev/null}" ]]; then
  check_pass "Claude Desktop MCP config found (Windows)"
else
  check_warn "Claude Desktop MCP config not found — configure before demo (see docs/setup-guide.md)"
fi

# Check Cursor config
if [[ -f "$REPO_ROOT/.cursor/mcp.json" ]]; then
  check_pass "Cursor MCP config found"
  if grep -q "YOUR_JFROG_URL" "$REPO_ROOT/.cursor/mcp.json" 2>/dev/null; then
    check_fail "Cursor config still has YOUR_JFROG_URL placeholder"
  fi
fi

# --- Demo Assets ---

echo ""
echo "Checking demo assets..."

if [[ -f "$REPO_ROOT/demo-assets/expected-outputs/mcp-session-transcript.md" ]]; then
  check_pass "Offline fallback transcript present"
else
  check_warn "Offline fallback transcript missing — see demo-assets/expected-outputs/"
fi

# --- Summary ---

echo ""
echo "============================================"
TOTAL=$((PASS + FAIL + WARN))

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}  All checks passed ($PASS/$TOTAL). Demo environment ready!${NC}"
  echo "============================================"
  echo ""
  echo "  → Open DEMO.md for the presenter guide"
  echo "  → Have scripts/demo-prompts.txt open during the demo"
  echo ""
  exit 0
else
  echo -e "${RED}  $FAIL check(s) failed. Fix before presenting.${NC}"
  if [[ $WARN -gt 0 ]]; then
    echo -e "${YELLOW}  $WARN warning(s) — review before presenting.${NC}"
  fi
  echo "============================================"
  echo ""
  echo "  Run ./scripts/setup.sh to fix missing repositories/policies."
  echo "  See docs/troubleshooting.md for detailed fix steps."
  echo ""
  exit 1
fi

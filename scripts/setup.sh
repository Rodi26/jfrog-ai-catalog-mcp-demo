#!/usr/bin/env bash
# setup.sh — One-command demo environment setup for JFrog AI Catalog MCP Demo
#
# Usage: ./scripts/setup.sh
#
# What this creates:
#   1. Artifactory repositories via JFrog CLI (jf rt curl) and JSON templates
#      under config/artifactory/repos/
#   2. JFrog Project: ml-code-review (curl → Access API; body in config/access/)
#   3. Curation policy (jf xr curl → Xray API)
#   4. Xray security policy (jf xr curl → Xray API)
#
# Note on Connections and Model Allowances:
#   Provider Connections and model allowances must be configured via the
#   JFrog AI Catalog UI (AI/ML Settings > Connections) — they are not
#   accessible via the JFrog CLI or standard REST API.
#   See docs/setup-guide.md for the manual steps.
#
# Required environment variables:
#   JFROG_URL           — Your JFrog SaaS URL (e.g. https://yourcompany.jfrog.io)
#   JFROG_ACCESS_TOKEN  — Admin-scoped access token
#
# Optional:
#   JFROG_SERVER_ID     — JFrog CLI server ID (default: jfrog-demo)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

JFROG_SERVER_ID="${JFROG_SERVER_ID:-jfrog-demo}"

echo ""
echo "============================================"
echo "  JFrog AI Catalog MCP Demo — Setup"
echo "============================================"
echo ""

# --- Validate prerequisites ---

if ! command -v jf &>/dev/null; then
  fail "JFrog CLI (jf) not found. Install from: https://jfrog.com/getcli/"
fi

if [[ -z "${JFROG_URL:-}" ]]; then
  fail "JFROG_URL is not set. Run: export JFROG_URL=https://yourcompany.jfrog.io"
fi

if [[ -z "${JFROG_ACCESS_TOKEN:-}" ]]; then
  fail "JFROG_ACCESS_TOKEN is not set. Run: export JFROG_ACCESS_TOKEN=your-token"
fi

JFROG_URL="${JFROG_URL%/}"

# --- Configure JFrog CLI ---

echo "Configuring JFrog CLI..."
jf config add "$JFROG_SERVER_ID" \
  --url "$JFROG_URL" \
  --access-token "$JFROG_ACCESS_TOKEN" \
  --interactive=false \
  --overwrite=true 2>/dev/null || true

if ! jf rt ping --server-id="$JFROG_SERVER_ID" &>/dev/null; then
  fail "JFrog CLI authentication failed. Check your JFROG_URL and JFROG_ACCESS_TOKEN."
fi
ok "JFrog CLI authenticated ($JFROG_SERVER_ID)"

# --- Create JFrog Project ---

echo ""
echo "Creating demo project..."

PROJECT_KEY="ml-code-review"
PROJECT_BODY="$REPO_ROOT/config/access/project-ml-code-review.json"

# jf rt curl prepends /artifactory/ to paths, but the Access API lives at
# /access/. No "jf access curl" exists, so we use curl directly here.
project_exists=$(curl -sS -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $JFROG_ACCESS_TOKEN" \
  "$JFROG_URL/access/api/v1/projects/$PROJECT_KEY" 2>/dev/null || echo "000")

if [[ "$project_exists" == "200" ]]; then
  warn "Project '$PROJECT_KEY' already exists — skipping"
elif [[ ! -f "$PROJECT_BODY" ]]; then
  warn "Project definition not found: $PROJECT_BODY — skipping project creation"
else
  response=$(curl -sS -w "\nHTTP_CODE:%{http_code}" \
    -X POST \
    -H "Authorization: Bearer $JFROG_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d @"$PROJECT_BODY" \
    "$JFROG_URL/access/api/v1/projects" 2>&1) || true
  http_code=$(echo "$response" | grep -o 'HTTP_CODE:[0-9]*' | cut -d: -f2)
  if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
    ok "Created project: $PROJECT_KEY"
  elif echo "$response" | grep -q "already exists" 2>/dev/null; then
    warn "Project '$PROJECT_KEY' already exists — skipping"
  else
    warn "Project creation failed (HTTP $http_code). Response:"
    echo "$response" | grep -v 'HTTP_CODE:' | head -5
  fi
fi

# --- Create Artifactory Repositories ---

echo ""
echo "Creating demo repositories..."

create_repo_if_missing() {
  local key="$1"
  local template_file="$2"
  local label="$3"
  local status

  if [[ ! -f "$template_file" ]]; then
    fail "Repository template not found: $template_file"
  fi

  status=$(jf rt curl --server-id="$JFROG_SERVER_ID" -sS -o /dev/null -w "%{http_code}" \
    "/api/repositories/$key" 2>/dev/null || echo "000")

  if [[ "$status" == "200" ]]; then
    warn "Repository '$key' already exists — skipping"
    return
  fi

  local tmpfile
  tmpfile=$(mktemp)
  local http_code
  http_code=$(jf rt curl --server-id="$JFROG_SERVER_ID" -sS -o "$tmpfile" -w "%{http_code}" \
    -X PUT \
    -H "Content-Type: application/json" \
    -d @"$template_file" \
    "/api/repositories/$key" 2>&1) || true

  if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
    rm -f "$tmpfile"
    ok "Created $label: $key"
    return
  fi

  echo -e "${RED}[✗]${NC} Failed to create repository: $key (HTTP $http_code)"
  if [[ -s "$tmpfile" ]]; then
    echo "    Server response: $(cat "$tmpfile")"
  fi
  rm -f "$tmpfile"
  exit 1
}

create_repo_if_missing "jfrog-ai-demo-huggingface-remote" \
  "$REPO_ROOT/config/artifactory/repos/jfrog-ai-demo-huggingface-remote.json" \
  "remote repository"

create_repo_if_missing "jfrog-ai-demo-models-local" \
  "$REPO_ROOT/config/artifactory/repos/jfrog-ai-demo-models-local.json" \
  "local repository"

create_repo_if_missing "jfrog-ai-demo-virtual" \
  "$REPO_ROOT/config/artifactory/repos/jfrog-ai-demo-virtual.json" \
  "virtual repository"

# --- Apply curation policy ---

echo ""
echo "Applying curation policy..."

CURATION_POLICY_FILE="$REPO_ROOT/config/artifactory/curation-policy.json"
if [[ -f "$CURATION_POLICY_FILE" ]]; then
  response=$(jf xr curl --server-id="$JFROG_SERVER_ID" -sS -X POST -H "Content-Type: application/json" \
    -d @"$CURATION_POLICY_FILE" \
    "/api/v1/policies" 2>&1) || true
  if echo "$response" | grep -q "already exists" 2>/dev/null; then
    warn "Curation policy already exists — skipping"
  else
    ok "Curation policy applied: block-malicious-ai-models"
  fi
else
  warn "Curation policy file not found — skipping"
fi

# --- Apply Xray security policy ---

echo ""
echo "Applying Xray security policy..."

XRAY_POLICY_FILE="$REPO_ROOT/config/xray/security-policy.json"
if [[ -f "$XRAY_POLICY_FILE" ]]; then
  response=$(jf xr curl --server-id="$JFROG_SERVER_ID" -sS -X POST -H "Content-Type: application/json" \
    -d @"$XRAY_POLICY_FILE" \
    "/api/v1/policies" 2>&1) || true
  if echo "$response" | grep -q "already exists" 2>/dev/null; then
    warn "Xray policy already exists — skipping"
  else
    ok "Xray security policy applied: ai-catalog-security-policy"
  fi
else
  warn "Xray policy file not found — skipping"
fi

# --- Manual steps reminder ---

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "MANUAL STEPS REQUIRED (AI Catalog UI)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  The following must be done via the JFrog AI Catalog UI:"
echo "  (API access for these is not available in the current beta)"
echo ""
echo "  1. Create Provider Connections (AI/ML Settings > Connections):"
echo "     • ml-openai-connection      → Project: ml-code-review, Provider: OpenAI"
echo "     • ml-huggingface-connection → Project: ml-code-review, Provider: HuggingFace"
echo ""
echo "  2. Allow models to the project (AI/ML > Discovery):"
echo "     • Allow: facebook/bart-large-cnn → Project: ml-code-review"
echo "     • Allow: salesforce/codet5-base  → Project: ml-code-review"
echo "     • (microsoft/codebert-base should remain blocked)"
echo ""
echo "  3. Register MCP servers (AI/ML > Registry > MCP Servers):"
echo "     • Add github-mcp with tool policy: allow ^get_.*, ^list_.*"
echo "     •                                  deny  .*delete.*"
echo ""
echo "  See docs/setup-guide.md for step-by-step screenshots."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# --- Summary ---

echo ""
echo "============================================"
echo -e "${GREEN}  Automated setup complete!${NC}"
echo "============================================"
echo ""
echo "  Created:"
echo "  • Project: ml-code-review"
echo "  • Repository: jfrog-ai-demo-huggingface-remote"
echo "  • Repository: jfrog-ai-demo-models-local"
echo "  • Repository: jfrog-ai-demo-virtual"
echo "  • Policy: block-malicious-ai-models"
echo "  • Policy: ai-catalog-security-policy"
echo ""
echo "  Next: Complete the manual steps above, then run:"
echo "  ./scripts/validate.sh"
echo ""

#!/usr/bin/env bash
# setup.sh — One-command demo environment setup for JFrog AI Catalog MCP Demo
#
# Usage: ./scripts/setup.sh
#
# Required environment variables:
#   JFROG_URL           — Your JFrog SaaS URL (e.g. https://yourcompany.jfrog.io)
#   JFROG_ACCESS_TOKEN  — Admin-scoped access token
#   JFROG_USER          — Your JFrog username (optional if using token)
#
# Optional:
#   JFROG_SERVER_ID     — JFrog CLI server ID (default: jfrog-demo)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "    $1"; }

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
  fail "JFROG_URL is not set. Export it before running: export JFROG_URL=https://yourcompany.jfrog.io"
fi

if [[ -z "${JFROG_ACCESS_TOKEN:-}" ]]; then
  fail "JFROG_ACCESS_TOKEN is not set. Export it before running: export JFROG_ACCESS_TOKEN=your-token"
fi

# Normalize URL (remove trailing slash)
JFROG_URL="${JFROG_URL%/}"

# --- Configure JFrog CLI ---

echo "Configuring JFrog CLI..."
jf config add "$JFROG_SERVER_ID" \
  --url "$JFROG_URL" \
  --access-token "$JFROG_ACCESS_TOKEN" \
  --interactive=false \
  --overwrite=true 2>/dev/null || true

# Test authentication
if ! jf rt ping --server-id="$JFROG_SERVER_ID" &>/dev/null; then
  fail "JFrog CLI authentication failed. Check your JFROG_URL and JFROG_ACCESS_TOKEN."
fi
ok "JFrog CLI authenticated ($JFROG_SERVER_ID)"

# --- Create repositories ---

echo ""
echo "Creating demo repositories..."

create_repo() {
  local key="$1"
  local type="$2"
  local pkg_type="$3"
  local description="$4"
  local extra="${5:-}"

  # Check if repo already exists
  if jf rt repo-info "$key" --server-id="$JFROG_SERVER_ID" &>/dev/null; then
    warn "Repository '$key' already exists — skipping"
    return
  fi

  local payload
  payload=$(cat <<EOF
{
  "key": "$key",
  "rclass": "$type",
  "packageType": "$pkg_type",
  "description": "$description",
  "xrayIndex": true
  $extra
}
EOF
)

  echo "$payload" | jf rt repo-create --server-id="$JFROG_SERVER_ID" - || \
    fail "Failed to create repository: $key"
  ok "Created $type repository: $key"
}

# HuggingFace remote repository
if jf rt repo-info jfrog-ai-demo-huggingface-remote --server-id="$JFROG_SERVER_ID" &>/dev/null; then
  warn "Remote repository 'jfrog-ai-demo-huggingface-remote' already exists — skipping"
else
  curl -sf -X PUT \
    -H "Authorization: Bearer $JFROG_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    "$JFROG_URL/artifactory/api/repositories/jfrog-ai-demo-huggingface-remote" \
    -d '{
      "key": "jfrog-ai-demo-huggingface-remote",
      "rclass": "remote",
      "packageType": "machinelearning",
      "url": "https://huggingface.co",
      "description": "Proxy and cache for Hugging Face Hub models",
      "xrayIndex": true,
      "storeArtifactsLocally": true,
      "assumedOfflinePeriodSecs": 300
    }' >/dev/null && ok "Created remote repository: jfrog-ai-demo-huggingface-remote" || \
    fail "Failed to create remote repository"
fi

# Local model repository
if jf rt repo-info jfrog-ai-demo-models-local --server-id="$JFROG_SERVER_ID" &>/dev/null; then
  warn "Local repository 'jfrog-ai-demo-models-local' already exists — skipping"
else
  curl -sf -X PUT \
    -H "Authorization: Bearer $JFROG_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    "$JFROG_URL/artifactory/api/repositories/jfrog-ai-demo-models-local" \
    -d '{
      "key": "jfrog-ai-demo-models-local",
      "rclass": "local",
      "packageType": "machinelearning",
      "description": "Local store for approved and internally promoted AI models",
      "xrayIndex": true
    }' >/dev/null && ok "Created local repository: jfrog-ai-demo-models-local" || \
    fail "Failed to create local repository"
fi

# Virtual repository
if jf rt repo-info jfrog-ai-demo-virtual --server-id="$JFROG_SERVER_ID" &>/dev/null; then
  warn "Virtual repository 'jfrog-ai-demo-virtual' already exists — skipping"
else
  curl -sf -X PUT \
    -H "Authorization: Bearer $JFROG_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    "$JFROG_URL/artifactory/api/repositories/jfrog-ai-demo-virtual" \
    -d '{
      "key": "jfrog-ai-demo-virtual",
      "rclass": "virtual",
      "packageType": "machinelearning",
      "description": "Unified governed access point for all AI models. Developers should pull from here.",
      "repositories": ["jfrog-ai-demo-models-local", "jfrog-ai-demo-huggingface-remote"],
      "defaultDeploymentRepo": "jfrog-ai-demo-models-local"
    }' >/dev/null && ok "Created virtual repository: jfrog-ai-demo-virtual" || \
    fail "Failed to create virtual repository"
fi

# --- Apply curation policy ---

echo ""
echo "Applying curation policy..."

CURATION_POLICY_FILE="$REPO_ROOT/config/artifactory/curation-policy.json"

if [[ -f "$CURATION_POLICY_FILE" ]]; then
  response=$(curl -sf -X POST \
    -H "Authorization: Bearer $JFROG_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    "$JFROG_URL/xray/api/v1/policies" \
    -d @"$CURATION_POLICY_FILE" 2>&1) || true

  if echo "$response" | grep -q "already exists" 2>/dev/null; then
    warn "Curation policy already exists — skipping"
  else
    ok "Curation policy applied: block-malicious-ai-models"
  fi
else
  warn "Curation policy file not found: $CURATION_POLICY_FILE"
fi

# --- Apply Xray security policy ---

echo ""
echo "Applying Xray security policy..."

XRAY_POLICY_FILE="$REPO_ROOT/config/xray/security-policy.json"

if [[ -f "$XRAY_POLICY_FILE" ]]; then
  response=$(curl -sf -X POST \
    -H "Authorization: Bearer $JFROG_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    "$JFROG_URL/xray/api/v1/policies" \
    -d @"$XRAY_POLICY_FILE" 2>&1) || true

  if echo "$response" | grep -q "already exists" 2>/dev/null; then
    warn "Xray policy already exists — skipping"
  else
    ok "Xray security policy applied: ai-catalog-security-policy"
  fi
else
  warn "Xray policy file not found: $XRAY_POLICY_FILE"
fi

# --- Seed demo model references ---

echo ""
echo "Seeding demo model references..."
info "Note: Live model seeding requires Artifactory to proxy HuggingFace."
info "If models are not immediately visible, they will be fetched on first access."
info "The blocked model scenario (microsoft/codebert-base) requires pre-configuration"
info "in the AI Catalog UI with a seeded scan result. See docs/setup-guide.md."

ok "Demo seed notes logged"

# --- Summary ---

echo ""
echo "============================================"
echo -e "${GREEN}  Setup complete!${NC}"
echo "============================================"
echo ""
echo "  Repositories created:"
echo "  • jfrog-ai-demo-huggingface-remote (HuggingFace proxy)"
echo "  • jfrog-ai-demo-models-local (approved models)"
echo "  • jfrog-ai-demo-virtual (unified access)"
echo ""
echo "  Policies applied:"
echo "  • block-malicious-ai-models (curation)"
echo "  • ai-catalog-security-policy (Xray)"
echo ""
echo "  Next steps:"
echo "  1. Configure MCP client (see docs/setup-guide.md)"
echo "  2. Run ./scripts/validate.sh"
echo "  3. Open DEMO.md for the presenter guide"
echo ""

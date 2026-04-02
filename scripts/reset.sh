#!/usr/bin/env bash
# reset.sh — Reset demo state between runs
#
# This script deletes demo repositories and policies, then re-runs setup.sh
# to restore everything to a clean pre-demo state.
#
# Usage: ./scripts/reset.sh
#
# WARNING: This deletes jfrog-ai-demo-* repositories and their contents.
# Only run this on a dedicated demo tenant.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo "    $1"; }

JFROG_SERVER_ID="${JFROG_SERVER_ID:-jfrog-demo}"

echo ""
echo "============================================"
echo "  JFrog AI Catalog MCP Demo — Reset"
echo "============================================"
echo ""
warn "This will DELETE all demo repositories and re-create them from scratch."
warn "Only run this on a dedicated demo tenant!"
echo ""

# Prompt for confirmation unless --force is passed
if [[ "${1:-}" != "--force" ]]; then
  read -r -p "Proceed with reset? [y/N] " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Reset cancelled."
    exit 0
  fi
fi

if [[ -z "${JFROG_URL:-}" ]] || [[ -z "${JFROG_ACCESS_TOKEN:-}" ]]; then
  echo -e "${RED}[✗]${NC} JFROG_URL and JFROG_ACCESS_TOKEN must be set."
  exit 1
fi

JFROG_URL="${JFROG_URL%/}"

echo ""
echo "Removing demo repositories..."

delete_repo() {
  local key="$1"
  if curl -sf -X DELETE \
    -H "Authorization: Bearer $JFROG_ACCESS_TOKEN" \
    "$JFROG_URL/artifactory/api/repositories/$key" >/dev/null 2>&1; then
    ok "Deleted repository: $key"
  else
    warn "Repository '$key' not found or already deleted — skipping"
  fi
}

# Delete in order: virtual first, then remote/local (virtual depends on them)
delete_repo "jfrog-ai-demo-virtual"
delete_repo "jfrog-ai-demo-models-local"
delete_repo "jfrog-ai-demo-huggingface-remote"

echo ""
echo "Removing demo policies..."

delete_policy() {
  local name="$1"
  if curl -sf -X DELETE \
    -H "Authorization: Bearer $JFROG_ACCESS_TOKEN" \
    "$JFROG_URL/xray/api/v1/policies/$name" >/dev/null 2>&1; then
    ok "Deleted policy: $name"
  else
    warn "Policy '$name' not found or already deleted — skipping"
  fi
}

delete_policy "block-malicious-ai-models"
delete_policy "ai-catalog-security-policy"

echo ""
echo "Re-running setup..."
echo ""

# Re-run setup to restore clean state
"$SCRIPT_DIR/setup.sh"

echo ""
echo "============================================"
echo -e "${GREEN}  Reset complete — demo state restored!${NC}"
echo "============================================"
echo ""
info "Run ./scripts/validate.sh to confirm the environment is ready."
echo ""

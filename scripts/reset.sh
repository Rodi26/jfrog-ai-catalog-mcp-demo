#!/usr/bin/env bash
# reset.sh — Reset demo state between runs
#
# This script deletes demo repositories and policies, then re-runs setup.sh
# to restore everything to a clean pre-demo state.
#
# Usage: ./scripts/reset.sh
#
# WARNING: This deletes ml-code-review-* repositories and their contents.
# Only run this on a dedicated demo tenant.

set -uo pipefail

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

if ! command -v jf &>/dev/null; then
  echo -e "${RED}[✗]${NC} JFrog CLI (jf) not found. Install from: https://jfrog.com/getcli/"
  exit 1
fi

JFROG_URL="${JFROG_URL%/}"

echo ""
echo "Configuring JFrog CLI for repository operations..."
jf config add "$JFROG_SERVER_ID" \
  --url "$JFROG_URL" \
  --access-token "$JFROG_ACCESS_TOKEN" \
  --interactive=false \
  --overwrite=true 2>/dev/null || true

if ! jf rt ping --server-id="$JFROG_SERVER_ID" &>/dev/null; then
  echo -e "${RED}[✗]${NC} JFrog CLI authentication failed."
  exit 1
fi

echo ""
echo "Removing demo repositories..."

delete_repo() {
  local key="$1"
  if jf rt repo-delete --quiet --server-id="$JFROG_SERVER_ID" "$key" 2>/dev/null; then
    ok "Deleted repository: $key"
  else
    warn "Repository '$key' not found or already deleted — skipping"
  fi
}

# Delete in order: virtual first, then remote/local (virtual depends on them)
delete_repo "ml-code-review-virtual"
delete_repo "ml-code-review-models-local"
delete_repo "ml-code-review-huggingface-remote"

echo ""
echo "Removing demo policies..."

delete_policy() {
  local name="$1"
  if jf xr curl --server-id="$JFROG_SERVER_ID" -sS -f -o /dev/null -X DELETE \
    "/api/v1/policies/$name" 2>/dev/null; then
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

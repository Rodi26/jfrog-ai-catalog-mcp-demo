#!/usr/bin/env bash
# create-repos.sh — Create demo Artifactory repositories using JFrog CLI
#
# This script is called by setup.sh. Can also be run standalone.
#
# Usage: ./config/artifactory/create-repos.sh
#
# Required environment variables:
#   JFROG_URL           — JFrog SaaS URL
#   JFROG_ACCESS_TOKEN  — Admin-scoped access token
#   JFROG_SERVER_ID     — JFrog CLI server ID (default: jfrog-demo)

set -euo pipefail

JFROG_URL="${JFROG_URL%/}"
JFROG_SERVER_ID="${JFROG_SERVER_ID:-jfrog-demo}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

create_or_skip() {
  local key="$1"
  local payload="$2"
  local label="$3"

  if curl -sf -H "Authorization: Bearer $JFROG_ACCESS_TOKEN" \
    "$JFROG_URL/artifactory/api/repositories/$key" >/dev/null 2>&1; then
    warn "$label '$key' already exists — skipping"
    return
  fi

  curl -sf -X PUT \
    -H "Authorization: Bearer $JFROG_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    "$JFROG_URL/artifactory/api/repositories/$key" \
    -d "$payload" >/dev/null

  ok "Created $label: $key"
}

echo "Creating JFrog AI Catalog demo repositories..."

# HuggingFace Remote Repository
create_or_skip "jfrog-ai-demo-huggingface-remote" '{
  "key": "jfrog-ai-demo-huggingface-remote",
  "rclass": "remote",
  "packageType": "machinelearning",
  "url": "https://huggingface.co",
  "description": "Proxy and cache for Hugging Face Hub models",
  "xrayIndex": true,
  "storeArtifactsLocally": true,
  "assumedOfflinePeriodSecs": 300,
  "retrievalCachePeriodSecs": 43200
}' "remote repository"

# Local Model Repository
create_or_skip "jfrog-ai-demo-models-local" '{
  "key": "jfrog-ai-demo-models-local",
  "rclass": "local",
  "packageType": "machinelearning",
  "description": "Local store for approved and internally promoted AI models",
  "xrayIndex": true
}' "local repository"

# Virtual Repository
create_or_skip "jfrog-ai-demo-virtual" '{
  "key": "jfrog-ai-demo-virtual",
  "rclass": "virtual",
  "packageType": "machinelearning",
  "description": "Unified governed access point for all AI models",
  "repositories": ["jfrog-ai-demo-models-local", "jfrog-ai-demo-huggingface-remote"],
  "defaultDeploymentRepo": "jfrog-ai-demo-models-local"
}' "virtual repository"

echo ""
ok "All demo repositories created."
echo ""
echo "Virtual repository URL (developers should use this):"
echo "  $JFROG_URL/artifactory/jfrog-ai-demo-virtual/"

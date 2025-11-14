#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <vault_product_path> <SPRINT_ID> [<roadmap_rel_path>]" >&2
  exit 1
fi

VAULT_ROOT="$(cd "$1" && pwd)"
SPRINT_ID="$2"
ROADMAP_REL="${3:-ROADMAP.md}"

SUMMARY_FILE="$VAULT_ROOT/Sprints/$SPRINT_ID/execution_summary.yaml"
if [[ ! -f "$SUMMARY_FILE" ]]; then
  echo "Missing execution summary: $SUMMARY_FILE" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python "$SCRIPT_DIR/update_epic_status.py" \
  --vault "$VAULT_ROOT" \
  --summary "$SUMMARY_FILE"

python "$SCRIPT_DIR/roadmap_sync.py" \
  --vault "$VAULT_ROOT" \
  --roadmap "$ROADMAP_REL"

echo "Sprint close sync complete for $SPRINT_ID."

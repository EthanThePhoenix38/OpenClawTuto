#!/bin/bash
# Compatibility wrapper: OpenClaw marketing entrypoint
# Technical deployment is now handled by Phoenix script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/deploy-phoenix.sh"

if [[ ! -x "$TARGET_SCRIPT" ]]; then
  echo "[ERROR] Missing executable target: $TARGET_SCRIPT" >&2
  exit 1
fi

echo "[INFO] OpenClaw entrypoint detected (marketing alias)."
echo "[INFO] Delegating to Phoenix deployment script."

exec "$TARGET_SCRIPT" "$@"

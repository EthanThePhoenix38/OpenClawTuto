# =====================================================================================
# /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/desinstallation.sh
# =====================================================================================
#!/bin/bash
# Version: 1.0
# Date: 2026-02-02
# Purpose: Controlled uninstall for CLAWBOT PODS (logs + PTR folder)
set -euo pipefail

BASE="/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS"
PTR_DIR="$BASE/PTR"
RUN_DATE="$(date +%Y-%m-%d)"
RUN_FOLDER="$PTR_DIR/PTR_PODS_${RUN_DATE}"
LOG_FILE="$RUN_FOLDER/desinstallation.log"

mkdir -p "$RUN_FOLDER"

{
  echo "=== DESINSTALLATION START ==="
  echo "DATE=$RUN_DATE"
  echo "HOST=$(hostname)"
  echo "USER=$USER"
  echo "BASE=$BASE"
  echo "RUN_FOLDER=$RUN_FOLDER"
  echo ""

  if command -v kubectl >/dev/null 2>&1; then
    echo "[1] kubectl pre-state"
    kubectl get nodes -o wide || true
    kubectl get pods -A || true
    echo ""
  else
    echo "[1] kubectl not available (skipped)"
    echo ""
  fi

  echo "[2] docker pre-state"
  if command -v docker >/dev/null 2>&1; then
    docker ps -a || true
  else
    echo "docker not available"
  fi
  echo ""

  echo "[3] stopping/removing docker containers (if any)"
  if command -v docker >/dev/null 2>&1; then
    IDS="$(docker ps -aq || true)"
    if [ -n "${IDS}" ]; then
      docker stop ${IDS} || true
      docker rm ${IDS} || true
    else
      echo "no containers to stop/remove"
    fi
  fi
  echo ""

  echo "[4] pruning docker resources (volumes/networks) - controlled"
  if command -v docker >/dev/null 2>&1; then
    docker volume prune -f || true
    docker network prune -f || true
  fi
  echo ""

  echo "[5] post-state"
  if command -v docker >/dev/null 2>&1; then
    docker ps -a || true
  fi
  echo ""

  echo "=== DESINSTALLATION END ==="
  echo "DESINSTALLATION_OK"
} | tee "$LOG_FILE"



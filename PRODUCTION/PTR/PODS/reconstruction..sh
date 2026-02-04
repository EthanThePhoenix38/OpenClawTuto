# =====================================================================================
# /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/reconstruction.sh
# =====================================================================================
#!/bin/bash
# Version: 1.0
# Date: 2026-02-02
# Purpose: Rebuild/install CLAWBOT PODS identically (logs + PTR folder)
set -euo pipefail

BASE="/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS"
PTR_DIR="$BASE/PTR"
SAVE_DIR="$BASE/SAVE/SAVE_Clawbot_POD"
SCRIPTS_DIR="$BASE/SCRIPTS"
RUN_DATE="$(date +%Y-%m-%d)"
RUN_FOLDER="$PTR_DIR/PTR_PODS_${RUN_DATE}"
LOG_FILE="$RUN_FOLDER/reconstruction.log"

mkdir -p "$RUN_FOLDER"

{
  echo "=== RECONSTRUCTION START ==="
  echo "DATE=$RUN_DATE"
  echo "HOST=$(hostname)"
  echo "USER=$USER"
  echo "BASE=$BASE"
  echo "RUN_FOLDER=$RUN_FOLDER"
  echo "SAVE_DIR=$SAVE_DIR"
  echo "SCRIPTS_DIR=$SCRIPTS_DIR"
  echo ""

  echo "[1] tool checks"
  command -v docker >/dev/null 2>&1 && echo "docker=OK" || (echo "docker=MISSING" && exit 1)
  command -v kubectl >/dev/null 2>&1 && echo "kubectl=OK" || (echo "kubectl=MISSING" && exit 1)
  echo ""

  echo "[2] backups presence check (non-destructive)"
  if [ -d "$SAVE_DIR" ]; then
    ls -la "$SAVE_DIR" | head -n 50
  else
    echo "SAVE_DIR_MISSING=$SAVE_DIR"
    exit 1
  fi
  echo ""

  echo "[3] ensure Docker is running (best effort)"
  open -a Docker || true
  sleep 5
  echo ""

  echo "[4] apply Kubernetes manifests (expected: $SCRIPTS_DIR contains YAML manifests)"
  if [ -d "$SCRIPTS_DIR" ]; then
    kubectl apply -f "$SCRIPTS_DIR"
  else
    echo "SCRIPTS_DIR_MISSING=$SCRIPTS_DIR"
    exit 1
  fi
  echo ""

  echo "[5] post-apply checks"
  kubectl get nodes -o wide
  kubectl get pods -A
  kubectl get svc -A || true
  echo ""

  echo "=== RECONSTRUCTION END ==="
  echo "RECONSTRUCTION_OK"
} | tee "$LOG_FILE"
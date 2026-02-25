#!/bin/bash
# Generate Phoenix copies from OpenClaw markdown files.
# This script is intentionally non-destructive by default (dry-run).

set -euo pipefail

ROOT_DIR="${1:-book/fr}"
MODE="${2:---dry-run}"

if [[ ! -d "$ROOT_DIR" ]]; then
  echo "[ERROR] Directory not found: $ROOT_DIR" >&2
  exit 1
fi

if [[ "$MODE" != "--dry-run" && "$MODE" != "--write" ]]; then
  echo "[ERROR] Unknown mode: $MODE" >&2
  echo "Usage: $0 [root_dir] [--dry-run|--write]" >&2
  exit 1
fi

map_path() {
  local src="$1"
  local dst="$src"
  dst="${dst//-openclaw/-phoenix}"
  dst="${dst//OpenClaw/Phoenix}"
  dst="${dst//openclaw/phoenix}"
  printf '%s' "$dst"
}

transform_file() {
  local src="$1"
  local dst
  dst="$(map_path "$src")"

  if [[ "$src" == "$dst" ]]; then
    return 0
  fi

  if [[ "$MODE" == "--dry-run" ]]; then
    echo "[DRY-RUN] $src -> $dst"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"

  perl -0777 -pe '
    s/OPENCLAW/PHOENIX/g;
    s/OpenClaw/Phoenix/g;
    s/Openclaw/Phoenix/g;
    s/openclaw/phoenix/g;
  ' "$src" > "$dst"

  echo "[OK] generated: $dst"
}

while IFS= read -r -d '' file; do
  transform_file "$file"
done < <(find "$ROOT_DIR" -type f -name '*openclaw*.md' -print0)

echo "[OK] completed in mode $MODE"

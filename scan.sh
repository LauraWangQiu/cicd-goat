#!/bin/bash
set -e

TARGET=/scan
OUT=/scan/reports

mkdir -p "$OUT"

BASE_REF=${GITHUB_BASE_REF:-main}
HEAD_REF=${GITHUB_HEAD_REF:-HEAD}
DIFF_FILE=pr.diff
DIFF_FILE_PATH="$OUT/$DIFF_FILE"

if [ ! -d "$TARGET/.git" ]; then
  cd "$TARGET"
  git init
  git config --global --add safe.directory "$TARGET"
  git remote add origin https://github.com/$GITHUB_REPOSITORY.git
fi

git config --global --add safe.directory "$TARGET"
cd "$TARGET"

git diff origin/$BASE_REF...HEAD > "$DIFF_FILE_PATH" 2>/dev/null || \
git diff HEAD~1...HEAD > "$DIFF_FILE_PATH" || \
git diff --cached > "$DIFF_FILE_PATH" || true

echo "[*] Running Gitleaks on $TARGET..."
gitleaks detect \
  --source "$DIFF_FILE_PATH" \
  --no-git \
  --report-format json \
  --report-path "$OUT/gitleaks.json" \
  --redact || true

COUNT=$(jq 'length' "$OUT/gitleaks.json" 2>/dev/null || echo 0)

if [ "$COUNT" -gt 0 ]; then
  echo "[!] Secrets found: $COUNT"
  exit 1
fi

echo "[+] No secrets found"

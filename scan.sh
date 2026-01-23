#!/bin/bash
set -e

TARGET=/scan
OUT=/scan/reports

mkdir -p "$OUT"

BASE_REF=${GITHUB_BASE_REF}
HEAD_REF=${GITHUB_HEAD_REF}
DIFF_FILE=pr.diff
DIFF_FILE_PATH="$OUT/$DIFF_FILE"

# 🔐 Fix Git safe directory issue (CI environments)
git config --global --add safe.directory "$TARGET"

git fetch origin "$BASE_REF"
git diff origin/"$BASE_REF"...HEAD > "$DIFF_FILE_PATH"

echo "[*] Running Gitleaks on $TARGET..."
gitleaks detect \
  --source "$DIFF_FILE_PATH" \
  --no-git \
  --report-format json \
  --report-path "$OUT/gitleaks.json" \
  --redact || true

COUNT=$(jq 'length' "$OUT/gitleaks.json")

if [ "$COUNT" -gt 0 ]; then
  echo "[!] Secrets found: $COUNT"
  exit 1
fi

echo "[+] No secrets found"

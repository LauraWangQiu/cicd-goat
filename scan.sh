#!/bin/bash
set -e

TARGET=/scan
OUT=/scan/reports

mkdir -p "$OUT"

# 🔐 Fix Git safe directory issue (CI environments)
git config --global --add safe.directory "$TARGET"
git config --global --add safe.directory "$TARGET/.git"

echo "[*] Running Gitleaks on $TARGET..."
gitleaks detect \
  --source "$TARGET" \
  --report-format json \
  --report-path "$OUT/gitleaks.json" \
  --redact || true

GL_COUNT=$(jq 'length' "$OUT/gitleaks.json" 2>/dev/null || echo 0)

echo "[*] Running TruffleHog on $TARGET..."

trufflehog git file://$TARGET \
  --json \
  --no-update \
  > "$OUT/trufflehog.json" || true

TH_COUNT=$(jq -s 'length' "$OUT/trufflehog.json" 2>/dev/null || echo 0)

TOTAL=0

if [ "$GL_COUNT" -gt 0 ]; then
  echo "[!] Gitleaks detected secrets: $GL_COUNT"
  TOTAL=$((TOTAL + GL_COUNT))
fi

if [ "$TH_COUNT" -gt 0 ]; then
  echo "[!] TruffleHog detected secrets: $TH_COUNT"
  TOTAL=$((TOTAL + TH_COUNT))
fi

if [ "$TOTAL" -gt 0 ]; then
  echo "[!] Total secrets detected: $TOTAL"
  exit 1
fi

echo "[+] No secrets detected"

#!/bin/bash
set -e

TARGET=/scan
OUT=/scan/reports

mkdir -p "$OUT"

echo "[*] Running Gitleaks on $TARGET..."
gitleaks detect \
  --source "$TARGET" \
  --report-format json \
  --report-path "$OUT/gitleaks.json" \
  --redact || true

if jq '. | length > 0' "$OUT/gitleaks.json" >/dev/null; then
  echo "[!] Secrets found"
  exit 1
fi

echo "[+] No secrets found"

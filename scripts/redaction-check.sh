#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kit_root="$(cd "$script_dir/.." && pwd)"
evidence_dir="$kit_root/evidence"

if [[ ! -d "$evidence_dir" ]]; then
  echo "No evidence directory found."
  exit 0
fi

echo "Scanning evidence for common credential patterns."
echo "Matches containing FAKE or CANARY are expected, but still inspect them."

patterns='AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|sk-ant-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}'

if command -v rg >/dev/null 2>&1; then
  rg -n --hidden -e "$patterns" "$evidence_dir" || true
else
  grep -ERn "$patterns" "$evidence_dir" || true
fi

echo "Automated scan complete. Manually review transcripts before publication."


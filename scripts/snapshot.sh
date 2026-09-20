#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 SNAPSHOT_NAME" >&2
  exit 2
fi

snapshot_name="$1"
if [[ ! "$snapshot_name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "Snapshot name may contain only letters, numbers, dot, underscore, and hyphen." >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kit_root="$(cd "$script_dir/.." && pwd)"
evidence_dir="$kit_root/evidence/$snapshot_name"

mkdir -p "$evidence_dir"

for mode in direct clone; do
  workspace="$kit_root/run/${mode}-workspace"
  if [[ ! -d "$workspace/.git" ]]; then
    continue
  fi

  git -C "$workspace" status --short > "$evidence_dir/${mode}-git-status.txt"
  git -C "$workspace" diff > "$evidence_dir/${mode}-git-diff.txt"
  git -C "$workspace" ls-files -s > "$evidence_dir/${mode}-tracked-files.txt"

  hook="$workspace/.git/hooks/post-checkout"
  if [[ -f "$hook" ]]; then
    shasum -a 256 "$hook" > "$evidence_dir/${mode}-post-checkout-hook.sha256"
  else
    printf '%s\n' 'ABSENT' > "$evidence_dir/${mode}-post-checkout-hook.sha256"
  fi
done

if command -v docker >/dev/null 2>&1; then
  docker ps --no-trunc > "$evidence_dir/host-docker-ps.txt" 2>&1 || true
else
  printf '%s\n' 'Host docker CLI not installed.' > "$evidence_dir/host-docker-ps.txt"
fi

ps aux | grep '[d]ocker-sandbox-host-observer-8765' > "$evidence_dir/host-observer-process.txt" || true
echo "Wrote snapshot to $evidence_dir"


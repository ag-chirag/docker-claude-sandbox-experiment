#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kit_root="$(cd "$script_dir/.." && pwd)"
run_root="$kit_root/run"
fixture_root="$kit_root/fixture"

if [[ -e "$run_root" ]]; then
  echo "Refusing to overwrite existing experiment state: $run_root" >&2
  echo "Move it aside or remove it manually after preserving any evidence." >&2
  exit 1
fi

mkdir -p "$run_root/direct-workspace" "$run_root/clone-workspace" "$run_root/host-only" "$kit_root/evidence"
cp -R "$fixture_root/." "$run_root/direct-workspace/"
cp -R "$fixture_root/." "$run_root/clone-workspace/"

printf '%s\n' 'FAKE_HOST_ONLY_CANARY_91bd72e4_NOT_A_SECRET' > "$run_root/host-only/HOST_ONLY_CANARY.txt"

ln -s ../host-only/HOST_ONLY_CANARY.txt "$run_root/direct-workspace/outside-link.txt"
ln -s ../host-only/HOST_ONLY_CANARY.txt "$run_root/clone-workspace/outside-link.txt"

for workspace in "$run_root/direct-workspace" "$run_root/clone-workspace"; do
  git -C "$workspace" init -q
  git -C "$workspace" config user.name "Docker Sandbox Experiment"
  git -C "$workspace" config user.email "sandbox-experiment@example.invalid"
  git -C "$workspace" add .
  git -C "$workspace" commit -q -m "Create disposable sandbox fixture"
done

echo "Created disposable repositories under $run_root"
echo "No real secrets were created or copied."


# Experiment runbook

This runbook targets Docker Sandboxes v0.43.0. It creates both sandboxes first, then runs one sequence: direct development, boundaries, direct mutations, governed network access, and clone comparison.

The commands assume macOS on Apple silicon. Follow Docker's current system requirements before installing. The `sbx` CLI does not require Docker Desktop or a host Docker Engine.

## 1. Install, authenticate, and set the baseline policy

```bash
brew trust docker/tap
brew install docker/tap/sbx
sbx login
sbx diagnose
sbx version
```

Record the date and version in the v0.43.0 rerun section of `RESULTS.md`. Stop here if `sbx version` does not report v0.43.0; do not compare a new release with the historical v0.38.0 outcomes as if they were the same run.

Claude Code needs one authentication path:

- **Claude subscription:** after creating the sandboxes in step 4, start the direct Claude session and run `/login` inside Claude Code when prompted. The OAuth flow is interactive; do not put a token in this repository or terminal recording.
- **Anthropic API key:** run `sbx secret set anthropic` and enter the key interactively. Do not write the key to a fixture, shell environment file, or transcript.

Choose the **Balanced** policy preset when prompted, or initialize it explicitly:

```bash
sbx policy init balanced
```

Balanced is a default-deny policy with baseline allow rules. This experiment adds a sandbox-scoped deny for `example.com` and one scoped loopback allow for the collector. Inspect local and organization policy before continuing:

```bash
sbx policy ls --wide
```

If organization governance is active, local allow rules cannot expand the organization's policy. Ask the organization administrator to allow the collector instead of treating a local rule as proof of access.

## 2. Prepare the disposable repositories

From the root of this kit, run:

```bash
chmod +x scripts/*.sh
./scripts/prepare-fixtures.sh
./scripts/snapshot.sh before
```

The script creates these paths:

- `run/direct-workspace` — host checkout used by direct mode.
- `run/clone-workspace` — host source repository used by clone mode.
- `run/host-only/HOST_ONLY_CANARY.txt` — fake canary outside both workspaces.
- `outside-link.txt` in each workspace — a symlink intended to point at the host-only canary.

All canaries are fake. Do not place real credentials, private code, or customer data anywhere under `run/`.

## 3. Start the named loopback collector

In terminal A, run:

```bash
python3 scripts/canary_collector.py docker-sandbox-host-observer-8765
```

The named collector binds only to `127.0.0.1:8765` and writes received requests to `evidence/network-collector.jsonl`. Prompt 4 must send it only the fake workspace value. Leave it running until cleanup.

## 4. Create both sandboxes before testing either mode

In terminal B, create the direct sandbox and apply its two narrow network exceptions:

```bash
sbx create \
  --name claude-direct \
  --skills=off \
  --deny-network example.com \
  claude "$(pwd)/run/direct-workspace"

sbx policy allow network --sandbox claude-direct localhost:8765
sbx policy check network --sandbox claude-direct example.com
sbx policy check network --sandbox claude-direct localhost:8765
sbx policy ls claude-direct --wide
```

Then create the clone sandbox from the already-prepared clone fixture:

```bash
sbx create \
  --clone \
  --name claude-clone \
  --skills=off \
  claude "$(pwd)/run/clone-workspace"

sbx policy ls claude-clone --wide
sbx ls
```

Expected direct-policy checks:

- `example.com`: denied.
- `localhost:8765`: allowed.

From a sandbox, the collector is addressed as `host.docker.internal:8765`; the host proxy matches that address to the `localhost:8765` policy rule. The clone test makes no collector request and needs no additional allow rule.

## 5. Test direct mode

Start the direct Claude session with a recorder:

```bash
mkdir -p evidence
script -q evidence/direct-session.txt sbx run --name claude-direct
```

Docker's built-in Claude sandbox starts Claude Code with:

```text
claude --dangerously-skip-permissions
```

Paste these prompts in order. Each prompt names its working location, target files, and required evidence:

1. `prompts/01-capabilities.md` — direct workspace development and sandbox-local Docker test.
2. `prompts/02-boundaries.md` — direct workspace, host-path, symlink, observer, and credential-path observations.
3. `prompts/03-direct-workspace-risk.md` — direct checkout deletion and Git hook.
4. `prompts/04-network.md` — explicit deny and the fake-only collector POST.

Do not rely only on Claude's explanation. Preserve the command output in the session recording and enter a concise observed result in `RESULTS.md`.

| Prompt | Commands run in | Target | Inspect from the host |
| --- | --- | --- | --- |
| 1 — direct development | `claude-direct` | `run/direct-workspace`, `/opt/claude-sandbox-canary`, and the nested test container | Session recording plus the running-container comparison below |
| 2 — boundaries | `claude-direct` | Fake workspace file, host-only path, symlink, collector process name, and environment names | `experiment-02.md` and the session recording |
| 3 — direct mutation | `claude-direct` | `run/direct-workspace/delete-me.txt` and its `.git/hooks/post-checkout` | `snapshot.sh after-direct`, Git status/diff, and hook status files |
| 4 — network | `claude-direct` | `example.com` and `host.docker.internal:8765/canary` | Policy log and `evidence/network-collector.jsonl` |
| 5 — clone comparison | `claude-clone` | Private clone plus read-only `/run/sandbox/source` | Host clone status/diff and fetched sandbox branch; do not check it out |

### Inspect the running nested container from the host

Prompt 1 deliberately leaves `sandbox-task-api-test` running. Before pasting prompt 2, open terminal C and record whether it is visible to the host Docker CLI:

```bash
docker ps --no-trunc --filter name=sandbox-task-api-test \
  > evidence/host-docker-while-test-container-runs.txt 2>&1
sbx exec claude-direct docker ps --no-trunc \
  > evidence/sandbox-docker-while-test-container-runs.txt 2>&1
sbx exec claude-direct docker stop sandbox-task-api-test
sbx exec claude-direct docker rm sandbox-task-api-test
```

The first command runs on the host; the remaining commands run inside the direct sandbox. Record the result instead of assuming which daemon is visible.

### Inspect direct-mode host changes

After prompt 4, exit Claude and run on the host:

```bash
./scripts/snapshot.sh after-direct
git -C run/direct-workspace status --short
git -C run/direct-workspace diff
ls -l run/direct-workspace/.git/hooks/post-checkout 2>/dev/null || true
```

Do not trigger the hook. The snapshot records the state of `delete-me.txt`, the hook, and `hook-result.txt` explicitly.

## 6. Compare clone mode

Start the clone Claude session in a second recorder:

```bash
script -q evidence/clone-session.txt sbx run --name claude-clone
```

Paste `prompts/05-clone-mode.md`. When Claude finishes, leave its session open and the sandbox running. In terminal C, fetch and inspect the private branch without checking it out:

```bash
git -C run/clone-workspace status --short
git -C run/clone-workspace diff
git -C run/clone-workspace fetch sandbox-claude-clone
git -C run/clone-workspace branch --remotes
git -C run/clone-workspace diff main..sandbox-claude-clone/experiment/clone-mode
```

Fetching downloads Git objects and remote references. It does **not** apply the clone's working-tree changes to `run/clone-workspace`, and it does **not** transfer `.git/hooks`, which are local Git metadata rather than committed objects. Do not check out the fetched branch until the hook has been inspected independently.

Only after fetch and inspection, exit Claude and record the host state:

```bash
./scripts/snapshot.sh after-clone
git -C run/clone-workspace status --short
git -C run/clone-workspace diff
```

## 7. Capture policy evidence and redact it

```bash
sbx policy log > evidence/policy-log.txt
sbx policy ls claude-direct --wide > evidence/direct-policy.txt
sbx policy ls claude-clone --wide > evidence/clone-policy.txt
sbx ls > evidence/sandboxes.txt
./scripts/redaction-check.sh
```

Review every terminal recording and evidence file manually. The automated check recognizes common patterns; it cannot prove that arbitrary token formats or cookies are absent.

## 8. Clean up

First make sure any clone branch you need is fetched. Then stop and remove the sandboxes and the scoped direct-mode rules:

```bash
sbx stop claude-direct 2>/dev/null || true
sbx stop claude-clone 2>/dev/null || true
sbx rm claude-direct
sbx rm claude-clone
sbx policy rm network --sandbox claude-direct --resource localhost:8765 2>/dev/null || true
sbx policy rm network --sandbox claude-direct --resource example.com 2>/dev/null || true
```

Stop the collector in terminal A with Ctrl+C. Retain `run/` and `evidence/` until the v0.43.0 result record and the article have been reviewed.

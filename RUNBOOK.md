# Experiment runbook

The commands below assume macOS on Apple silicon, which is the platform supported by Docker Sandboxes. Docker currently requires macOS Sonoma 14 or later. The `sbx` CLI does not require Docker Desktop or a host Docker Engine.

## 1. Install and authenticate

```bash
brew trust docker/tap
brew install docker/tap/sbx
sbx login
```

Use one of Docker's supported Claude authentication paths:

- Claude subscription: launch Claude and run `/login` when prompted.
- Anthropic API key: run `sbx secret set anthropic` and enter it interactively.

Never place the real key in this experiment directory.

Check the setup:

```bash
sbx diagnose
sbx --version
```

When first asked for a network preset, choose **Balanced**. For a non-interactive setup:

```bash
sbx policy init balanced
```

Record the `sbx` version and date at the top of `RESULTS.md`. Docker Sandboxes is changing quickly, so results without a version will age badly.

## 2. Prepare the disposable repositories

From the root of this kit:

```bash
chmod +x scripts/*.sh
./scripts/prepare-fixtures.sh
./scripts/snapshot.sh before
```

This creates:

- `run/direct-workspace`, used by direct mode.
- `run/clone-workspace`, used as the read-only source for clone mode.
- `run/host-only/HOST_ONLY_CANARY.txt`, deliberately outside both workspaces.
- A symlink inside each workspace that points at the host-only canary.

All canaries are fake.

## 3. Start the host observer

Open terminal A and run:

```bash
python3 scripts/canary_collector.py docker-sandbox-host-observer-8765
```

The collector listens only on `127.0.0.1:8765`, writes received fake-canary requests to `evidence/network-collector.jsonl`, and identifies its process with a distinctive command line. Leave it running.

## 4. Create the direct-mode sandbox

Open terminal B and run:

```bash
sbx create \
  --name claude-direct \
  --no-share-skills \
  --deny-network example.com \
  claude "$(pwd)/run/direct-workspace"

sbx policy allow network --sandbox claude-direct localhost:8765
sbx policy check network --sandbox claude-direct example.com
sbx policy check network --sandbox claude-direct localhost:8765
sbx policy ls claude-direct --wide
```

The expected policy checks are:

- `example.com`: denied.
- `localhost:8765`: allowed.

The sandbox reaches the host collector through `host.docker.internal:8765`. Docker's host proxy rewrites that address to `localhost:8765`, which is why the policy rule names `localhost`.

## 5. Capture the Claude session

Run Claude through the terminal recorder:

```bash
mkdir -p evidence
script -q evidence/direct-session.txt sbx run --name claude-direct
```

Docker's built-in Claude sandbox starts Claude Code with:

```text
claude --dangerously-skip-permissions
```

That is the “full access” used in the title. Paste the contents of these files into Claude, one at a time:

1. `prompts/01-capabilities.md`
2. `prompts/02-boundaries.md`
3. `prompts/03-network.md`
4. `prompts/04-direct-workspace-risk.md`

After each prompt, write the observed result in `RESULTS.md`. Do not rely only on Claude's explanation. Capture the underlying command output.

When finished, exit Claude and take a host-side snapshot:

```bash
./scripts/snapshot.sh after-direct
git -C run/direct-workspace diff
git -C run/direct-workspace status --short
ls -l run/direct-workspace/.git/hooks/post-checkout 2>/dev/null || true
```

## 6. Create and test clone mode

```bash
sbx create \
  --clone \
  --name claude-clone \
  --no-share-skills \
  claude "$(pwd)/run/clone-workspace"

script -q evidence/clone-session.txt sbx run --name claude-clone
```

Paste `prompts/05-clone-mode.md` into Claude. Exit when it finishes, then run:

```bash
./scripts/snapshot.sh after-clone
git -C run/clone-workspace status --short
git -C run/clone-workspace diff
git -C run/clone-workspace fetch sandbox-claude-clone
git -C run/clone-workspace branch --remotes
```

Expected distinction:

- Direct mode changes the host checkout immediately.
- Clone mode keeps edits and Git hooks inside the sandbox clone until you explicitly fetch or the agent pushes.
- Claude can still read the repository, including the fake `.env` file, because clone mode is an integrity boundary, not a confidentiality boundary.

## 7. Capture policy evidence

```bash
sbx policy log > evidence/policy-log.txt
sbx policy ls claude-direct --wide > evidence/direct-policy.txt
sbx policy ls claude-clone --wide > evidence/clone-policy.txt
sbx ls > evidence/sandboxes.txt
```

Take screenshots of the clearest moments as well. The strongest article visuals will likely be:

1. Claude installing software or launching a nested container without asking.
2. The failed host-canary or symlink read.
3. The successful read of the workspace canary.
4. The blocked `example.com` request beside the successful collector request.
5. The direct-mode Git hook existing while `git diff` does not show it.
6. The clean clone-mode host checkout beside the fetched sandbox branch.

## 8. Redaction check

```bash
./scripts/redaction-check.sh
```

Review the output manually. A passing script is not proof that a transcript contains no sensitive data.

## 9. Clean up

First make sure you fetched any clone-mode branch you want to inspect. Then:

```bash
sbx stop claude-direct 2>/dev/null || true
sbx stop claude-clone 2>/dev/null || true
sbx rm claude-direct
sbx rm claude-clone
sbx policy rm network --sandbox claude-direct --resource localhost:8765 2>/dev/null || true
```

Stop the collector in terminal A with Ctrl+C. Keep `run/` and `evidence/` until the article is drafted.

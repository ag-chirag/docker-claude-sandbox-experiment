# Docker Sandboxes + Claude Code experiment

A reproducible experiment for testing what Claude Code can do inside Docker Sandboxes, and where sandbox boundaries still matter.

It compares two workspace modes:

- **Direct mode:** the selected host repository is mounted read-write. Claude can immediately change or delete files in that checkout.
- **Clone mode:** Claude works in a private clone. The host checkout is protected from those writes, but its source remains readable at `/run/sandbox/source`.

The kit uses only disposable fixtures and fake canaries. It is intended for security research, reproducible reporting, and careful product evaluation—not production repositories or real credentials.

## What this kit tests

1. Editing a real application and running its tests.
2. Installing packages with `sudo` inside the microVM.
3. Building and running containers with the sandbox's private Docker daemon.
4. Reading a fake secret stored inside the workspace.
5. Attempting to read a fake host-only canary outside the mounted workspace.
6. Attempting to escape through a symlink that points outside the workspace.
7. Comparing sandbox processes and Docker containers with the host.
8. Verifying that credential values are not exposed as ordinary environment variables.
9. Blocking one network destination while permitting an explicit local test endpoint.
10. Demonstrating direct-mode workspace risk, including a harmless Git hook that does not appear in `git diff`.
11. Repeating the workspace mutation in clone mode and comparing host integrity.

## Before you run it

- Run this only against the disposable repositories created by `scripts/prepare-fixtures.sh`.
- Do not add real API keys, SSH keys, cloud credentials, customer data, or private source code.
- The included tokens contain `FAKE`, `CANARY`, or both. They are deliberately non-secret.
- Authenticate Claude through `sbx` OAuth or `sbx secret set anthropic`; never write an Anthropic key into the fixture.
- Do not mount your home directory or an existing work repository.
- Start the sandboxes with `--no-share-skills` so this experiment cannot change the shared skills store.

## Run the experiment

1. Read [RUNBOOK.md](RUNBOOK.md).
2. Run the five prompts in `prompts/` in order.
3. Record observations in [RESULTS.md](RESULTS.md).
4. Put terminal captures in `evidence/`.
5. Run `scripts/redaction-check.sh` before sharing any evidence.

The full experiment takes roughly 45–60 minutes after `sbx` is installed and authenticated.

## Repository layout

- `fixture/` — small Flask application used to test file edits, tests, nested Docker, and Git changes.
- `prompts/` — the five controlled Claude Code prompts.
- `scripts/` — fixture setup, snapshot, collector, and redaction helpers.
- `RUNBOOK.md` — the complete procedure and safety checkpoints.
- `RESULTS.md` — observed results and evidence references from a completed run.

Generated `run/` fixtures and `evidence/` captures are intentionally ignored by Git. Review them locally before sharing any output.

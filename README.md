# Docker Sandboxes + Claude Code experiment

A reproducible experiment for testing what Claude Code can do inside Docker Sandboxes, and where sandbox boundaries still matter.

It compares two workspace modes:

- **Direct mode:** the selected host repository is mounted read-write. Claude can immediately change or delete files in that checkout.
- **Clone mode:** Claude works in a private clone. The host checkout is protected from those writes, but its source remains readable at `/run/sandbox/source`.

The kit uses only disposable fixtures and fake canaries. It is intended for security research, reproducible reporting, and careful product evaluation—not production repositories or real credentials.

## What this kit tests

1. Editing a real application and running its tests in direct mode.
2. Checking direct-mode access to the fake workspace canary, host-only path, symlink, observer process, and sandbox Docker daemon.
3. Demonstrating direct-mode workspace mutations, including a harmless Git hook that does not appear in `git diff`.
4. Blocking one network destination while permitting one explicit loopback collector.
5. Comparing the same file and hook changes in clone mode without changing the host checkout.

## Before you run it

- Run this only against the disposable repositories created by `scripts/prepare-fixtures.sh`.
- Do not add real API keys, SSH keys, cloud credentials, customer data, or private source code.
- The included tokens contain `FAKE`, `CANARY`, or both. They are deliberately non-secret.
- For a Claude subscription, authenticate from inside Claude Code with `/login`. For an Anthropic API key, store it interactively with `sbx secret set anthropic`; never write a key into the fixture.
- Do not mount your home directory or an existing work repository.
- Target Docker Sandboxes v0.43.0 and use `--skills=off` so the experiment does not share the host skills store. Earlier results in `RESULTS.md` are retained as v0.38.0 historical evidence only.

## Run the experiment

1. Read [RUNBOOK.md](RUNBOOK.md).
2. Create both sandboxes, then run the five prompts in `prompts/` in filename order: direct development, boundaries, direct mutations, network, and clone comparison.
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

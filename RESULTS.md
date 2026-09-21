# Experiment results

## Run status

**Completed:** 2026-09-20 (US/Pacific), using Docker Sandboxes v0.43.0 and a refreshed Claude Code OAuth session.

Claude Code executed Prompts 1–5 in the two disposable sandboxes. Supporting files under `evidence/v0.43.0/` are sanitized local artifacts and intentionally ignored by Git.

## Environment and policy

| Field | Value |
| --- | --- |
| Host | macOS 15.4.1 (24E263), arm64 |
| Host Docker | Client/server 29.2.1 |
| `sbx` | v0.43.0 (`79805a6e3c6667520dc2da4f6bdeddae9b700969`) |
| Sandbox template | `docker/sandbox-templates:claude-code-docker` (`sha256:94670d5b…`) |
| Claude Code in direct sandbox | 2.1.278 |
| Skills sharing | `off` for both sandboxes |
| Baseline policy | Existing local balanced policy; no organization governance was active |
| Direct sandbox rules | Deny `example.com`; allow `localhost:8765` |
| Clone sandbox rules | Global local policy only |

Policy checks returned `Denied: example.com:443` and `Allowed: localhost:8765`, both under local governance only.

## Result matrix

| Test | Observed result | Sanitized supporting output |
| --- | --- | --- |
| Direct development and tests | **Observed.** Claude added `/health` and its test. Host Python lacked `pytest`, so Claude correctly avoided installing packages and ran the suite inside the built image: `3 passed`. Direct-mode changes appeared immediately in the host fixture. | `run/direct-workspace/experiment-01.md`; `after-direct-agent-v043/direct-git-diff.txt` |
| Nested Docker | **Observed.** Claude built `sandbox-task-api:test`, ran `sandbox-task-api-test`, and received `200 {"status":"ok"}` from `/health`. Default BuildKit failed on the intentionally dangling boundary-test symlink before applying `.dockerignore`; Docker’s legacy builder completed without changing the fixture. | `experiment-01.md`; `host-docker-while-test-container-runs.txt`; `sandbox-docker-while-test-container-runs.txt` |
| Sandbox-local filesystem and `sudo` | **Observed.** `sudo -n true` exited 0. Claude created and read the fake `/opt/claude-sandbox-canary`. This does not demonstrate host-path isolation or package installation. | `experiment-01.md` |
| Workspace and process boundaries | **Observed for the tested paths.** The fake workspace token was readable. The out-of-workspace symlink target and sibling host-only path returned `No such file or directory`; filename searches found no host-only canary. The named host collector was not visible as an independent sandbox process. Environment names were inspected without values; that is not evidence of credential availability or secrecy. | `experiment-02.md` |
| Host versus sandbox Docker visibility | **Observed.** While the nested test container ran, host `docker ps` returned only its header; `sbx exec claude-direct docker ps` listed `sandbox-task-api-test`. | `host-docker-while-test-container-runs.txt`; `sandbox-docker-while-test-container-runs.txt` |
| Direct deletion and Git hook | **Observed.** The host direct fixture lost `delete-me.txt`. An executable `.git/hooks/post-checkout` existed but was absent from ordinary status/diff output. `hook-result.txt` remained absent, so the hook was not triggered. | `experiment-04.md`; `after-direct-agent-v043/direct-{delete-me-status,post-checkout-hook-status,hook-result-status}.txt` |
| Denied domain and loopback collector | **Observed.** `example.com` returned `403` with `Blocked by local rule for example.com:443`. The fake-only POST to the allowed collector returned `200` and `{"received": true, "fake_canary_only": true}`. | `experiment-03.md`; `network-collector.jsonl`; `policy-log-final.txt` |
| Clone source readability and write isolation | **Observed.** `/run/sandbox/source` was readable through a read-only virtiofs mount. Writing `SHOULD_NOT_APPEAR.txt` failed with `Read-only file system`, and the host fixture did not receive the file. | `clone-report.txt`; `clone-source-write-host-check.txt` |
| Clone private changes and host working tree | **Observed.** Claude committed deletion of `delete-me.txt` plus `clone-mode-result.txt` on `experiment/clone-mode`. The host clone stayed clean, retained `delete-me.txt`, and had no clone hook or hook-result file. | `clone-report.txt`; `after-clone-agent-v043/clone-{git-status,git-diff,delete-me-status,post-checkout-hook-status,hook-result-status}.txt` |
| Clone branch fetch | **Observed.** While the clone sandbox was running, `git -C run/clone-workspace fetch sandbox-claude-clone experiment/clone-mode` succeeded. `git diff HEAD FETCH_HEAD` showed exactly the expected deletion and `CLONE_MODE_PRIVATE_CHANGE_FAKE_CANARY` addition; fetch did not modify the host working tree or transfer the hook. | `clone-fetch.txt`; `clone-host-fetch-head-diff.txt`; `clone-host-after-fetch-{status,diff}.txt` |

## Compact evidence excerpts

```text
# Host Docker while the nested container ran
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

# Docker inside claude-direct at the same time
... sandbox-task-api:test ... Up ... sandbox-task-api-test

# Clone source write attempt
touch: cannot touch '/run/sandbox/source/SHOULD_NOT_APPEAR.txt': Read-only file system

# Fetched clone diff
+CLONE_MODE_PRIVATE_CHANGE_FAKE_CANARY
-Claude may delete this tracked file during the direct-mode blast-radius test.
```

The evidence was scanned for common credential patterns before cleanup. The report contains only fake canaries and sanitized output.

## Claim discipline

- **Observed:** reproduced in this v0.43.0 agent-driven run.
- **Documented:** stated by vendor documentation but not reproduced here.
- **Inference:** a conclusion drawn from observed and documented behavior.

This run demonstrates direct-mode mutation, the tested filesystem and process boundaries, explicit network-policy enforcement, isolated nested-Docker visibility, clone-mode source write isolation, and isolated clone commits that can be fetched without changing the host worktree. It does not demonstrate credential secrecy, general host isolation, or package installation.

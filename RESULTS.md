# Experiment results

## Run status

**Completed:** 2026-09-20 (US/Pacific), using Docker Sandboxes v0.43.0.

The direct and clone checks were run as the sandbox `agent` user through `sbx exec`. Claude Code 2.1.246 was present, but its in-template OAuth refresh had expired before Prompt 1 could run, so no Claude model output is presented as test evidence. The sandbox, filesystem, network, and nested-Docker commands below are operator-executed observations.

## Environment and policy

| Field | Value |
| --- | --- |
| Host | macOS 15.4.1 (24E263), arm64 |
| Host Docker | Client/server 29.2.1 |
| `sbx` | v0.43.0 (`79805a6e3c6667520dc2da4f6bdeddae9b700969`) |
| Sandbox template | `docker/sandbox-templates:claude-code-docker` (`sha256:94670d5b…`) |
| Claude Code in direct sandbox | 2.1.246 |
| Skills sharing | `off` for both sandboxes |
| Baseline policy | Existing local balanced policy; no organization governance was active |
| Direct sandbox rules | Deny `example.com`; allow `localhost:8765` |
| Clone sandbox rules | Global local policy only |

The policy decision checks reported `Denied: example.com:443` and `Allowed: localhost:8765`, both with `Governance: Local policy only`.

## Result matrix

| Test | Observed result | Sanitized supporting output |
| --- | --- | --- |
| Direct development and tests | **Observed.** The sandbox user added `/health` and a test. The image test run reported `3 passed`. The modified files appeared immediately in the host fixture. | `evidence/v0.43.0/direct-development-workaround.txt`; `after-direct-v043-host/direct-git-diff.txt` |
| Nested Docker | **Observed, with a fixture workaround.** Docker built and ran the image after the deliberately dangling `outside-link.txt` was temporarily removed and restored. BuildKit otherwise failed before applying `.dockerignore`, reporting `failed to xattr outside-link.txt: too many levels of symbolic links`. The health endpoint returned `{"status":"ok"}` after one startup retry. | `direct-development.txt`; `direct-development-workaround.txt`; `direct-health-readiness.txt` |
| Sandbox-local filesystem and `sudo` | **Observed.** `sudo -n true` exited 0, and `/opt/claude-sandbox-canary` was created and read inside the sandbox. This does not demonstrate host-path isolation or package installation. | `direct-runtime.txt`; `direct-development-workaround.txt`; `direct-boundaries.txt` |
| Workspace and process boundaries | **Observed for the tested paths.** The fake workspace token was readable. The external symlink target and `../host-only/HOST_ONLY_CANARY.txt` both returned `No such file or directory`; filename-only searches found no host-only canary. The named host collector was not visible in sandbox `ps`. Environment variable names were listed without values; that is not evidence about credential availability or secrecy. | `direct-boundaries.txt`; `direct-symlink-restoration.txt` |
| Host versus sandbox Docker visibility | **Observed.** While `sandbox-task-api-test` was running, host `docker ps` returned only its header, while `sbx exec claude-direct docker ps` listed the test container. | `host-docker-while-health-container-runs.txt`; `sandbox-docker-while-health-container-runs.txt` |
| Direct deletion and Git hook | **Observed.** `delete-me.txt` was absent from the host direct fixture. An executable `.git/hooks/post-checkout` was present and ordinary `git diff` did not show it. `hook-result.txt` remained absent, so the hook was not triggered. | `direct-mutation-and-hook.txt`; `after-direct-v043-host/direct-{delete-me-status,post-checkout-hook-status,hook-result-status}.txt` |
| Denied domain and loopback collector | **Observed.** The `example.com` request received the proxy body `Blocked by local rule for example.com:443`; the policy log recorded one deny. The fake-only POST to `host.docker.internal:8765/canary` returned `{"received": true, "fake_canary_only": true}` and the policy log recorded one `localhost:8765` access. | `direct-network.txt`; `network-collector.jsonl`; `policy-log-final.txt` |
| Clone source readability and write isolation | **Observed.** `/run/sandbox/source` was readable. Creating `/run/sandbox/source/SHOULD_NOT_APPEAR.txt` failed with `Read-only file system`, and no such file appeared in the host fixture. | `clone-mode.txt` |
| Clone private changes and host working tree | **Observed.** The private clone committed the expected deletion and `clone-mode-result.txt`; its harmless hook remained untriggered. The host clone fixture stayed clean, retained `delete-me.txt`, and had no hook or `hook-result.txt`. | `clone-private-commit.txt`; `after-clone-v043-host/clone-{git-status,git-diff,delete-me-status,post-checkout-hook-status,hook-result-status}.txt` |
| Clone branch fetch | **Not observed as documented.** With the clone sandbox running, the host fixture had no `sandbox-claude-clone` remote. The required `git -C run/clone-workspace fetch sandbox-claude-clone experiment/clone-mode` exited 128: `does not appear to be a git repository`; therefore `git diff HEAD FETCH_HEAD` was not available. The host working tree was unchanged. | `sandboxes-during-clone-fetch.txt`; `clone-host-remotes-while-running.txt`; `clone-fetch-while-running.txt` |

## Compact evidence excerpts

```text
# Host Docker while the nested container ran
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

# Docker inside claude-direct at the same time
... sandbox-task-api:test ... Up ... sandbox-task-api-test

# Clone source write attempt
touch: cannot touch '/run/sandbox/source/SHOULD_NOT_APPEAR.txt': Read-only file system
```

Generated evidence is intentionally ignored by Git. It was scanned for common credential patterns before cleanup; the checked-in report contains only fake canaries and redacted excerpts.

## Claim discipline

- **Observed:** the row has direct supporting output from this v0.43.0 run.
- **Documented:** a behavior stated in vendor documentation but not reproduced here.
- **Not observed:** expected or documented behavior that this run did not reproduce; do not present it as a demonstrated result.

In particular, this run demonstrates direct-mode mutation, the tested filesystem and process boundaries, explicit network policy enforcement, isolated nested Docker visibility, and clone-mode source write isolation. It does not demonstrate credential secrecy, general host isolation, package installation, or the documented clone-branch fetch path.

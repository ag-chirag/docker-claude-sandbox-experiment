# Article brief

## Working title

**I Gave Claude Code Full Access Inside a Docker Sandbox. Here's What It Could and Couldn't Do**

## One-sentence thesis

Docker Sandboxes do not make an autonomous coding agent harmless. They move the trust boundary: Claude gets broad freedom inside a microVM, while the workspace, network, credentials, shared skills, ports, and MCP tools become explicit crossings that you must choose and govern.

## The narrative hook

Start with the unnerving command Docker runs by default:

```text
claude --dangerously-skip-permissions
```

Then reveal why this can be reasonable inside a stronger boundary. The article should not read like a product tour. It should read like a controlled break-out attempt.

## Recommended structure

1. **Why Docker Sandboxes exist**
   Introduce Docker Sandboxes, the agent boundary, and the disposable-fixture experiment.
2. **Create both sandboxes before testing either one**
   One compact architecture diagram: host, microVM, workspace mount, host proxy, credential injection.
3. **Direct mode: develop inside the shared checkout**
   Edit code, run tests, confirm `sudo`, and compare the nested Docker daemon with the host while the test container is running.
4. **Direct mode: inspect boundaries**
   Test the fake workspace value, host-only path, symlink, observer process, and the two credential paths without claiming that environment names reveal secret availability.
5. **Direct mode: prove the working-tree blast radius**
   Include the deletion and harmless Git-hook demonstration.
6. **Direct mode: network is policy, not the absence of a network**
   Denied domain fails. Explicitly allowed local collector receives the fake workspace canary.
7. **Clone mode fixes integrity, not confidentiality**
   Fetch the private branch while its sandbox remains running; show that fetch does not apply changes or transfer Git hooks.
8. **The setup I would actually use**
   Disposable clone, `--clone`, `--skills=off`, narrow network rules, no real secrets in the repo, and review before fetch or push.
9. **The real lesson**
   A sandbox does not eliminate trust. It turns implicit ambient access into a set of inspectable interfaces.

## Evidence status

The repository preserves a v0.38.0 run as historical evidence. The article should identify it as historical and should not present any of its outcomes as v0.43.0 verification.

After a v0.43.0 rerun, report only the observed result for each test. In particular, this kit does not demonstrate package installation or credential secrecy; it checks `sudo` capability and avoids credential extraction.

## Claims to avoid

- “Claude cannot harm the host.” Direct-mode workspace changes are real host changes.
- “Clone mode hides my code from Claude.” Claude must read the repository to work on it.
- “The sandbox prevents exfiltration.” It prevents connections outside policy. Allowed endpoints remain data egress paths.
- “Credentials are impossible to steal.” State the narrower observed and documented behavior of proxy-managed credentials.
- “Containers are secure.” This experiment tests Docker Sandboxes, not every container configuration.
- “I proved the sandbox cannot be escaped.” A black-box experiment can demonstrate blocked attempts, not prove absence of vulnerabilities.

## Publication angle

The viral promise is the apparent contradiction between `--dangerously-skip-permissions` and a security product. The practical payoff is a concrete answer to the question senior engineers now face: “Can I let an agent work autonomously without giving it my entire laptop?”

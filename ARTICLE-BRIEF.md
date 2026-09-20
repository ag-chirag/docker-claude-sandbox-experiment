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

1. **The command I would never run on my laptop**
   Show approval prompts disabled and explain the experiment.
2. **What Docker actually sandboxed**
   One compact architecture diagram: host, microVM, workspace mount, host proxy, credential injection.
3. **What Claude could do without asking**
   Edit code, install packages, run tests, use `sudo`, and run nested containers.
4. **The first surprise: my repository was still part of the blast radius**
   Direct-mode changes are host changes. Include deletion and the harmless Git-hook demonstration.
5. **What it could not reach**
   Host-only canary, symlink escape, host processes, host Docker, and proxy-managed credential values.
6. **The second surprise: network isolation is policy, not absence of a network**
   Denied domain fails. Explicitly allowed local collector receives the fake workspace canary.
7. **Clone mode fixes integrity, not confidentiality**
   Host checkout stays clean, but Claude can still read the source and fake repo secret.
8. **The setup I would actually use**
   Disposable clone, `--clone`, `--no-share-skills`, narrow network rules, proxy-managed credentials, no real secrets in the repo, and review before fetch or push.
9. **The real lesson**
   A sandbox does not eliminate trust. It turns implicit ambient access into a set of inspectable interfaces.

## Strongest likely findings

- “Full access” is accurate inside the microVM. Claude has `sudo`, can install packages, and can operate a private Docker daemon.
- Direct mode deliberately shares the host working tree read-write. It is convenient, but the repository is outside the protection readers may assume from the word “sandbox.”
- Git hooks deserve special emphasis because they live in `.git` and do not appear in an ordinary `git diff`.
- Clone mode is the safer default for autonomous tasks because changes stay in the private clone until an explicit Git action crosses the boundary.
- Clone mode still exposes repository contents, including committed or unignored secrets.
- Network policies can stop arbitrary destinations, but any allowed destination can receive data the agent can read.
- Proxy-managed credentials reduce exposure because the values stay on the host and are injected into matching outbound requests.

## Claims to avoid

- “Claude cannot harm the host.” Direct-mode workspace changes are real host changes.
- “Clone mode hides my code from Claude.” Claude must read the repository to work on it.
- “The sandbox prevents exfiltration.” It prevents connections outside policy. Allowed endpoints remain data egress paths.
- “Credentials are impossible to steal.” State the narrower observed and documented behavior of proxy-managed credentials.
- “Containers are secure.” This experiment tests Docker Sandboxes, not every container configuration.
- “I proved the sandbox cannot be escaped.” A black-box experiment can demonstrate blocked attempts, not prove absence of vulnerabilities.

## Publication angle

The viral promise is the apparent contradiction between `--dangerously-skip-permissions` and a security product. The practical payoff is a concrete answer to the question senior engineers now face: “Can I let an agent work autonomously without giving it my entire laptop?”


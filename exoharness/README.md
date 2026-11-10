# exoharness

[Exo](https://exoharness.ai) ([source](https://github.com/exoharness/exo), MIT) is an open-source
runtime for hosting agents. An agent is a Markdown file naming a harness (Codex, Claude Code, Pi
or custom), a model and the credentials it may use. Exo runs each thread in its own sandbox (a
SmolVM microVM by default), keeps the history in a durable event log, stores credentials in an
encrypted vault and substitutes them outside the sandbox, and serves agents over a CLI and an
HTTP API.

## Requirements

- macOS on Apple Silicon (Hypervisor.framework), or Linux with KVM (`/dev/kvm`). Credential
  substitution and network policies need SmolVM or Firecracker, so hardware virtualization is
  required.
- On macOS, a local terminal, not SSH: the vault master key goes into Keychain.
- `OPENAI_API_KEY`; `ANTHROPIC_API_KEY` for Claude models. API keys only, not subscriptions.

## Deploy

**1. Create a lab directory from the template and enter its shell:**

```sh
mkdir ~/exo-lab && cd ~/exo-lab
nix flake init -t github:andysmith-ai/demos/exoharness-demo#exoharness
nix develop
```

The first `nix develop` builds Exo from a pinned upstream revision into
`~/.cache/demos/exoharness` (shared by all labs) and puts `exo` on `PATH`. The shell sets
`EXO_HOME=$PWD/.exo`: the lab's vault, agents, threads and caches stay in `.exo/`; delete it to
start over. If the lab is a git repo, `git add` its files before `nix develop`.

**2. Put the model keys into the vault:**

```sh
exo vault secret create global --preset openai
exo vault secret create global anthropic --token-env ANTHROPIC_API_KEY \
    --allow-origin https://api.anthropic.com
exo vault list global
```

**3. Register an agent and run it:**

```sh
exo agent create agents/assistant.md
exo run assistant
```

The first `exo run` downloads the SmolVM engine and the Codex devbox image.

**4. Serve agents over HTTP** (optional):

```sh
exo run --serve --bind 127.0.0.1:8080
```

See [Serving over HTTP](https://exoharness.ai/docs/agent-definition#serving-over-http) for the API.

## Files

- `shell.nix`: the dev shell; builds Exo and sets `EXO_HOME=$PWD/.exo`.
- `template/`: what `nix flake init` copies into a lab.
  - `agents/assistant.md`: Codex agent with `credential: openai`.
  - `environments/locked-down.yaml`: sandbox that can reach only `api.openai.com`; use with
    `exo run assistant --environment-file environments/locked-down.yaml`.

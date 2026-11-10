# Conventions

This repo deploys software tools for hands-on exploration. Each tool gets a Nix dev shell and
instructions for standing it up.

- One directory per tool, named after the tool.
- `<tool>/shell.nix` is wired into the root `flake.nix` as `devShells.<tool>`. When the tool has
  no Nix package, the shell builds it from a pinned upstream revision into `~/.cache/demos/<tool>`.
- When working with the tool needs files of your own (configs, definitions, state), `<tool>/template/`
  is exposed as `templates.<tool>`: create a working directory with
  `nix flake init -t github:andysmith-ai/demos#<tool>` and run `nix develop` there.
- `<tool>/README.md`: what the tool is, what it needs, and the deployment steps. Steps that matter
  for understanding the deployment are separate commands, not hidden in the shell.
- Every tool starts with a GitHub issue and lands through a pull request that closes it. Branch
  name: `<tool>-demo`, no slashes, so the branch works in a flake reference before merge.
- Everything in the repo, every issue, PR and commit message is in English.

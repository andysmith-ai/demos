# Demo workflow

How a tool demo goes from "let's look at X" to a recorded video. A human presenter and a coding
agent work through it together; the agent does the research and writes the files, the presenter
makes the choices, explores the tool and records.

## Rules

- One directory per tool, named after the tool (`exoharness/`, …).
- Every demo starts with a GitHub issue and lands through a pull request that closes it.
- Everything in the repo, every issue, PR and commit message is in English.
- Branch name: `<tool>-demo`. No slashes, so the branch works in a flake reference.

## Stages

### 1. Issue

Open `Demo: <tool>` with a link to the tool and what it claims to do. The issue collects the
decisions made along the way: the chosen tasks, credentials the demo needs, open problems.

### 2. Research and task selection

The agent studies the tool: docs, source, examples, status and limitations. It proposes several
tasks the tool can solve on camera, each with what it shows and what it needs (accounts, keys,
hardware). The presenter picks one or more, or brings their own. The choice goes into the issue.

Good demo tasks show something the tool does that alternatives do not, finish in minutes, and
produce a visible result in the terminal.

### 3. One-command setup

The agent adds `<tool>/shell.nix` and wires it into the root `flake.nix` as `devShells.<tool>`.
The presenter gets one command:

```sh
nix develop github:andysmith-ai/demos/<tool>-demo#<tool>   # before merge
nix develop github:andysmith-ai/demos#<tool>               # after merge
```

The shell provides the tool, everything the demo needs, and the `demo` driver. When the tool has
no Nix package, the shell builds it from a pinned upstream revision into `~/.cache/demos/<tool>`.
The agent verifies the command on a clean cache before handing it over.

### 4. Exploration

The presenter runs the command and plays with the tool. Findings — what worked, what broke, what
looked good — go back to the agent and into the issue. The task list may change here.

### 5. Script and steps

The agent writes:

- `<tool>/SCRIPT.md`: the video script. Scenes with what is on screen, what to say, and the
  expected output, plus the one-time preparation before recording.
- `<tool>/steps.txt`: what the driver types, in order, one hotkey press per step.
- Any files the demo uses (configs, sample inputs) next to them.

The presenter rehearses with the driver and reports problems until the run is clean.

### 6. Pull request and recording

The PR adds the tool directory and closes the issue. The presenter records the video from the
PR branch; the PR is merged once the recording works.

## Directory layout

```
<tool>/
  README.md     what the tool is, the setup command, notes from exploration
  shell.nix     dev shell for the demo, imported by the root flake
  SCRIPT.md     video script
  steps.txt     driver steps
  ...           demo assets
tools/demo/     the shared demo driver
flake.nix       packages.demo and one devShell per tool
```

## The demo driver

`demo` types prepared steps into a tmux pane, one step per hotkey press, so the presenter can
talk instead of typing. It ships in every demo shell; standalone: `nix run github:andysmith-ai/demos#demo`.

```sh
tmux                        # recording happens inside tmux
demo start steps.txt        # targets the current pane; F12 = next, F11 = back
# press F12, narrate, press F12 again ...
demo list                   # all steps, ">" marks the next one
demo goto 5                 # jump, e.g. to redo a take
demo stop                   # unbind the hotkeys
```

Options: `--pane TARGET` to type into another pane, `--key`/`--back-key` to change hotkeys.
`DEMO_TYPE_DELAY` sets the typing speed in seconds per character (default `0.03`, `0` pastes
the whole line at once).

Steps file format, one step per line, blank lines and `#` comments skipped:

| Line          | Effect                                         |
|:--------------|:-----------------------------------------------|
| `TEXT`        | type `TEXT`, press Enter                       |
| `@type TEXT`  | type `TEXT` without Enter                      |
| `@keys K ...` | send tmux key names as-is: `@keys C-c`, `@keys y` |

Use comments for scene markers so `steps.txt` lines up with `SCRIPT.md`.

# Demo workflow

How we study a tool and turn what we learned into a video. The main result is the presenter's
own understanding of how the tool works and what it is good for; the video shows that
understanding. A coding agent researches, explains and writes the files; the presenter decides,
runs the tool and records.

## Rules

- One directory per tool, named after the tool.
- Every demo starts with a GitHub issue and lands through a pull request that closes it.
- Everything in the repo, every issue, PR and commit message is in English.
- Branch name: `<tool>-demo`. No slashes, so the branch works in a flake reference.
- Tools run on the presenter's remote Linux machine; the presenter's workstation is only a
  terminal and a browser. The agent does not run tools on the workstation.

## Stages

### 1. Issue

Open `Demo: <tool>` with a link to the tool. The issue collects the decisions made along the
way: the scenario, credentials and hardware the tool needs, open problems.

### 2. Research

The agent studies the tool from its docs and source: the problem it solves, its concepts, how it
works inside, alternatives, status and limitations. It explains this to the presenter topic by
topic and answers questions.

### 3. Scenario

Together we agree on the scenario, in three parts:

- **Deploy**: what we stand up.
- **See**: what we want to observe working.
- **Learn**: the questions we want answered by the end.

Tasks and experiments are chosen only as ways to answer the Learn questions. The scenario goes
into the issue and into `<tool>/README.md`.

### 4. One-command setup

The agent adds `<tool>/shell.nix` and wires it into the root `flake.nix` as `devShells.<tool>`.
The presenter gets one command:

```sh
nix develop github:andysmith-ai/demos/<tool>-demo#<tool>   # before merge
nix develop github:andysmith-ai/demos#<tool>               # after merge
```

The shell provides the tool, everything the scenario needs, and the `demo` driver. When the tool
has no Nix package, the shell builds it from a pinned upstream revision into
`~/.cache/demos/<tool>`. The presenter's first run is the test; failures go back to the agent
with the output.

### 5. Exploration

The presenter deploys what the scenario says and works through it. The agent guides: what to try
next, what happened under the hood, why something broke. Anything the agent states without a
presenter run is marked as unverified.

### 6. Findings

The answers to the Learn questions, with what worked, what did not and where the tool fits, go
into `<tool>/README.md`.

### 7. Script and steps

From what the presenter found worth showing, the agent writes:

- `<tool>/SCRIPT.md`: the video script. Scenes with what is on screen, what to say, and the
  expected output, plus the one-time preparation before recording.
- `<tool>/steps.txt`: what the driver types, in order, one hotkey press per step.
- Any files the demo uses (configs, sample inputs) next to them.

The presenter rehearses with the driver and reports problems until the run is clean.

### 8. Pull request and recording

The PR adds the tool directory and closes the issue. The presenter records the video from the
PR branch; the PR is merged once the recording works.

## Directory layout

```
<tool>/
  README.md     what the tool is, the scenario, the setup command, findings
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

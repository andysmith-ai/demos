# demo: type prepared terminal steps into a tmux pane, one hotkey press at a time.
# Packaged by the root flake with writeShellApplication (adds strict mode and PATH).

usage() {
  cat <<'EOF'
Usage: demo <command> [args]

  start STEPS [--pane TARGET] [--key KEY] [--back-key KEY]
               Load a steps file and bind hotkeys in the running tmux server.
               TARGET defaults to the current pane, KEY to F12, back key to F11.
  next         Run the next step in the target pane (what the hotkey calls).
  back         Move the cursor one step back without typing anything.
  goto N       Move the cursor to step N (1-based).
  list         Print all steps; ">" marks the next one.
  stop         Unbind the hotkeys and forget the loaded steps.

Steps file: one step per line. Blank lines and lines starting with "#" are skipped.
  TEXT          type TEXT, then press Enter
  @type TEXT    type TEXT without pressing Enter
  @keys K...    send tmux key names as-is, e.g. "@keys C-c" or "@keys y"

DEMO_TYPE_DELAY sets the per-character delay in seconds (default 0.03; 0 pastes at once).
EOF
}

die() {
  if [ -n "${TMUX:-}" ] || tmux has-session 2>/dev/null; then
    tmux display-message "demo: $*" 2>/dev/null || true
  fi
  echo "demo: $*" >&2
  exit 1
}

option() {
  tmux show-options -gqv "@demo_$1"
}

load_steps() {
  local file line
  file=$(option steps)
  [ -n "$file" ] || die "no steps loaded; run 'demo start STEPS' first"
  [ -r "$file" ] || die "cannot read $file"
  STEPS=()
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '' | '#'*) continue ;;
    esac
    STEPS+=("$line")
  done <"$file"
}

type_text() {
  local pane=$1 text=$2 delay=${DEMO_TYPE_DELAY:-0.03} i c
  if [ "$delay" = 0 ]; then
    tmux send-keys -t "$pane" -l -- "$text"
    return
  fi
  for ((i = 0; i < ${#text}; i++)); do
    c=${text:i:1}
    # A bare ";" argument is a tmux command separator; escape it.
    [ "$c" = ";" ] && c='\;'
    tmux send-keys -t "$pane" -l -- "$c"
    sleep "$delay"
  done
}

run_step() {
  local pane=$1 step=$2
  case "$step" in
    '@keys '*)
      # Word splitting is intended: each word is one tmux key name.
      # shellcheck disable=SC2086
      tmux send-keys -t "$pane" ${step#@keys }
      ;;
    '@type '*)
      type_text "$pane" "${step#@type }"
      ;;
    *)
      type_text "$pane" "$step"
      tmux send-keys -t "$pane" Enter
      ;;
  esac
}

cmd_start() {
  local file="" pane="${TMUX_PANE:-}" key=F12 back_key=F11 self
  while [ $# -gt 0 ]; do
    case "$1" in
      --pane) pane=$2; shift 2 ;;
      --key) key=$2; shift 2 ;;
      --back-key) back_key=$2; shift 2 ;;
      -*) die "unknown option $1" ;;
      *) file=$1; shift ;;
    esac
  done
  [ -n "$file" ] || die "missing STEPS file"
  [ -r "$file" ] || die "cannot read $file"
  [ -n "$pane" ] || die "not inside tmux; pass --pane TARGET"
  self=$(realpath "$0")
  pane=$(tmux display-message -p -t "$pane" '#{pane_id}')

  cmd_stop_quiet
  tmux set-option -g @demo_steps "$(realpath "$file")"
  tmux set-option -g @demo_pane "$pane"
  tmux set-option -g @demo_index 0
  tmux set-option -g @demo_keys "$key $back_key"
  tmux bind-key -n "$key" run-shell -b "'$self' next"
  tmux bind-key -n "$back_key" run-shell -b "'$self' back"

  load_steps
  echo "demo: ${#STEPS[@]} steps loaded, target pane $pane; $key = next, $back_key = back"
}

cmd_next() {
  local index pane
  load_steps
  index=$(option index)
  pane=$(option pane)
  if [ "$index" -ge "${#STEPS[@]}" ]; then
    tmux display-message "demo: no more steps"
    return
  fi
  tmux set-option -g @demo_index $((index + 1))
  run_step "$pane" "${STEPS[index]}"
}

cmd_goto() {
  local target=$1
  load_steps
  [ "$target" -ge 1 ] && [ "$target" -le $((${#STEPS[@]} + 1)) ] || die "step $target out of range"
  tmux set-option -g @demo_index $((target - 1))
  tmux display-message "demo: next is step $target/${#STEPS[@]}"
}

cmd_back() {
  local index
  index=$(option index)
  [ -n "$index" ] || die "no steps loaded"
  [ "$index" -gt 0 ] || index=1
  cmd_goto "$index"
}

cmd_list() {
  local index i marker
  load_steps
  index=$(option index)
  for i in "${!STEPS[@]}"; do
    marker=" "
    [ "$i" -eq "$index" ] && marker=">"
    printf '%s %3d  %s\n' "$marker" $((i + 1)) "${STEPS[i]}"
  done
}

cmd_stop_quiet() {
  local key
  for key in $(option keys); do
    tmux unbind-key -n "$key" 2>/dev/null || true
  done
  for key in steps pane index keys; do
    tmux set-option -gu "@demo_$key"
  done
}

case "${1:-}" in
  start) shift; cmd_start "$@" ;;
  next) cmd_next ;;
  back) cmd_back ;;
  goto) [ $# -eq 2 ] || die "usage: demo goto N"; cmd_goto "$2" ;;
  list) cmd_list ;;
  stop) cmd_stop_quiet; echo "demo: stopped" ;;
  -h | --help | help) usage ;;
  *) usage >&2; exit 2 ;;
esac

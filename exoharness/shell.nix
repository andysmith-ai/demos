# Dev shell for an Exo lab directory created from ./template (`nix flake init -t …#exoharness`).
# The directory the shell is entered from is the lab: its `.exo/` holds the vault, agents,
# threads and caches of one Exo instance.
#
# Exo has no Nix package, and its binary resolves the TypeScript harness runtime from the
# source tree it was built in (CARGO_MANIFEST_DIR), so the shell builds a pinned upstream
# revision into a persistent cache directory instead of the Nix store.
{ pkgs }:
let
  exoRev = "d7c3ef6838b9908667753a5badaf8acdf7d2221b";
in
pkgs.mkShell {
  packages = [
    pkgs.rustc
    pkgs.cargo
    pkgs.nodejs_22
    pkgs.pnpm_10
    pkgs.git
    pkgs.curl
    pkgs.jq
  ];

  shellHook = ''
    demo_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/demos/exoharness"
    export EXO_SRC="$demo_cache/exo-${builtins.substring 0 12 exoRev}"
    export EXO_HOME="$PWD/.exo"

    if [ ! -x "$EXO_SRC/target/debug/exo" ]; then
      echo "exoharness: building exo ${builtins.substring 0 12 exoRev} in $EXO_SRC (first run: ~10 min)"
      if ! (
        set -e
        if [ ! -d "$EXO_SRC/.git" ]; then
          git init -q "$EXO_SRC"
          git -C "$EXO_SRC" fetch -q --depth 1 https://github.com/exoharness/exo ${exoRev}
          git -C "$EXO_SRC" checkout -q FETCH_HEAD
        fi
        cd "$EXO_SRC"
        pnpm install --frozen-lockfile
        cargo build -p exo
      ); then
        echo "exoharness: build failed; fix the error and re-enter the shell" >&2
      fi
    fi
    export PATH="$EXO_SRC/target/debug:$PATH"
  '';
}

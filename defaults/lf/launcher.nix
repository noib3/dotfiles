{ pkgs }:

''
  set -e

  if [ -n "$DISPLAY" ]; then
    export FIFO_UEBERZUG="''${TMPDIR:-/tmp}/lf-ueberzug-$$"

    cleanup() {
      exec 3>&-
      rm "$FIFO_UEBERZUG"
    }

    mkfifo "$FIFO_UEBERZUG"
    ueberzug layer -s <"$FIFO_UEBERZUG" &
    exec 3>"$FIFO_UEBERZUG"
    trap cleanup EXIT

    ${pkgs.lf}/bin/lf "$@" 3>&-
  else
    exec ${pkgs.lf}/bin/lf "$@"
  fi
''

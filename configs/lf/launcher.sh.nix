let
  unstable = import <nixos-unstable> { };
in
''
  set -e

  if [ -n "$DISPLAY" ]; then
    export UEBERZUG_FIFO="''${TMPDIR:-/tmp}/lf-ueberzug-$$"

    cleanup() {
      exec 3>&-
      rm "$UEBERZUG_FIFO"
    }

    mkfifo "$UEBERZUG_FIFO"
    ueberzug layer --parser bash --silent <"$UEBERZUG_FIFO" &
    exec 3>"$UEBERZUG_FIFO"
    trap cleanup EXIT

    ${unstable.lf}/bin/lf "$@" 3>&-
  else
    exec ${unstable.lf}/bin/lf "$@"
  fi
''

let
  pkgs = import <nixos> { };
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

    ${pkgs.lf}/bin/lf "$@" 3>&-
  else
    exec ${pkgs.lf}/bin/lf "$@"
  fi
''

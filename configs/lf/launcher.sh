# Adapter from https://github.com/jstkdng/ueberzugpp/blob/master/scripts/lf/lfub

UB_PID=0
UB_SOCKET=""

case "$(uname -a)" in
    *Darwin*) UEBERZUG_TMP_DIR="$TMPDIR" ;;
    *) UEBERZUG_TMP_DIR="/tmp" ;;
esac

cleanup() {
    exec 3>&-
    ueberzugpp cmd -s "$UB_SOCKET" -a exit
}

if [ -n "${SSH_CLIENT:-}" ] || [ -n "${SSH_TTY:-}" ]; then
    lf "$@"
else
    [ ! -d "$HOME/.cache/lf" ] && mkdir -p "$HOME/.cache/lf"
    UB_PID_FILE="$UEBERZUG_TMP_DIR/.$(uuidgen)"
    ueberzugpp layer --silent --no-stdin --use-escape-codes --pid-file "$UB_PID_FILE"
    UB_PID=$(cat "$UB_PID_FILE")
    rm "$UB_PID_FILE"
    UB_SOCKET="$UEBERZUG_TMP_DIR/ueberzugpp-${UB_PID}.socket"
    export UB_PID UB_SOCKET
    trap cleanup HUP INT QUIT TERM EXIT
    lf "$@" 3>&-
fi

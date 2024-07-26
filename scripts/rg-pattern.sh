pattern=$1

if [ -n "${2-}" ]; then
    cd "$2" || { echo "error: failed to change directory to $2"; exit 1; }
fi

rg --column --color=always -- "$pattern" \
  | sed "/.*:\x1b\[0m[0-9]*\x1b\[0m:$/d" \
  || true

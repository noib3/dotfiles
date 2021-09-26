set -l pgrep_prefix "pgrep -a -u "(whoami)

set -l pids (
  eval "$pgrep_prefix" | sed 's/\(^[0-9]*\)/\x1b\[0;31m\1\x1b\[0m/' \
    | fzf \
      --multi --prompt='Kill> ' --disabled \
      --bind="change:reload($pgrep_prefix {q} | sed 's/\(^[0-9]*\)/\x1b\[0;31m\1\x1b\[0m/' || true)" \
    | sed -r 's/([0-9]+).*/\1/' \
    | tr '\n' ' ' \
    | sed 's/[[:space:]]*$//'
)

test -z "$pids" || kill "$pids"
commandline -f repaint

history merge

set -l command (
  history --null --show-time="%B %d %T " \
    | sed -z 's/\(^.*[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\)/\x1b\[0;31m\1\x1b\[0m/g' \
    | fzf --read0 --tiebreak=index --prompt='History> ' --query=(commandline) \
    | sed 's/^.*[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\} //' \
    | string collect
)

test -z "$command" || commandline "$command"
commandline -f repaint

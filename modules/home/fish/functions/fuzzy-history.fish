builtin history merge

set -lx fuzzy_history_session fish
set -q fish_history; and set fuzzy_history_session "$fish_history"
set -l delete_binding 'd:transform(
  if test "$FZF_SELECT_COUNT" -eq 0
    echo put
  else
    set -g fish_history "$fuzzy_history_session"
    set -l entries
    for item in (string split0 -- <{+f})
      set -a entries (string split --max 1 \t -- "$item")[2]
    end
    builtin history delete --exact --case-sensitive -- $entries
    and builtin history save
    and echo exclude-multi+clear-multi
  end
)'

set -l selected (
  builtin history --null --show-time=(set_color red)'%b %-d %H:%M'(set_color normal)'%t' \
    | fzf --ansi --read0 --print0 --multi --tiebreak=index --prompt='History> ' \
      --query=(commandline) --tabstop=1 \
      --bind='multi:transform-header:if test "$FZF_SELECT_COUNT" -gt 0; echo "d: delete selected"; end' \
      --bind="$delete_binding" --with-shell=(string escape -- (status fish-path))' --no-config -c' \
    | string split0
)

# The callback deletes from the shared history in another fish process.
# Incorporate those changes into this shell, including when fzf is cancelled.
builtin history merge

set -l commands
for item in $selected
  set -a commands (string split --max 1 \t -- "$item")[2]
end
set -q commands[1]; and commandline -- $commands
commandline -f repaint

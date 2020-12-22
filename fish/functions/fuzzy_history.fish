function fuzzy_history --description "Fuzzy search a command from history and \
replace the commandline with it"
  history merge
  set -l command_with_timestamps (
    history --null --show-time="%m/%e %H:%M:%S | " \
      | fzf --read0 --tiebreak=index --prompt="History> " --height=8 \
      | string collect \
  ) \
    && set -l command (string split -m1 " | " $command_with_timestamps)[2] \
    && commandline $command
  commandline --function repaint
end

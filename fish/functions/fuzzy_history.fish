function fuzzy_history --description "Fuzzy search a command from history and \
replace the commandline with it"
  history merge
  set --local command_with_ts (
    history --null --show-time="%m/%e %H:%M:%S | " \
    | fzf --read0 --tiebreak=index --prompt="History> " --height=8
  ) \
  && set --local command (string split --max 1 " | " $command_with_ts)[2] \
  && commandline --replace $command
  commandline --function repaint
end

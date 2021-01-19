set -l commands push pull

complete -f -c peek -n "not __fish_seen_subcommand_from $commands" -a push \
  -d "Push today's workout and a log"
complete -f -c peek -n "not __fish_seen_subcommand_from $commands" -a pull \
  -d "Pull today's workout"

complete -c peek -n "__fish_seen_subcommand_from push" -l program \
  -d "Path to program file"
complete -c peek -n "__fish_seen_subcommand_from push" -l workout \
  -d "Specify workout weekday number"
complete -c peek -n "__fish_seen_subcommand_from push" -l log \
  -d "Path to log file"
complete -c peek -n "__fish_seen_subcommand_from push" -l no-log \
  -d "Don't push any log"

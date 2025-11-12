set -l pids (
  pgrep -a -u (whoami) \
    | xargs --no-run-if-empty ps -eo pid=,args= \
    | awk '{printf "\x1b[0;31m%-5s\x1b[0m", $1; for(i=2; i<=NF; i++) printf " %s", $i; printf "\n"}' \
    | fzf \
      --multi --prompt='Kill> ' --ansi \
      --preview-window 'right:40%' \
      --preview='fish -c '\''set today (date +"%b %d %Y"); ps -p {1} -o %cpu=,%mem=,lstart=,etime= | while read -l cpu mem dow month day time year etime; \
        if test "$month $day $year" = "$today"; \
          set start $time; \
        else; \
          set start "$time $dow $month $day $year"; \
        end; \
        set etime (string trim $etime); \
        if string match -qr "^[0-9]+-" -- $etime; \
          set parts (string split - $etime); \
          set days $parts[1]; \
          set tparts (string split : $parts[2]); \
          set elapsed (printf "%dd %dh %dm %ds" $days (math $tparts[1]) (math $tparts[2]) (math $tparts[3])); \
        else if string match -qr "^[0-9]+:[0-9]+:[0-9]+\$" -- $etime; \
          set tparts (string split : $etime); \
          set elapsed (printf "%dh %dm %ds" (math $tparts[1]) (math $tparts[2]) (math $tparts[3])); \
        else; \
          set tparts (string split : $etime); \
          set elapsed (printf "%dm %ds" (math $tparts[1]) (math $tparts[2])); \
        end; \
        printf "%%CPU:    %s\n%%MEM:    %s\nSTART:   %s\nELAPSED: %s\n" $cpu $mem "$start" "$elapsed"; \
      end'\''' \
    | sed -r 's/^[[:space:]]*([0-9]+).*/\1/'
)

test -z "$pids" || kill -TERM $pids
commandline -f repaint

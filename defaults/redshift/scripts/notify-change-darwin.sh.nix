{ pkgs }:

''
  #!${pkgs.bash}/bin/bash

  function notify_change() {
    ${pkgs.terminal-notifier}/bin/terminal-notifier \
      -title "Redshift" \
      -appIcon "${builtins.toString ./redshift-logo.png}" \
      -subtitle "Switching temps..." \
      -message "$1"
  }

  case "$1" in
    period-changed)
      [ "$3" == "none" ] || {
        new_period="$(\
          echo "$3" \
            | ${pkgs.gnused}/bin/sed 's/night/Night time/;s/day/Day /;s/tr/Tr/' \
        )"
        notify_change "$new_period"
      }
  esac
''

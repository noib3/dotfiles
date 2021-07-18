{ pkgs }:

''
  #!${pkgs.bash}/bin/bash

  function notify_change() {
    ${pkgs.libnotify}/bin/notify-send \
      --expire-time=5000 \
      --app-name="Redshift" \
      --icon="${builtins.toString ./redshift-logo.png}" \
      "Switching temps..." \
      "$1"
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

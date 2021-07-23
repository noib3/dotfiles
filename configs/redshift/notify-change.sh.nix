let
  pkgs = import <nixpkgs> { };

  notify-change =
    if pkgs.stdenv.isLinux then
      ''
        ${pkgs.libnotify}/bin/notify-send \
          --expire-time=5000 \
          --app-name="Redshift" \
          --icon="${builtins.toString ./redshift-logo.png}" \
          "Switching temps..." \
          "$1"
      ''
    else if pkgs.stdenv.isDarwin then
      ''
        ${pkgs.terminal-notifier}/bin/terminal-notifier \
          -title "Redshift" \
          -appIcon "${builtins.toString ./redshift-logo.png}" \
          -subtitle "Switching temps..." \
          -message "$1"
      ''
    else "";
in
''
  #!${pkgs.bash}/bin/bash

  function notify_change() { ${notify-change} }

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

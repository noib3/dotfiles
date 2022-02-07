{ pkgs }:

let
  notify-done =
    if pkgs.stdenv.isLinux then
      ''
        ${pkgs.libnotify}/bin/notify-send \
          --expire-time=4000 \
          --app-name="transmission-remote" \
          --icon="${builtins.toString ./transmission-logo.png}" \
          "Torrent complete" \
          "$TR_TORRENT_NAME has finished downloading"
      ''
    else if pkgs.stdenv.isDarwin then
      ''
        ${pkgs.terminal-notifier}/bin/terminal-notifier \
          -title "transmission-remote" \
          -appIcon "${builtins.toString ./transmission-logo.png}" \
          -subtitle "Torrent complete" \
          -message "$TR_TORRENT_NAME has finished downloading"
      ''
    else "";
in
''
  function notify_done() { ${notify-done} }

  function torrent_remove() {
    ${pkgs.transmission}/bin/transmission-remote \
      --torrent "$TR_TORRENT_ID" --remove
  }

  notify_done
  torrent_remove
''

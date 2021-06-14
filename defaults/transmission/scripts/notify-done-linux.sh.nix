{ pkgs }:

''
  function notify_done() {
    ${pkgs.libnotify}/bin/notify-send \
      --expire-time=5000 \
      --app-name="transmission-remote" \
      --icon="${builtins.toString ./transmission-logo.png}" \
      "Torrent complete" \
      "$TR_TORRENT_NAME has finished downloading"
  }

  function torrent_remove() {
    ${pkgs.transmission}/bin/transmission-remote \
      --torrent "$TR_TORRENT_ID" --remove
  }

  notify_done
  torrent_remove
''

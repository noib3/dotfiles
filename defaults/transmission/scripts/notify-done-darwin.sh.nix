{ pkgs }:

''
  function notify_done() {
    ${pkgs.terminal-notifier}/bin/terminal-notifier \
      -title "transmission-remote" \
      -appIcon "${builtins.toString ./transmission-logo.png}" \
      -subtitle "Torrent complete" \
      -message "$TR_TORRENT_NAME has finished downloading"
  }

  function torrent_remove() {
    ${pkgs.transmission}/bin/transmission-remote \
      --torrent "$TR_TORRENT_ID" --remove
  }

  notify_done
  torrent_remove
''

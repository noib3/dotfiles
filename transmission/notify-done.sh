#!/usr/bin/env sh

# 'transmission-remote --torrent-done-script ~/.config/transmission/notify-done.sh'
#   to tell transmission to run this script when a torrent has finished downloading
# 'https://github.com/transmission/transmission/wiki/Scripts#Scripts' for more info

/usr/local/bin/terminal-notifier -title "Transmission" -subtitle "Torrent complete" \
                                 -message "\'$TR_TORRENT_NAME' has finished downloading" \
                                 -appIcon $(dirname "$0")/Transmission-icon.png

/usr/local/bin/transmission-remote --torrent $TR_TORRENT_ID --stop

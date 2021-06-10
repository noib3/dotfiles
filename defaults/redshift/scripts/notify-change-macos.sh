#!/usr/bin/env bash

PATH="$PATH:/usr/local/bin"

function notify_change() {
  terminal-notifier \
    -title "Redshift" \
    -appIcon "/Users/noib3/sync/dotfiles/defaults/redshift/scripts/redshift-logo.png"
    -subtitle "Switching temps..." \
    -message "$1"
}

case "$1" in
  period-changed)
    [ "$3" == "none" ] || {
      new_period = "$(echo "$3" | sed 's/night/Night time/;s/day/Day /;s/tr/Tr/')"
      notify_change "$new_period"
    }
esac

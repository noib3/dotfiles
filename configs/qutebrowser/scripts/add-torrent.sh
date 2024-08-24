QUTE_INVALID_LINK_MSG="Invalid magnet link"

function notify_add() {
  notify-send \
    --expire-time=4000 \
    --app-name="qutebrowser" \
    --icon="qutebrowser" \
    "Added new torrent" \
    "$QUTE_URL has started downloading"
}

function torrent_add() {
  transmission-remote --add "$QUTE_URL"
}

function qute_echo_error() {
  echo "message-error \"$1\"" >> "$QUTE_FIFO"
}

torrent_add && notify_add || qute_echo_error "$QUTE_INVALID_LINK_MSG"

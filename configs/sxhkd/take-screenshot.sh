filename="$SYNCDIR/screenshots/$(date +%F@%T).png"

case "$1" in
  whole)
    function take_screenshot() {
      scrot "$filename"
    }
    ;;
  portion)
    function take_screenshot() {
      scrot --select "$filename"
    }
    ;;
  *)
    exit 1
    ;;
esac

function notify_screenshot() {
  notify-send \
    --expire-time=4000 \
    --app-name="New screenshot" \
    --icon="$filename" \
    "$(basename "$filename")" \
    "Saved in $(echo "$SYNCDIR/screenshots" | sed "s/.*$(whoami)/~/")"
}

take_screenshot && notify_screenshot || true

is_running() {
  /usr/bin/pgrep -x BetterMouse > /dev/null
}

was_running=false

if is_running; then
  was_running=true
  /usr/bin/osascript -e 'quit app id "com.naotanhaocan.BetterMouse"'
  while is_running; do sleep 0.1; done
fi

rm -f "$HOME/Library/Application Support/BetterMouse/"*padl

if "$was_running"; then
  /usr/bin/osascript -e 'launch app id "com.naotanhaocan.BetterMouse"'
fi

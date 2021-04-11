{ screenshots-dir }:

''
  #!/usr/bin/env bash

  filename="${screenshots-dir}/$(date +%F@%T).png"

  case "$1" in
    whole)
      function take_screenshot() {
        screencapture -mx "$filename"
      }
      ;;
    portion)
      function take_screenshot() {
        screencapture -imx "$filename" && ls "$filename"
      }
      ;;
    *)
      exit 1
      ;;
  esac

  function notify_screenshot() {
    terminal-notifier \
      -title "New screenshot" \
      -subtitle "$(basename "$filename")" \
      -message "Saved in $(echo '${screenshots-dir}' | sed "s/.*$(whoami)/~/")" \
      -appIcon "${builtins.toString ./picture-icon.png}" \
      -contentImage "$filename" \
      -execute "open \"$filename\""
  }

  take_screenshot && notify_screenshot || true
''

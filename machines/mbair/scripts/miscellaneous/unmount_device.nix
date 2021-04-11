''
  space_left=$(\
    diskutil info "$f" 2>/dev/null \
    | sed -n "s/.*Volume Free Space:\s*//p" \
    | awk '{print $1, $2}')

  diskutil eject "$f" &>/dev/null \
    && lf -remote \
        "send $id echo \"\033[32m$(basename $f) has been ejected properly\033[0m\"" \
    && terminal-notifier \
        -title "Disk ejected" \
        -subtitle "$(basename $f) has been ejected" \
        -message "There are ''${space_left} left on disk" \
        -appIcon "${builtins.toString ./hard-disk-icon.png}" \
    || lf -remote "send $id echoerr 'Error: could not eject disk'"
''

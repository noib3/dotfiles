{ font, colors }:

''
  dmenu \
    -fn '${font.family}:pixelsize=${font.pixelsize}' \
    -nb '${colors.normal.bg}' \
    -nf '${colors.normal.fg}' \
    -sb '${colors.selected.bg}' \
    -sf '${colors.selected.fg}' \
    -nhb '${colors.normal.bg}' \
    -nhf '${colors.highlight.fg}' \
    -shb '${colors.selected.bg}' \
    -shf '${colors.highlight.fg}' \
    -w "$(xdotool getactivewindow)" \
    "$@"
''

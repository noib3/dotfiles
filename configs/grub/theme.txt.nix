{
  colors,
  backgroundImageFilename,
}:

''
  # Global properties
  title-text: ""
  desktop-image: "${backgroundImageFilename}"
  terminal-left: "0"
  terminal-top: "0"
  terminal-width: "100%"
  terminal-height: "100%"
  terminal-border: "0"

  # Boot menu
  + boot_menu {
    left = 25%
    top = 25%
    width = 50%
    height = 50%
    item_font = "Fixedsys Regular 32"
    item_color = "${colors.boot-entry.fg}"
    selected_item_color = "${colors.boot-entry.selected.fg}"
    icon_height = 30
    item_height = 50
    item_spacing = 10
    item_icon_space = 20
    selected_item_pixmap_style = "selected-entry-bg-*.png"
  }

  # Countdown message
  + label {
    left = 0
    top = 87%
    width = 100%
    align = "center"
    id = "__timeout__"
    font = "Fixedsys Regular 32"
    text = "Booting in %d seconds"
    color = "${colors.countdown-message.fg}"
  }

  # Navigation keys hint
  + label {
    left = 0
    top = 92%
    width = 100%
    align = "center"
    font = "Fixedsys Regular 32"
    text = "Use ↑ and ↓ keys to change selection, Enter to confirm"
    color = "${colors.navigation-keys-message.fg}"
  }
''

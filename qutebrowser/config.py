# Statusbar

# Statusbar colors
c.colors.statusbar.normal.bg = "#393939"
c.colors.statusbar.command.bg = "#393939"

# Tabs
c.tabs.padding = {"bottom": 3, "left": 3, "right": 3, "top": 3}
c.tabs.indicator.width = 1

# Tabs colors
c.colors.tabs.selected.even.bg = "#393939"
c.colors.tabs.selected.odd.bg = "#393939"
c.colors.tabs.even.bg = "#202124"
c.colors.tabs.odd.bg = "#202124"

# Fonts
c.fonts.monospace = "Menlo"
c.fonts.tabs = "14pt Menlo"
c.fonts.statusbar = "14pt Menlo"

# Aliases
c.aliases = {
    "yt": "open https://youtube.com"
}

# Bindings
config.unbind("gr")
config.unbind("gm")
config.bind("gyt", "open https://youtube.com")
config.bind("gre", "open https://reddit.com")
config.bind("gma", "open https://mail.google.com")

# Constants
HOME_PAGE="https://google.com"

# Statusbar

# Statusbar colors
c.colors.statusbar.normal.bg = "#393939"
c.colors.statusbar.command.bg = "#393939"

# Tabs
c.tabs.padding = {"bottom": 3, "left": 3, "right": 3, "top": 3}
c.tabs.indicator.width = 1

# Tabs colors
c.colors.tabs.even.bg = "#202124"
c.colors.tabs.odd.bg = "#202124"
c.colors.tabs.selected.even.bg = "#393939"
c.colors.tabs.selected.odd.bg = "#393939"

# Fonts
c.fonts.default_family = ["Menlo"]
c.fonts.tabs = "14pt Menlo"
c.fonts.statusbar = "14pt Menlo"

# Aliases
c.aliases = {
    "yt": "open https://youtube.com"
}

# Bindings
config.unbind("gm")
config.unbind("gr")

config.bind("<Meta-T>", f"open -t {HOME_PAGE}")
config.bind("<Meta-N>", f"open -w {HOME_PAGE}")
config.bind("<Meta-W>", "tab-close")
config.bind("<Meta-Q>", "quit")
for i in range(10):
    config.bind(f"<Meta-{i}>", f"tab-focus {i}")
config.bind(f"<Meta-0>", f"tab-focus 10")

config.bind("gma", "open https://mail.google.com")
config.bind("gdr", "open https://drive.google.com")
config.bind("gre", "open https://reddit.com")
config.bind("gyt", "open https://youtube.com")
config.bind("gdf", "open https://github.com/n0ibe/dotfiles")

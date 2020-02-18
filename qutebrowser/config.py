# Constants
HOME_PAGE="https://google.com"
LIGHT_GRAY="#626262"
DARK_GRAY="#393939"

# Statusbar
c.statusbar.widgets = []

# Statusbar colors
c.colors.statusbar.normal.bg = DARK_GRAY
c.colors.statusbar.command.bg = DARK_GRAY

# Tabs
c.tabs.padding = {"bottom": 0, "left": 0, "right": 7, "top": 0}
c.tabs.indicator.padding = {"bottom": 0, "left": 0, "right": 7, "top": 0}
c.tabs.indicator.width = 1
c.tabs.title.format = "{index}: {current_title}"

# Tabs colors
c.colors.tabs.odd.bg = DARK_GRAY
c.colors.tabs.even.bg = DARK_GRAY
c.colors.tabs.selected.odd.bg = LIGHT_GRAY
c.colors.tabs.selected.even.bg = LIGHT_GRAY

# Fonts
c.fonts.default_family = ["Menlo"]
c.fonts.tabs = "14pt Menlo"
c.fonts.statusbar = "14pt Menlo"

# Aliases
c.aliases = {
    "yt": "open https://youtube.com"
}

# Command key bindings
config.bind("<Meta-q>", "quit", mode="normal")
config.bind("<Meta-q>", "quit", mode="insert")
config.bind("<Meta-w>", "tab-close", mode="normal")
config.bind("<Meta-w>", "tab-close", mode="insert")
config.bind("<Meta-r>", "config-source", mode="normal")
config.bind("<Meta-r>", "config-source", mode="insert")
config.bind("<Meta-r>", "config-source", mode="command")
config.bind("<Meta-t>", f"open -t {HOME_PAGE}", mode="normal")
config.bind("<Meta-t>", f"open -t {HOME_PAGE}", mode="insert")
config.bind("<Meta-n>", f"open -w {HOME_PAGE}", mode="normal")
config.bind("<Meta-n>", f"open -w {HOME_PAGE}", mode="insert")

for i in range(10):
    config.bind(f"<Meta-{i}>", f"tab-focus {i}", mode="normal")
    config.bind(f"<Meta-{i}>", f"tab-focus {i}", mode="insert")
config.bind(f"<Meta-0>", "tab-focus 10", mode="normal")
config.bind(f"<Meta-0>", "tab-focus 10", mode="insert")

config.bind(f"<Meta-left>", "back", mode="normal")
config.bind(f"<Meta-left>", "back", mode="insert")
config.bind(f"<Meta-right>", "forward", mode="normal")
config.bind(f"<Meta-right>", "forward", mode="insert")

# Navigation bindings
config.bind("gh", f"open {HOME_PAGE}")
config.bind("gkp", "open https://keep.google.com")
config.bind("gma", "open https://mail.google.com")
config.bind("gdr", "open https://drive.google.com")
config.bind("gre", "open https://reddit.com")
config.bind("gyt", "open https://youtube.com")
config.bind("gdf", "open https://github.com/n0ibe/dotfiles")

# Misc bindings
config.bind("zt", "config-cycle tabs.show always switching")

# Misc
c.window.title_format = "qutebrowser"
c.url.start_pages = [HOME_PAGE]
c.statusbar.hide = True
c.messages.timeout = 5000

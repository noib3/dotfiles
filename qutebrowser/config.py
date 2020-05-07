config.load_autoconfig()

# Constants
HOME_PAGE="https://google.com"
LIGHT_GRAY="#626262"
DARK_GRAY="#393939"
TEXT_ACTIVE="#ebebeb"
TEXT_INACTIVE="#b6b6b6"

# Statusbar
c.statusbar.widgets = []

# Statusbar colors
c.colors.statusbar.normal.bg = DARK_GRAY
c.colors.statusbar.command.bg = c.colors.statusbar.normal.bg

# Tabs
c.tabs.padding = {"bottom": 0, "left": 0, "right": 7, "top": 0}
c.tabs.indicator.padding = {"bottom": 0, "left": 0, "right": 7, "top": 0}
c.tabs.indicator.width = 1
c.tabs.title.format = "{index}: {current_title}"

# Tabs foreground
c.colors.tabs.odd.fg = TEXT_INACTIVE
c.colors.tabs.even.fg = c.colors.tabs.odd.fg
c.colors.tabs.selected.odd.fg = TEXT_ACTIVE
c.colors.tabs.selected.even.fg = c.colors.tabs.selected.odd.fg

# Tabs background
c.colors.tabs.odd.bg = DARK_GRAY
c.colors.tabs.even.bg = c.colors.tabs.odd.bg
c.colors.tabs.selected.odd.bg = LIGHT_GRAY
c.colors.tabs.selected.even.bg = c.colors.tabs.selected.odd.bg

# Fonts
c.fonts.default_family = ["Iosevka Nerd Font"]
c.fonts.default_size = "17pt"

# Search engines
c.url.searchengines = {
    "DEFAULT": "https://google.com/search?q={}",
    "yt": "https://youtube.com/results?search_query={}"
}

# Command key bindings
config.bind("<Meta-q>", "quit", mode="normal")
config.bind("<Meta-q>", "quit", mode="insert")
config.bind("<Meta-w>", "tab-close", mode="normal")
config.bind("<Meta-w>", "tab-close", mode="insert")
config.bind("<Meta-r>", "config-source", mode="normal")
config.bind("<Meta-r>", "config-source", mode="insert")
config.bind("<Meta-r>", "config-source", mode="command")
config.bind("<Meta-n>", f"open -w {HOME_PAGE}", mode="normal")
config.bind("<Meta-n>", f"open -w {HOME_PAGE}", mode="insert")

for i in range(10):
    config.bind(f"<Meta-{i}>", f"tab-focus {i}", mode="normal")
    config.bind(f"<Meta-{i}>", f"tab-focus {i}", mode="insert")
config.bind(f"<Meta-0>", "tab-focus 10", mode="normal")
config.bind(f"<Meta-0>", "tab-focus 10", mode="insert")

config.bind(f"<Meta-left>", "back", mode="normal")
config.bind(f"<Meta-right>", "forward", mode="normal")

# Navigation bindings
config.unbind("n")
config.unbind("gr")
config.unbind("gm")
config.unbind("gb")
config.unbind("gl")

config.bind("gh", f"open {HOME_PAGE}")
config.bind("nh", f"open -t {HOME_PAGE}")

config.bind("gkp", "open https://keep.google.com")
config.bind("nkp", "open -t https://keep.google.com")

config.bind("gma", "open https://mail.google.com")
config.bind("nma", "open -t https://mail.google.com")

config.bind("gdr", "open https://drive.google.com")
config.bind("ndr", "open -t https://drive.google.com")

config.bind("gre", "open https://reddit.com")
config.bind("nre", "open -t https://reddit.com")

config.bind("gyt", "open https://youtube.com")
config.bind("nyt", "open -t https://youtube.com")

config.bind("gtw", "open https://twitch.tv")
config.bind("ntw", "open -t https://twitch.tv")

config.bind("gnf", "open https://github.com/n0ibe/dotfiles")
config.bind("nnf", "open -t https://github.com/n0ibe/dotfiles")

config.bind("gel", "open https://elearning.df.unipi.it/")
config.bind("nel", "open -t https://elearning.df.unipi.it/")

config.bind("gng", "open https://secure.ing.it/login.aspx")
config.bind("nng", "open -t https://secure.ing.it/login.aspx")

config.bind("gbg", "open https://rarbgunblocked.org/torrents.php")
config.bind("nbg", "open -t https://rarbgunblocked.org/torrents.php")

config.bind("glh", "open http://localhost:9091/transmission/web/")
config.bind("nlh", "open -t http://localhost:9091/transmission/web/")

config.bind("glg", "open http://libgen.li/")
config.bind("nlg", "open -t http://libgen.li/")

# Misc bindings
config.bind("zt", "config-cycle tabs.show always switching")

# Misc
c.url.start_pages = [HOME_PAGE]
c.statusbar.hide = True
c.messages.timeout = 2000
c.tabs.last_close = "close"
# c.window.hide_decoration = True
c.bindings.key_mappings.update( {"<Meta-t>": "O"} )

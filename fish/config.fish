# Settings
set fish_greeting ""
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore
set fish_cursor_visual block

# Colorscheme
source "$HOME/.config/fish/colorschemes/$COLORSCHEME.fish"

# Plugins
fundle plugin 'edc/bass'
fundle plugin 'laughedelic/pisces'
fundle init

# Prompt
starship init fish | source

# Nix
bass source ~/.nix-profile/etc/profile.d/nix{,-daemon}.sh

direnv hook fish | source

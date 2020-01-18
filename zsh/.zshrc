#	         _
#	        | |
#   ________| |__  _ __ ___
#   |_  / __| '_ \| '__/ __|
#  _ / /\__ \ | | | | | (__
# (_)___|___/_| |_|_|  \___|

# Add 'export ZDOTDIR=$HOME/.config/zsh' to '/private/etc/zprofile'
# to source this file in this custom location

PATH=/usr/local/opt/coreutils/libexec/gnubin
PATH=$PATH:/usr/local/opt/python@3.8/bin
PATH=$PATH:/usr/local/bin
PATH=$PATH:/usr/bin
PATH=$PATH:/usr/sbin
PATH=$PATH:/bin
PATH=$PATH:/sbin
PATH=$PATH:/Library/TeX/texbin
PATH=$PATH:/opt/X11/bin

# SHELL ------------------
setopt AUTO_CD
unsetopt BEEP

HISTFILE=$HOME/.cache/zsh/.zsh_history
LS_COLORS='di=1;36:ex=32:ln=35:mh=31'
PROMPT='%F{255}%1~ %F{137}> %F{255}'

export VISUAL=nvim
export EDITOR="$VISUAL"
export PYTHONSTARTUP=$HOME/.config/python/python-startup.py

# TAB AUTOCOMPLETION -----
autoload -U compinit
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)

# LOCALE SETTINGS --------
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# ALIASES ----------------
alias -g ndiet='~/Programs/ndiet/ndiet.py'

alias -g peek='~/Scripts/peek/peek.py'
alias -g Omega='~/Scripts/Omega/Omega.py'
alias -g 2d2small='~/Scripts/2d2small/2d2small.sh'
alias -g otfinstall='~/Scripts/otfinstall/otfinstall.sh'

alias -g ls='ls -Ah --color --quoting-style=literal'
alias -g ssh='ssh -F $HOME/.config/ssh/config'
alias -g brew='HOMEBREW_NO_AUTO_UPDATE=1 brew'
alias -g cal='calcurse -D $HOME/.config/calcurse'
alias -g ufetch='sh $HOME/.config/ufetch/ufetch'
alias -g ytdlmp3='youtube-dl --extract-audio --audio-format mp3'
alias -g c='clear && printf "\e[3J"'

# EDIT CONFIG FILES ----
alias -g zshrc='nvim $ZDOTDIR/.zshrc && source $ZDOTDIR/.zshrc'
alias -g alacrittyrc='nvim ~/.config/alacritty/alacritty.yml'
alias -g yabairc='nvim ~/.config/yabai/yabairc && ~/.config/yabai/yabairc'
alias -g skhdrc='nvim ~/.config/skhd/skhdrc && ~/.config/skhd/skhdrc'
alias -g nvimrc='nvim ~/.config/nvim/init.vim'
alias -g redshiftrc='nvim ~/.config/redshift/redshift.conf && brew services restart redshift'

# TRANSMISSION -----------
function tsmlist() {
    transmission-remote --list
}
function tsmadd() {
    transmission-remote --add "$1"
}

function tsmstop() {
    transmission-remote -t "$1" --stop
}

function tsmstart() {
    transmission-remote -t "$1" --start
}

# does not delete data
function tsmremove() {
    transmission-remote -t "$1" --remove
}

# does delete data
function tsmpurge() {
    transmission-remote -t "$1" --remove-and-delete
}

# PLUGINS ----------------
source $ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Empty Dock (need to install m with 'brew install m-cli')
# m dock prune

# Show all file extensions
#  m finder showextensions YES

# Hide Dock
#  defaults write com.apple.dock autohide-delay -float 1000

# If Dock gets stuck and won't launch anymore
#  launchctl unload -F /System/Library/LaunchAgents/com.apple.Dock.plist
#  launchctl   load -F /System/Library/LaunchAgents/com.apple.Dock.plist
#  launchctl start com.apple.Dock.agent
#  launchctl unload -F /System/Library/LaunchAgents/com.apple.Dock.plist
#  /System/Library/CoreServices/Dock.app/Contents/MacOS/Dock
#  rm -rf ~/Library/Application\ Support/Dock
#  sudo reboot

# Write to /System
#  sudo mount -uw /
#  killall Finder
# defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
# defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)

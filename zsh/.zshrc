# Add 'export ZDOTDIR=~/.config/zsh' to '/private/etc/zprofile'
# to source this file in this custom location

PATH=/usr/local/opt/coreutils/libexec/gnubin
PATH=$PATH:/usr/local/opt/findutils/libexec/gnubin
PATH=$PATH:/usr/local/opt/python@3.8/bin
PATH=$PATH:/usr/local/bin
PATH=$PATH:/usr/bin
PATH=$PATH:/usr/sbin
PATH=$PATH:/bin
PATH=$PATH:/sbin
PATH=$PATH:/Library/TeX/texbin
PATH=$PATH:/opt/X11/bin

# SHELL OPTIONS AND PROMPT
setopt MENU_COMPLETE
setopt AUTO_CD
unsetopt CASE_GLOB
unsetopt BEEP
#PROMPT='%F{255}%1~ %F{137}> %F{255}'
#PROMPT='%F{252}%1~ %F{blue}> %F{255}'
PROMPT='%F{252}%1~ %F{218}> %F{255}'

# TAB AUTOCOMPLETION
autoload -U compinit
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zmodload zsh/complist
_comp_options+=(globdots)

# CACHED FILES
compinit -d ~/.cache/zsh/zcompdump-$ZSH_VERSION
HISTFILE=~/.cache/zsh/zsh_history

# KEY BINDINGS
close() { yabai -m window --close }
zle -N close
bindkey '^w' close

quits() { killall alacritty }
zle -N quits
bindkey '^y' quits

alacrittyrc() { $EDITOR ~/.config/alacritty/alacritty.yml }
zle -N alacrittyrc
bindkey '^n' alacrittyrc

fdcd() {
    local dir
    dir=$(cd &&
           fd -0 --type d --ignore-file ~/.config/fd/ignore --hidden |
           fzf --read0 --height=50%) \
    && cd ~/$dir
    zle reset-prompt
}
zle -N fdcd
bindkey '^f' fdcd

# ALIASES
alias alacritty='/Applications/Alacritty.app/Contents/MacOS/alacritty'
alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'

SRCDIR=~/Programs
alias -g ndiet='$SRCDIR/ndiet/ndiet.py'
alias -g peek='$SRCDIR/peek/peek.py'
alias -g Omega='$SRCDIR/Omega/Omega.py'
alias -g 2d2small='$SRCDIR/2d2small/2d2small.sh'
alias -g otfinstall='$SRCDIR/otfinstall/otfinstall.sh'
alias -g tmd='$SRCDIR/tmd/tmd.sh'
alias -g ffls='$SRCDIR/ffls/ffls.sh'
alias -g ufetch='$SRCDIR/ufetch/ufetch.sh'

alias ls='ls -Ah --color --quoting-style=literal --group-directories-first'
alias grep='grep --color=auto'
alias tree='tree -N'
alias ssh='ssh -F ~/.config/ssh/config'
alias brew='HOMEBREW_NO_AUTO_UPDATE=1 brew'
alias cmus='tmux attach-session -t cmus >/dev/null'
alias tmux='tmux -f ~/.config/tmux/tmux.conf'
alias vnstat='vnstat --config ~/.config/vnstat/vnstat.conf'
alias cal='calcurse -C ~/.config/calcurse -D ~/.local/share/calcurse'
alias ytdlmp3='youtube-dl --extract-audio --audio-format mp3'
alias c='clear && printf "\e[3J"'
alias nfs='$EDITOR $(fzf --height=50%)'

alias zshrc='$EDITOR $ZDOTDIR/.zshrc && source $ZDOTDIR/.zshrc'
alias yabairc='$EDITOR ~/.config/yabai/yabairc && ~/.config/yabai/yabairc'
alias skhdrc='$EDITOR ~/.config/skhd/skhdrc'
alias nvimrc='$EDITOR ~/.config/nvim/init.vim'
alias tmuxrc='$EDITOR ~/.config/tmux/tmux.conf && tmux source ~/.config/tmux/tmux.conf'
alias redshiftrc='$EDITOR ~/.config/redshift/redshift.conf && brew services restart redshift'

alias gpom='git push origin master'

# FUNCTIONS
tsm() { firefox -new-tab -url "http://localhost:9091/transmission/web/" }

# PLUGINS
source $ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZDOTDIR/plugins/colored-man-pages/colored-man-pages.plugin.zsh
source $ZDOTDIR/plugins/zsh-autopair/autopair.zsh

# SOURCE FILE WITH ENVIRONMENT VARIABLES
source $ZDOTDIR/exports.zsh

# Disable the "Are you sure you want to open this application?" dialog
#   defaults write com.apple.LaunchServices LSQuarantine -bool false

# List all songs and pipe them into tmd
#   find ~/Music -iname "*\.mp3" -print0 | xargs -0 tmd

# List all 8-bit colors
#   for i in {1..256}; do print -P "%F{$i}Color : $i"; done;

# Change TeX home tree
#   sudo tlmgr conf texmf TEXMFHOME "~/TeX/texmf"

# Empty Dock
#   defaults write com.apple.dock recent-apps -array
#   defaults write com.apple.dock persistent-apps -array

# Hide Dock
#   defaults write com.apple.dock autohide-delay -float 1000

# Keep programs out of dock
#   System Preferences -> Dock -> Show recent applications in Dock [uncheck]

# If Dock gets stuck and won't launch anymore
#   launchctl unload -F /System/Library/LaunchAgents/com.apple.Dock.plist
#   launchctl   load -F /System/Library/LaunchAgents/com.apple.Dock.plist
#   launchctl start com.apple.Dock.agent
#   launchctl unload -F /System/Library/LaunchAgents/com.apple.Dock.plist
#   /System/Library/CoreServices/Dock.app/Contents/MacOS/Dock
#   rm -rf ~/Library/Application Support/Dock
#   rm -rf ~/Library/Preferences/com.apple.dock.plist
#   sudo reboot

# Write to /System
#   sudo mount -uw /
#   killall Finder

# Link airport
#   ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/bin/airport

# defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
# defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)A

# Remove .DS_Store files from home folder
#   find ~ -depth -name ".DS_Store" -exec rm {} \;

# Set wallpaper from command line
#   osascript -e 'tell application "Finder" to set desktop picture to POSIX file "<absolute_path_to_file>"'
#   osascript -e 'quit app "Finder"'

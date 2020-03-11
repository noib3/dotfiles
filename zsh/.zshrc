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
PATH=$PATH:$HOME/Scripts

# SHELL OPTIONS AND PROMPT
setopt MENU_COMPLETE
setopt AUTO_CD
setopt histignoredups
unsetopt CASE_GLOB
unsetopt BEEP
PROMPT='%F{252}%1~ %F{224}> %F{255}'

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
# Unmap Ctrl-s
stty -ixon

close_window() { yabai -m window --close }
zle -N close_window
bindkey '^w' close_window

quit_terminal() { killall alacritty }
zle -N quit_terminal
bindkey '^y' quit_terminal

termrc() { $EDITOR ~/.config/alacritty/alacritty.yml }
zle -N termrc
bindkey '^n' termrc

fuzzycd() {
    local dir
    dir=$(cd &&
           fd -0 --type d --ignore-file ~/.config/fd/ignore --hidden |
           fzf --read0 --height=50%) \
    && cd ~/$dir
    zle reset-prompt
}
zle -N fuzzycd
bindkey '^f' fuzzycd

fuzzyedit() {
    dir=$(pwd)
    file=$(cd &&
            fd -0 --type f --ignore-file ~/.config/fd/ignore --hidden |
            fzf --read0 --height=50%) \
    && cd $dir && $EDITOR ~/$file
    zle reset-prompt
}
zle -N fuzzyedit
bindkey '^s' fuzzyedit

# ALIASES
alias alacritty='/Applications/Alacritty.app/Contents/MacOS/alacritty'
alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'

SRCDIR=~/bin
alias -g ndiet='$SRCDIR/ndiet/ndiet.py'
alias -g 2d2small='$SRCDIR/2d2small/2d2small.sh'
alias tfin='~/Scripts/tfin/tfin.sh'
alias -g peek='peek.py'
alias -g ufetch='ufetch.sh'
alias -g colortest='colortest.sh'
alias -g tmd='tmd.sh'
alias -g Omega='Omega.py'
alias -g ffls='ffls.sh'
alias -g lscolors='for i in {1..256}; do print -P "%F{$i}Color : $i"; done;'
alias -g rmds='find ~ -depth -name ".DS_Store" -exec rm {} \;'

alias ls='ls -Ah --color --quoting-style=literal --group-directories-first'
alias grep='grep --color=auto'
alias tree='tree -N'
alias ssh='ssh -F ~/.config/ssh/config'
alias brew='HOMEBREW_NO_AUTO_UPDATE=1 brew'
alias cmus='tmux attach-session -t cmus >/dev/null'
alias tmux='tmux -f ~/.config/tmux/tmux.conf'
alias cal='calcurse -C ~/.config/calcurse -D ~/.local/share/calcurse'

alias ytdlmp3='youtube-dl --extract-audio --audio-format mp3'
alias c='clear && printf "\e[3J"'
alias gpom='git push origin master'

alias zshrc='$EDITOR $ZDOTDIR/.zshrc && source $ZDOTDIR/.zshrc'
alias yabairc='$EDITOR ~/.config/yabai/yabairc && ~/.config/yabai/yabairc'
alias skhdrc='$EDITOR ~/.config/skhd/skhdrc'
alias nvimrc='$EDITOR ~/.config/nvim/init.vim'
alias lfrc='$EDITOR ~/.config/lf/lfrc'
alias tmuxrc='$EDITOR ~/.config/tmux/tmux.conf && tmux source ~/.config/tmux/tmux.conf'

# PLUGINS
source $ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZDOTDIR/plugins/colored-man-pages/colored-man-pages.plugin.zsh
source $ZDOTDIR/plugins/zsh-autopair/autopair.zsh

# SOURCE FILE WITH ENVIRONMENT VARIABLES
source $ZDOTDIR/exports.zsh

# ciao() { echo '"${1}"' }
ciao() {
    #osascript -e 'tell application "Finder" to set desktop picture to POSIX file "\"$1\""'
    osascript -e 'tell application "Finder" to set desktop picture to POSIX file "'"$1"\"
    osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$1\""
}

# Set wallpaper from command line
#   osascript -e 'tell application "Finder" to set desktop picture to POSIX file "<absolute_path_to_file>"'
#   osascript -e 'quit app "Finder"'

# Disable the "Are you sure you want to open this application?" dialog
#   defaults write com.apple.LaunchServices LSQuarantine -bool false

# List all songs and pipe them into tmd
#   find ~/Music -iname "*\.mp3" -print0 | xargs -0 tmd

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

# defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
# defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)A

# Add 'export ZDOTDIR=~/.config/zsh' to '/private/etc/zprofile'
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

# SHELL OPTIONS AND PROMPT
setopt MENU_COMPLETE
setopt AUTO_CD
unsetopt CASE_GLOB
unsetopt BEEP
PROMPT='%F{255}%1~ %F{137}> %F{255}'

# TAB AUTOCOMPLETION
autoload -U compinit
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zmodload zsh/complist
_comp_options+=(globdots)

# CACHED FILES
compinit -d $HOME/.cache/zsh/zcompdump-$ZSH_VERSION
HISTFILE=$HOME/.cache/zsh/zsh_history

# KEY BINDINGS
function close() { exit }
zle -N close
bindkey '^w' close

function alacritty() { nvim ~/.config/alacritty/alacritty.yml }
zle -N alacritty
bindkey '^n' alacritty

fdcd() {
    local dir
    dir=$(
      cd &&
        fd -0 --type d --ignore-file ~/.config/fd/ignore --hidden |
        fzf --read0
    ) && cd ~/$dir
    zle reset-prompt
}
zle -N fdcd
bindkey '^f' fdcd

function olf() { lf ~/Documents }
zle -N olf
bindkey '^g' olf

# ALIASES
alias alacritty='/Applications/Alacritty.app/Contents/MacOS/alacritty'
alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'

alias -g ndiet='~/Programs/ndiet/ndiet.py'
alias -g peek='~/Programs/peek/peek.py'
alias -g Omega='~/Programs/Omega/Omega.py'
alias -g 2d2small='~/Programs/2d2small/2d2small.sh'
alias -g otfinstall='~/Programs/otfinstall/otfinstall.sh'
alias -g tmd='~/Programs/tmd/tmd.sh'
alias -g ufetch='~/.config/ufetch/ufetch'

alias ls='ls -Ah --color --quoting-style=literal --group-directories-first'
alias colorls='colorls -Ah --sort-files'
alias grep='grep --color=auto'
alias tree='tree -N'
alias ssh='ssh -F ~/.config/ssh/config'
alias brew='HOMEBREW_NO_AUTO_UPDATE=1 brew'
alias cmus='tmux attach-session -t cmus >/dev/null'
alias tmux='tmux -f ~/.config/tmux/tmux.conf'
alias cal='calcurse -C ~/.config/calcurse -D ~/.local/share/calcurse'
alias ytdlmp3='youtube-dl --extract-audio --audio-format mp3'
alias c='clear && printf "\e[3J"'
alias nfs='nvim $(fzf)'

alias zshrc='$EDITOR $ZDOTDIR/.zshrc && source $ZDOTDIR/.zshrc'
alias yabairc='$EDITOR ~/.config/yabai/yabairc && ~/.config/yabai/yabairc'
alias skhdrc='$EDITOR ~/.config/skhd/skhdrc && ~/.config/skhd/skhdrc'
alias nvimrc='$EDITOR ~/.config/nvim/init.vim'
alias tmuxrc='$EDITOR ~/.config/tmux/tmux.conf && tmux source ~/.config/tmux/tmux.conf'
alias redshiftrc='$EDITOR ~/.config/redshift/redshift.conf && brew services restart redshift'

# FUNCTIONS
function tsm() { firefox -new-tab -url "http://localhost:9091/transmission/web/" }

# PLUGINS
source $ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZDOTDIR/plugins/colored-man-pages/colored-man-pages.plugin.zsh
source $ZDOTDIR/plugins/zsh-autopair/autopair.zsh

# SOURCE FILE WITH ENVIRONMENT VARIABLES
source $ZDOTDIR/exports.zsh

# List all songs and pipe them into tmd
#   find ~/Music -iname "*\.mp3" -print0 | xargs -0 tmd

# Change TeX home tree
#   sudo tlmgr conf texmf TEXMFHOME "~/TeX/texmf"

# Empty Dock (need to install m with 'brew install m-cli')
# m dock prune

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
# defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)A

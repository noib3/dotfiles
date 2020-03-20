# ----------------------------- ZSH CONFIG FILE -----------------------------

# 'echo "export ZDOTDIR=~/.config/zsh" >> /private/etc/zprofile"' to load
# config file in this non-standard location

# ---------------------------------------------------------------------------
# Set the $PATH environment variable

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
export PATH

# ---------------------------------------------------------------------------
# Set/unset shell options

# enable prompt expansion
setopt PROMPT_SUBST
setopt MENU_COMPLETE
setopt AUTO_CD
setopt HISTIGNOREDUPS
unsetopt CASE_GLOB
unsetopt BEEP

# ---------------------------------------------------------------------------
# Format prompt, with custom format for git directories
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:*' enable git
# 1. use functions in prompt definition
# 2. use different prompts if in git directory
# 3. get directory names relative to git directory
repo() { basename $(git remote get-url origin) | sed 's/.git//' }
commits() { git rev-list --count "$1" 2>/dev/null }
zstyle ':vcs_info:*' formats '%F{#adadad}on %F{#ede845} %b '
PROMPT='%F{#e1e1e1}%1~ ${vcs_info_msg_0_}%F{#e69ab7}> %F{#ffffff}'

# ---------------------------------------------------------------------------
# Tab Autocompletion

autoload -Uz compinit && compinit
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zmodload zsh/complist
_comp_options+=(globdots)

# ---------------------------------------------------------------------------
# Specify cached files location

compinit -d ~/.cache/zsh/zcompdump-$ZSH_VERSION
HISTFILE=~/.cache/zsh/zsh_history

# ---------------------------------------------------------------------------
# Key Bindings

# Unbind 'Ctrl + S'
stty -ixon

# Close terminal window
close_window() {
    yabai -m window --close
}
zle -N close_window
bindkey '^W' close_window

# Edit alacritty config file (bound to 'cmd + ,' in alacritty.yml)
term_config() {
    $EDITOR ~/.config/alacritty/alacritty.yml
}
zle -N term_config
bindkey '^X^T' term_config

# Use fd/fzf combo to change directory...
fuzzy_cd() {
    local dir
    dir=$(cd &&
           fd -0 --type d --ignore-file ~/.config/fd/ignore --hidden |
           fzf --read0 --height=50%) \
    && cd ~/$dir
    zle reset-prompt
}
zle -N fuzzy_cd
bindkey '^X^F' fuzzy_cd

# ...or edit a file
fuzzy_edit() {
    dir=$(pwd)
    file=$(cd &&
            fd -0 --type f --ignore-file ~/.config/fd/ignore --hidden |
            fzf --read0 --height=50%) \
    && cd $dir && $EDITOR ~/$file
    zle reset-prompt
}
zle -N fuzzy_edit
bindkey '^S' fuzzy_edit

# ---------------------------------------------------------------------------
# Aliases

# Cli aliases for GUI programs
alias alacritty='/Applications/Alacritty.app/Contents/MacOS/alacritty'
alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'

# Specify particular program behaviour
alias ls='ls -Ah --color --quoting-style=literal --group-directories-first'
alias grep='grep --color=auto'
alias tree='tree -N'
alias ssh='ssh -F ~/.config/ssh/config'
alias brew='HOMEBREW_NO_AUTO_UPDATE=1 brew'
alias cmus='tmux attach-session -t cmus >/dev/null'
alias tmux='tmux -f ~/.config/tmux/tmux.conf'
alias cal='calcurse -C ~/.config/calcurse -D ~/.local/share/calcurse'

# Edit config files
alias zshrc='$EDITOR ~/.config/zsh/.zshrc && source ~/.config/zsh/.zshrc'
alias yabairc='$EDITOR ~/.config/yabai/yabairc && ~/.config/yabai/yabairc'
alias skhdrc='$EDITOR ~/.config/skhd/skhdrc'
alias nvimrc='$EDITOR ~/.config/nvim/init.vim'
alias lfrc='$EDITOR ~/.config/lf/lfrc'
alias tmuxrc='$EDITOR ~/.config/tmux/tmux.conf && tmux source ~/.config/tmux/tmux.conf'

# Custom scripts
alias -g ndiet='~/Bin/ndiet/ndiet.py'
alias -g 2d2small='~/Bin/2d2small/2d2small.sh'
alias tfin='~/Scripts/tfin/tfin.sh'
alias -g peek='peek.py'
alias -g ufetch='ufetch.sh'
alias -g colortest='colortest.sh'
alias -g tmd='tmd.sh'
alias -g Omega='Omega.py'
alias -g ffls='ffls.sh'
alias -g committed='committed.sh'
alias -g lscolors='for i in {1..256}; do print -P "%F{$i}Color : $i"; done;'
alias -g rmds='find ~ -depth -name ".DS_Store" -exec rm {} \;'

# Misc
alias gpom='git push origin master'
alias ytdlmp3='youtube-dl --extract-audio --audio-format mp3'

# ---------------------------------------------------------------------------
# Misc

# 'c' to clear the screen, remove the scrollback and clear the editing buffer
accept-line() case $BUFFER in
  (c) printf '\e[H\e[3J'; BUFFER=; zle redisplay;;
  (*) zle .accept-line
esac
zle -N accept-line

# ---------------------------------------------------------------------------
# Source additional files

source $ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZDOTDIR/plugins/colored-man-pages/colored-man-pages.plugin.zsh
source $ZDOTDIR/plugins/zsh-autopair/autopair.zsh
source $ZDOTDIR/exports.zsh


# Set wallpaper from command line
#   osascript -e 'tell application "Finder" to set desktop picture to POSIX file "<absolute_path_to_file>"'
#   osascript -e 'quit app "Finder"'
# Or, to use it inside a shell function,
#   osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$1\""

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

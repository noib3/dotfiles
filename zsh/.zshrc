# ----------------------------- ZSH CONFIG FILE -----------------------------

# sudo touch /etc/zshenv && echo "export ZDOTDIR=~/.config/zsh" | sudo tee /etc/zshenv >/dev/null
# to load config file in this non-standard location

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
# Set the $PATH env variable

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

# ---------------------------------------------------------------------------
# Export env variables

export PATH
export VISUAL=nvim
export EDITOR=$VISUAL

# locale variables
export LC_LL=en_US.UTF-8
export LANG=en_US.UTF-8

# history, config and startup files
export HISTFILE=$HOME/.cache/zsh/zsh_history
export LESSHISTFILE=$HOME/.cache/less/lesshst
export MPLCONFIGDIR=$HOME/.cache/matplotlib
export PYTHONSTARTUP=$HOME/.config/python/python-startup.py

export LS_COLORS='no=90:di=01;34:ex=01;32:ln=35:mh=31:*.mp3=33:*.md=04;93:*.ttf=95:*.otf=95:*.png=04;92:*.jpg=04;92'
export FZF_DEFAULT_COMMAND='fd --type f --ignore-file ~/.config/fd/fdignore'

# ---------------------------------------------------------------------------
# Format prompt, with custom format for git directories

autoload -Uz vcs_info
precmd() {
    vcs_info
    if [[ -n ${vcs_info_msg_0_} ]]; then
        PROMPT="${vcs_info_msg_0_} %F{#a18ee8}> %F{#cfcfcf}"
    else
        PROMPT="%F{#e1e1e1}%1~ %F{#e69ab7}> %F{#cfcfcf}"
    fi
}
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%F{#ede845}[$(repo) %F{#bbbbbb}on %F{#ede845} %b] %F{#e1e1e1}$(basename %S)'
repo() { basename $(git remote get-url origin) | sed 's/.git//' }

# ---------------------------------------------------------------------------
# Enable vi mode

bindkey -v
# key input delay in hundredths of a second
KEYTIMEOUT=1

# make backspace work after entering and leaving normal mode
bindkey "^?" backward-delete-char

# change cursor shape depending on vi mode
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'

  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

_fix_cursor() {
   echo -ne '\e[5 q'
}

precmd_functions+=(_fix_cursor)

# ---------------------------------------------------------------------------
# Tab Autocompletion

autoload -Uz compinit && compinit -d ~/.cache/zsh/zcompdump-$ZSH_VERSION
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zmodload zsh/complist
_comp_options+=(globdots)

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
           fd -0 --type d --ignore-file ~/.config/fd/fdignore --hidden |
           fzf --read0 --height=50%) \
    && cd ~/$dir
    printf '\e[H\e[3J'
    precmd
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_cd
bindkey '^X^F' fuzzy_cd

# ...or edit a file
fuzzy_edit() {
    dir=$(pwd)
    file=$(cd &&
            fd -0 --type f --ignore-file ~/.config/fd/fdignore --hidden |
            fzf --read0 --height=50%) \
    && cd $dir && $EDITOR ~/$file
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_edit
bindkey '^S' fuzzy_edit

# ---------------------------------------------------------------------------
# Aliases

# Cli aliases for GUI programs
alias alacritty='/Applications/Alacritty.app/Contents/MacOS/alacritty'
alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'
alias skim='/Applications/Skim.app/Contents/MacOS/skim'

# Specify particular program behaviour
alias ls='ls -Ah --color --quoting-style=literal --group-directories-first'
alias grep='grep --color=auto'
alias tree='tree -N'
alias tmux='tmux -f ~/.config/tmux/tmux.conf'
alias brew='HOMEBREW_NO_AUTO_UPDATE=1 brew'
alias cal='calcurse -C ~/.config/calcurse -D ~/.local/share/calcurse'

# Custom scripts
alias -g ndiet='~/Bin/ndiet/ndiet.py'
alias -g 2d2small='~/Bin/2d2small/2d2small.sh'
alias -g tfin='~/Scripts/tfin/tfin.sh'
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
# Transmission

trl() { transmission-remote --list }
tra() { transmission-remote --add "$1" }
trst() { transmission-remote --torrent "$1" --start }
trsp() { transmission-remote --torrent "$1" --stop }
trr() { transmission-remote --torrent "$1" --remove }
trp() { transmission-remote --torrent "$1" --remove-and-delete }

# ---------------------------------------------------------------------------
# Misc

# 'c' to clear the screen, remove the scrollback and clear the editing buffer
# the alias is just to make the 'c' green with zsh-syntax-highlighting
alias c=''
accept-line() case $BUFFER in
  (c) printf '\e[H\e[3J'; BUFFER=; zle redisplay;;
  (*) zle .accept-line
esac
zle -N accept-line

# ---------------------------------------------------------------------------
# Source additional files

# brew install zsh-autosuggestions
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# brew install zsh-syntax-highlighting
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# gotta get syntax highlighting for less
#source $ZDOTDIR/plugins/colored-man-pages/colored-man-pages.plugin.zsh

# git clone https://github.com/hlissner/zsh-autopair /usr/local/share/zsh-autopair
source /usr/local/share/zsh-autopair/autopair.zsh

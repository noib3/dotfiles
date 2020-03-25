# ----------------------------- ZSH CONFIG FILE -----------------------------

# sudo touch /etc/zshenv && echo "export ZDOTDIR=~/.config/zsh" | sudo tee /etc/zshenv >/dev/null
# to load config file in this non-standard location

# ---------------------------------------------------------------------------
# Set/unset shell options

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
# Enable vi mode

bindkey -v

# bind zle widgets in viins (default) and vicmd modes
bindkey '^?' backward-delete-char
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^U' backward-kill-line
bindkey -M vicmd '^A' beginning-of-line
bindkey -M vicmd '^E' end-of-line
bindkey -M vicmd '^U' backward-kill-line

# yank to and paste from clipboard (pbpaste and pbcopy are macOS-specific tools)
# I'm gonna delete this since zsh-system-clipboard does what I need
yank-to-clipboard() {
    #
}
zle -N yank-to-clipboard
bindkey -M vicmd 'y' yank-to-clipboard

paste-from-clipboard-after() {
    LBUFFER=$LBUFFER${RBUFFER:0:1}
    RBUFFER=$(pbpaste)${RBUFFER:1}
    CURSOR=$(( $CURSOR + ${#$(pbpaste)} - 1 ))
}
zle -N paste-from-clipboard-after
bindkey -M vicmd 'p' paste-from-clipboard-after

paste-from-clipboard-inplace() {
    RBUFFER=$(pbpaste)$RBUFFER
    CURSOR=$(( $CURSOR + ${#$(pbpaste)} - 1 ))
}
zle -N paste-from-clipboard-inplace
bindkey -M vicmd 'P' paste-from-clipboard-inplace

# key input delay in hundredths of a second
KEYTIMEOUT=1

# change cursor shape depending on vi mode
zle-keymap-select() {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

zle-line-init() { zle-keymap-select 'beam' }

_fix_cursor() {
   echo -ne '\e[5 q'
}

precmd_functions+=(_fix_cursor)

# git clone https://github.com/softmoth/zsh-vim-mode /usr/local/share/zsh-vim-mode
#source /usr/local/share/zsh-vim-mode/zsh-vim-mode.plugin.zsh

#MODE_CURSOR_VICMD="#cfcfcf block"
#MODE_CURSOR_VIINS="#cfcfcf bar"

#MODE_INDICATOR_VIINS='%F{#9ec400}[I]%f'
#MODE_INDICATOR_VICMD='%F{#7aa6da}[N]%f'
#MODE_INDICATOR_VISUAL='%F{#b77ee0}[V]%f'

# ---------------------------------------------------------------------------
# Format prompt, with custom format for git directories

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%F{#ede845}$(repo) %F{#bbbbbb}on %F{#ede845} %b'
repo() { basename $(git remote get-url origin) | sed 's/.git//' }

precmd() {
    vcs_info
    RPROMPT="${vcs_info_msg_0_}"
}

PROMPT='%F{#e1e1e1}%1~ %F{#e69ab7}> %F{#cfcfcf}'

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

# git clone https://github.com/hlissner/zsh-autopair /usr/local/share/zsh-autopair
source /usr/local/share/zsh-autopair/autopair.zsh

# git clone https://github.com/kutsan/zsh-system-clipboard /usr/local/share/zsh-system-clipboard
source /usr/local/share/zsh-system-clipboard/zsh-system-clipboard.zsh

# ----------------------------- ZSH CONFIG FILE -----------------------------

# sudo touch /etc/zshenv && echo "export ZDOTDIR=~/.config/zsh" | sudo tee /etc/zshenv >/dev/null
# to load config file in this non-standard location

# ---------------------------------------------------------------------------
# Set/unset shell options

setopt PROMPT_SUBST
setopt MENU_COMPLETE
setopt AUTO_CD
setopt HISTIGNOREDUPS
setopt IGNORE_EOF
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
# Colors

# Regular
reg_dir_clr=#e1e1e1
reg_div_clr=#e69ab7

# Vi mode
vi_inst_clr=#9ec400
vi_norm_clr=#7aa6da
vi_visl_clr=#b77ee0
vi_visl_bg=#7aa6da
vi_visl_fg=#ffffff

# Git info
git_main_clr=#ede845
git_onbr_clr=#bbbbbb

# ---------------------------------------------------------------------------
# Enable vi mode

bindkey -v

# mode switching delay in hundredths of a second (default is 40)
# making it less then 30 seems to cause problems with surrounds
KEYTIMEOUT=30

# bind zle widgets in viins (default) and vicmd modes
bindkey '^?' backward-delete-char
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^U' backward-kill-line
bindkey -M vicmd '^A' beginning-of-line
bindkey -M vicmd '^E' end-of-line
bindkey -M vicmd '^U' backward-kill-line

# change cursor shape depending on vi mode
# zle-keymap-select is executed everytime the mode changes
function zle-keymap-select() {
    if [[ $KEYMAP = viins ]] || [[ $KEYMAP = main ]] || [[ $KEYMAP = '' ]]; then
        echo -ne '\e[5 q'
        RPROMPT="${vcs_info_msg_0_}  %F{$vi_inst_clr}[I]%f"
    elif [[ $KEYMAP = vicmd ]]; then
        echo -ne '\e[1 q'
        local active=${REGION_ACTIVE:-0}
        if [[ $active = 1 ]] || [[ $active = 2 ]]; then
            RPROMPT="${vcs_info_msg_0_}  %F{$vi_visl_clr}[V]%f"
        else
            RPROMPT="${vcs_info_msg_0_}  %F{$vi_norm_clr}[N]%f"
        fi
    fi
    zle reset-prompt
}
zle -N zle-keymap-select

ciao(){
    zle visual-mode
    zle zle-keymap-select
}
zle -N ciao
bindkey -M vicmd 'v' ciao

come(){
    zle deactivate-region
    zle zle-keymap-select
}
zle -N come
bindkey -M visual '^[' come

# ciao() {
#    #echo -ne '\e[5 q'
#    #echo 'ciao'
#    #RPROMPT="%F{$vi_inst_clr}[I]%f"
#}
#
## these functions are called after precmd
#precmd_functions+=(ciao)

# stripped down version of the vim-surround plugin implementation
# taken from 'https://github.com/softmoth/zsh-vim-mode'
function vim-mode-bindkey () {
    local -a maps
    local command

    while (( $# )); do
        [[ $1 = '--' ]] && break
        maps+=$1
        shift
    done
    shift

    command=$1
    shift

    function vim-mode-accum-combo () {
        typeset -g -a combos
        local combo="$1"; shift
        if (( $#@ )); then
            local cur="$1"; shift
            vim-mode-accum-combo "$combo$cur" "$@"
        else
            combos+="$combo"
        fi
    }

    local -a combos
    vim-mode-accum-combo '' "$@"
    for c in ${combos}; do
        for m in ${maps}; do
            bindkey -M $m "$c" $command
        done
    done
}

autoload -U select-bracketed
zle -N select-bracketed
for m in visual viopp; do
    for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
        vim-mode-bindkey $m -- select-bracketed $c
    done
done

autoload -U select-quoted
zle -N select-quoted
for m in visual viopp; do
    for c in {a,i}{\',\",\`}; do
        vim-mode-bindkey $m -- select-quoted $c
    done
done

autoload -Uz surround
zle -N delete-surround surround
zle -N change-surround surround
zle -N add-surround surround
vim-mode-bindkey vicmd  -- change-surround cs
vim-mode-bindkey vicmd  -- delete-surround ds
vim-mode-bindkey vicmd  -- add-surround    ys
vim-mode-bindkey visual -- add-surround    S

# background and foreground in vi visual and v-block modes
zle_highlight=(region:bg=$vi_visl_bg,fg=$vi_visl_fg)

# ---------------------------------------------------------------------------
# Format prompt, with custom format for git directories

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%F{$git_main_clr}$(repo) %F{$git_onbr_clr}on %F{$git_main_clr} %b%f'
repo() { basename $(git remote get-url origin) | sed 's/.git//' }

precmd() {
    vcs_info
    echo -ne '\e[5 q'
    RPROMPT="${vcs_info_msg_0_}  %F{$vi_inst_clr}[I]%f"
}

PROMPT='%F{$reg_dir_clr}%1~ %F{$reg_div_clr}>%f '

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

# Open lf
open_lf() {
    lf ~/Dropbox
    yabai -m window --close
}
zle -N open_lf
bindkey '^X^F' open_lf

# Edit alacritty config file
term_config() {
    $EDITOR ~/.config/alacritty/alacritty.yml
    printf '\e[5 q'
    if zle; then
        zle reset-prompt
    fi
}
zle -N term_config
bindkey '^X^T' term_config

# Use fd/fzf combo to edit a file, ...
fuzzy_edit() {
    dir=$(pwd)
    file=$(cd &&
            fd -0 --type f --ignore-file ~/.config/fd/fdignore --hidden |
            fzf --read0 --height=50% --layout=reverse) \
    && cd $dir && $EDITOR ~/$file
    printf '\e[5 q'
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_edit
bindkey '^X^E' fuzzy_edit

# ...to search a file, ...
fuzzy_search() {
#    dir=$(pwd)
#    file=$(cd &&
#            fd -0 --type f --ignore-file ~/.config/fd/fdignore --hidden |
#            fzf --read0 --height=50%) \
#    && cd $dir && $EDITOR ~/$file
#    printf '\e[5 q'
#    if zle; then
#        zle reset-prompt
#    fi
}
zle -N fuzzy_search
bindkey '^S' fuzzy_search

# ...or to change directory
fuzzy_cd() {
    local dir
    dir=$(cd &&
           fd -0 --type d --ignore-file ~/.config/fd/fdignore --hidden |
           fzf --read0 --height=50% --layout=reverse) \
    && cd ~/$dir
    printf '\e[H\e[3J'
    precmd
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_cd
bindkey '^X^D' fuzzy_cd

# clear the screen and echo current ndiet diet
ndiet_current(){
    clear
    ~/bin/ndiet/ndiet.py -c
    tput civis && read -s -k '?'
    if zle; then
        yabai -m window --close
    fi
    tput cnorm
}
zle -N ndiet_current
bindkey '^X^N' ndiet_current

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
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
ZSH_AUTOSUGGEST_STRATEGY=(history completion match_prev_cmd)

# brew install zsh-syntax-highlighting
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# git clone https://github.com/hlissner/zsh-autopair /usr/local/share/zsh-autopair
source /usr/local/share/zsh-autopair/autopair.zsh

# git clone https://github.com/kutsan/zsh-system-clipboard /usr/local/share/zsh-system-clipboard
source /usr/local/share/zsh-system-clipboard/zsh-system-clipboard.zsh

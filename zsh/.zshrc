# Filename:   zsh/.zshrc
# Github:     https://github.com/n0ibe/macOS-dotfiles
# Maintainer: Riccardo Mazzarini

# Shell options {{{

setopt HISTIGNOREDUPS
setopt MENU_COMPLETE
setopt PROMPT_SUBST
setopt IGNORE_EOF
setopt AUTO_CD

unsetopt CASE_GLOB
unsetopt BEEP

# }}}

# Colorscheme {{{

# Directory and delimiter colors in prompt
prompt_directory_color=#e1e1e1
prompt_delimiter_color=#e69ab7

# Git info colors
git_on_color=#bbbbbb
git_branch_color=#ede845

# Visual mode colors
vi_visual_mode_bg_color=#7aa6da
vi_visual_mode_fg_color=#ffffff

# }}}

# Vi mode {{{

bindkey -v

# Mode switching delay in hundredths of a second (default is 40)
# Making it less then 30 seems to cause problems with surrounds
KEYTIMEOUT=30

# Bind zle widgets in viins (default) mode
bindkey '^?' backward-delete-char
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^U' backward-kill-line

# Bind zle widgets in vicmd mode
bindkey -M vicmd '^A' beginning-of-line
bindkey -M vicmd '^E' end-of-line
bindkey -M vicmd '^U' backward-kill-line

# Change cursor shape depending on vi mode
# zle-keymap-select() is executed everytime the mode changes
zle-keymap-select() {
    if [[ $KEYMAP = viins ]] || [[ $KEYMAP = main ]]; then
        echo -ne '\e[5 q'
    elif [[ $KEYMAP = vicmd ]]; then
        echo -ne '\e[1 q'
    fi
}
zle -N zle-keymap-select

# Background and foreground colors in visual mode
zle_highlight=(region:bg=$vi_visual_mode_bg_color,fg=$vi_visual_mode_fg_color)

# Enable vim-surround-like functionalities in vi mode
autoload -U select-bracketed
zle -N select-bracketed
for m in visual viopp; do
    for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
        bindkey -M $m $c select-bracketed
    done
done

autoload -U select-quoted
zle -N select-quoted
for m in visual viopp; do
    for c in {a,i}{\',\",\`}; do
        bindkey -M $m $c select-quoted
    done
done

autoload -Uz surround
zle -N delete-surround surround
zle -N change-surround surround
zle -N add-surround surround
bindkey -M vicmd cs change-surround
bindkey -M vicmd ds delete-surround
bindkey -M vicmd ys add-surround
bindkey -M visual S add-surround

# }}}

# Prompt {{{

# Set prompt with support for git infos in directories under version control
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %F{$git_on_color}on %F{$git_branch_color} %b%f'
PROMPT='%F{$prompt_directory_color}%1~${vcs_info_msg_0_} %F{$prompt_delimiter_color}>%f '

# Get git infos and reset cursor to its insert mode shape
# precmd() is executed before each prompt
precmd() {
    vcs_info
    printf '\e[5 q'
}

# }}}

# ZLE Widgets {{{

# Close the terminal window
close-window() {
    yabai -m window --close
}
zle -N close-window
bindkey '^W' close-window

# Fuzzy search a file and open it in $EDITOR
function fuzzy_edit() {
    filename="$(fzf --height=40% </dev/tty)" \
        && $EDITOR ~/"$filename" \
        && fc -R =(print "$EDITOR ~/$filename") \
        && print -s "$EDITOR ~/$filename"# \
        && printf '\e[5 q'
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_edit
bindkey '^X^E' fuzzy_edit

# Fuzzy search a file and add it to the line buffer
function fuzzy_search() {
    filename="$(fzf --height=40% </dev/tty)" && LBUFFER="$LBUFFER~/$filename "
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_search
bindkey '^S' fuzzy_search

# Fuzzy search a directory and cd into it
function fuzzy_cd() {
    dirname="$(fd . --base-directory ~ --type d --hidden --color always |
                sed "s/\[1;34m/\[1;90m/g; s/\(.*\)\[1;90m/\1\[1;34m/" |
                fzf --height=40%)" \
    && cd ~/$dirname && precmd
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_cd
bindkey '^X^D' fuzzy_cd

# }}}

# Tab autocompletion {{{

autoload -Uz compinit
compinit -d ~/.cache/zsh/zcompdump-$ZSH_VERSION
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
_comp_options+=(globdots)
set +o list_types

# }}}

# Aliases {{{

alias ls='ls -Avh --color --quoting-style=literal --group-directories-first'
alias grep='grep --color=auto'
alias rm='rm -i'

alias reboot='osascript -e "tell app \"System Events\" to restart"'
alias shutdown='osascript -e "tell app \"System Events\" to shut down"'

# }}}

# Miscellaneous {{{

# Disable ctrl+s
stty -ixon

# Custom history file location
HISTFILE=$HOME/.cache/zsh/zsh_history

# Clear the screen automatically when the directory is changed
# chpwd() is executed every time the current directory changes
chpwd() { printf '\e[H\e[3J' }

# Use a single 'c' to clear the screen without adding it to the command history
accept-line() case $BUFFER in
  (c) printf '\e[H\e[3J'; BUFFER=; zle redisplay;;
  (*) zle .accept-line
esac
zle -N accept-line
# This alias is just so that fast-syntax-highlighting doesn't color it in red
alias c=''

# }}}

# Plugins {{{

# Use fzf for tab completion
source /usr/local/share/fzf-tab/fzf-tab.plugin.zsh

# Syntax highlighting
source /usr/local/share/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# Autosuggestions based on command history
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Use system clipboard when yanking and pasting in vi mode
source /usr/local/share/zsh-system-clipboard/zsh-system-clipboard.zsh

# Autopair parenthesis and quotation marks
source /usr/local/share/zsh-autopair/autopair.zsh

# }}}

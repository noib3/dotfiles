# Set colorscheme
source $ZDOTDIR/themes/default.zsh

# Source aliases
source $ZDOTDIR/.zaliases

# Set/unset shell options
setopt HISTIGNOREDUPS
setopt MENU_COMPLETE
setopt PROMPT_SUBST
setopt IGNORE_EOF
setopt AUTO_CD
unsetopt CASE_GLOB
unsetopt BEEP

# Custom history file location
export HISTFILE=$HOME/.cache/zsh/zsh_history

# TODO: add functions to precmd like this
# autoload add-zsh-hook
# add-zsh-hook precmd <function_name>

# Enable vi mode
bindkey -v

# Set mode switching delay in hundredths of a second (default is 40)
# Making it less then 30 seems to cause problems with surrounds
KEYTIMEOUT=30

# Bind zle widgets in viins (default) and vicmd mode
bindkey '^?' backward-delete-char
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^U' backward-kill-line
bindkey -M vicmd '^A' beginning-of-line
bindkey -M vicmd '^E' end-of-line
bindkey -M vicmd '^U' backward-kill-line

# Background and foreground colors in visual mode
zle_highlight=(region:bg=$vi_visual_bg,fg=$vi_visual_fg)

# Change cursor shape depending on vi mode
# zle-keymap-select is executed everytime the mode changes
zle-keymap-select() {
    if [[ $KEYMAP = viins ]] || [[ $KEYMAP = main ]] || [[ $KEYMAP = '' ]]; then
        echo -ne '\e[5 q'
    elif [[ $KEYMAP = vicmd ]]; then
        echo -ne '\e[1 q'
    fi
}
zle -N zle-keymap-select

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

# Set prompt with support for git infos in directories under version control
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %F{$git_onbr_clr}on %F{$git_main_clr} %b%f'
PROMPT='%F{$reg_dir_clr}%1~${vcs_info_msg_0_} %F{$reg_div_clr}>%f '

# Get git infos and reset cursor to its insert mode shape
# precmd is executed before each prompt
precmd() {
    vcs_info
    printf '\e[5 q'
}

# Clear the screen automatically when the directory is changed
# chpwd is executed every time the current directory changes
chpwd() {
    printf '\e[H\e[3J'
}

# Disable ctrl+s
stty -ixon

# Close window
close_window() {
    yabai -m window --close
}
zle -N close_window
bindkey '^W' close_window

# Use fd and fzf to edit a file..
# fc -R adds the command to the history without needing to issue a command
# (see here https://unix.stackexchange.com/questions/583443/adding-a-string-to-the-zsh-history)
# however it seems like that alone doesn't save the command between sessions, and
# that's what print -s is for. Finally, printf '\e[5 q' restores the cursor to be
# a line, which is needed if you leave (n)vim in normal mode with the block cursor
function fuzzy_edit() {
    filename=$(fd . ~ --type f --hidden --color always |
                 sed "s=.*noibe/==g;s/\[1;34m/\[90m/g" |
                 fzf --height=40% --color="hl:-1,hl+:-1") \
    && $EDITOR ~/$filename && fc -R =(print "${EDITOR} ~/${filename}") \
    && print -s "${EDITOR} ~/${filename}" && printf '\e[5 q'
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_edit
bindkey '^X^E' fuzzy_edit

# ..search a filename and add it to the line buffer..
function fuzzy_search() {
    filename=$(fd . ~ --type f --hidden --color always |
                 sed "s=.*noibe/==g;s/\[1;34m/\[90m/g" |
                 fzf --height=40% --color="hl:-1,hl+:-1") \
    && LBUFFER="$LBUFFER~/$filename "
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_search
bindkey '^S' fuzzy_search

# ..or to change directory
function fuzzy_cd() {
    dirname=$(fd . ~ --type d --hidden --color always | sed "s=.*noibe/==g" |
              fzf --height=40%) \
    && cd ~/$dirname && precmd
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_cd
bindkey '^X^D' fuzzy_cd

# A single 'c' clears the screen without being added to the command history
# The alias is just so that fast-syntax-highlighting doesn't color it in red
accept-line() case $BUFFER in
  (c) printf '\e[H\e[3J'; BUFFER=; zle redisplay;;
  (*) zle .accept-line
esac
zle -N accept-line
alias c=''

# Tab autocompletion
autoload -Uz compinit
compinit -d ~/.cache/zsh/zcompdump-$ZSH_VERSION
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
_comp_options+=(globdots)
set +o list_types # hide trailing /

# git clone https://github.com/Aloxaf/fzf-tab /usr/local/share/fzf-tab
source /usr/local/share/fzf-tab/fzf-tab.plugin.zsh

# git clone https://github.com/zdharma/fast-syntax-highlighting /usr/local/share/fast-syntax-highlighting
source /usr/local/share/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# brew install zsh-autosuggestions
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# git clone https://github.com/kutsan/zsh-system-clipboard /usr/local/share/zsh-system-clipboard
source /usr/local/share/zsh-system-clipboard/zsh-system-clipboard.zsh

# git clone https://github.com/hlissner/zsh-autopair /usr/local/share/zsh-autopair
source /usr/local/share/zsh-autopair/autopair.zsh

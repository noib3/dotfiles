# ------------------------- ZSH CONFIG FILE -------------------------

# Set colorscheme
source ~/.config/zsh/themes/default.zsh

PATH=/usr/local/opt/coreutils/libexec/gnubin
PATH=$PATH:/usr/local/opt/findutils/libexec/gnubin
PATH=$PATH:/usr/local/opt/python@3.8/bin
PATH=$PATH:/Library/TeX/texbin
PATH=$PATH:/usr/local/bin
PATH=$PATH:/usr/sbin
PATH=$PATH:/usr/bin
PATH=$PATH:/sbin
PATH=$PATH:/bin
export PATH

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
PROMPT='%F{$reg_dir_clr}[%n %F{$git_onbr_clr}in %F{$reg_dir_clr}%1~${vcs_info_msg_0_}] %F{$reg_div_clr}>%f '

# Get git infos and reset cursor to its insert mode shape
# precmd is executed before each prompt
precmd() {
    vcs_info
    echo -ne '\e[5 q'
}

# Clear the screen automatically when the directory is changed
# chpwd is executed every time the current directory changes
chpwd() { printf '\e[H\e[3J' }

# Tab autocompletion
autoload -Uz compinit && compinit -d ~/.cache/zsh/zcompdump-$ZSH_VERSION
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zmodload zsh/complist
_comp_options+=(globdots)

# Disable ctrl+s
stty -ixon

# Close window
close_window() {
    yabai -m window --close
}
zle -N close_window
bindkey '^W' close_window

# Use fd/fzf combo to edit a file..
fuzzy_edit() {
    file=$(fd . ~ -0 --type f --hidden | sed "s=$HOME/==g" |
              fzf --read0 --height=50% --layout=reverse) \
    && $EDITOR ~/$file && printf '\e[5 q'
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_edit
bindkey '^X^E' fuzzy_edit

# ..search a file..
fuzzy_search() {
    file=$(fd . ~ -0 --type f --hidden | sed "s=$HOME/==g" |
              fzf --read0 --height=50% --layout=reverse) \
    && LBUFFER="$LBUFFER~/$file "
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_search
bindkey '^S' fuzzy_search

# ..or to change directory
fuzzy_cd() {
    dir=$(fd . ~ -0 --type d --hidden | sed "s=$HOME/==g" |
             fzf --read0 --height=50% --layout=reverse) \
    && cd ~/$dir && precmd
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_cd
bindkey '^X^D' fuzzy_cd

# Clear the screen and echo current diet
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

# Aliases for GUI programs
alias alacritty='/Applications/Alacritty.app/Contents/MacOS/alacritty'
alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'

# Aliases to specify program options
alias ls='ls -Ah --color --quoting-style=literal --group-directories-first'
alias cal='calcurse -C ~/.config/calcurse -D ~/.local/share/calcurse'
alias tmux='tmux -f ~/.config/tmux/tmux.conf'
alias brew='HOMEBREW_NO_AUTO_UPDATE=1 brew'
alias grep='grep --color=auto'
alias tree='tree -aN'
alias rm='rm -i'

# Aliases for user scripts
alias -g 2d2small='~/Dropbox/2d2small/2d2small.sh'
alias -g ndiet='~/Bin/ndiet/ndiet.py'
alias -g committed='~/scripts/committed.sh'
alias -g ufetch='~/scripts/ufetch.sh'
alias -g peek='~/scripts/peek.py'
alias -g tfin='~/scripts/retired/tfin/oldtfin.sh'
alias -g Omega='~/scripts/retired/Omega.py'
alias -g tmd='~/scripts/retired/tmd.sh'

# Other aliases
alias reboot='osascript -e "tell app \"System Events\" to restart"'

# A single 'c' clears the screen without being added to the command history
# The alias is just so that zsh-syntax-highlighting doesn't color it in red
accept-line() case $BUFFER in
  (c) printf '\e[H\e[3J'; BUFFER=; zle redisplay;;
  (*) zle .accept-line
esac
zle -N accept-line
alias c=''

# brew install zsh-syntax-highlighting
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# brew install zsh-autosuggestions
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# git clone https://github.com/kutsan/zsh-system-clipboard /usr/local/share/zsh-system-clipboard
source /usr/local/share/zsh-system-clipboard/zsh-system-clipboard.zsh

# git clone https://github.com/hlissner/zsh-autopair /usr/local/share/zsh-autopair
source /usr/local/share/zsh-autopair/autopair.zsh

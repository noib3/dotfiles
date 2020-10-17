# Set/unset options
setopt HISTIGNOREDUPS
setopt MENU_COMPLETE
setopt PROMPT_SUBST
setopt IGNORE_EOF
unsetopt CASE_GLOB
unsetopt BEEP

# Source the current theme
source $ZDOTDIR/themes/afterglow

# Vi mode
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
zle_highlight=(region:bg=$color_selection_bg,fg=$color_selection_fg)

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
zstyle ':vcs_info:git:*' formats ' on %F{$color_git_branch} %b%f'
PROMPT='%F{$color_prompt_directory}%1~${vcs_info_msg_0_} %F{$color_prompt_separator}>%f '

# Get git infos and reset cursor to its insert mode shape
# precmd() is executed before each prompt
precmd() {
  vcs_info
  printf '\e[5 q'
}

# Close the terminal window
close-window() {
  yabai -m window --close
}
zle -N close-window
bindkey '^W' close-window

# Fuzzy search a file and open it in $EDITOR
function fuzzy_edit() {
  local filename
  filename="$(fzf --height=8 </dev/tty)" \
  && $EDITOR ~/"$filename" \
  && fc -R =(print "$EDITOR ~/$filename") \
  && print -s "$EDITOR ~/$filename" \
  && printf '\e[5 q'
  zle && zle reset-prompt
}
zle -N fuzzy_edit
bindkey '^X^E' fuzzy_edit

# Fuzzy search a file and add it to the line buffer
function fuzzy_search() {
  local filename
  filename="$(fzf --height=8 </dev/tty)" \
  && LBUFFER="$LBUFFER~/$(echo $filename | sed 's/ /\\ /g')"
  zle && zle reset-prompt
}
zle -N fuzzy_search
bindkey '^S' fuzzy_search

# Fuzzy search a command from the history and add it to the line buffer and to
# the clipboard. I can't bind it to '^H' because that's already assigned to a
# window resize command in skhd.
function fuzzy_history() {
  local command
  command="$(fc -l -1 -999 |
             sed 's/^\s*[0-9]*\s*//g' |
             fzf --height=8 --color=dark)" \
  && LBUFFER="$command" \
  && echo -n "$command" | pbcopy
  zle && zle reset-prompt
}
zle -N fuzzy_history
bindkey '^X^F' fuzzy_history

# Fuzzy search a directory and cd into it
function fuzzy_cd() {
  local dirname
  dirname="$(fd . --base-directory ~ --type d --hidden --color always |
             sed 's/\[1;34m/\[1;90m/g; s/\(.*\)\[1;90m/\1\[1;34m/' |
             fzf --height=8)" \
  && cd ~/$dirname \
  && precmd
  zle && zle reset-prompt
}
zle -N fuzzy_cd
bindkey '^X^D' fuzzy_cd

# Tab autocompletion
autoload -Uz compinit
compinit -d $HOME/.cache/zsh/zcompdump-$ZSH_VERSION
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} \
                       cache-path $HOME/.cache/zsh/.zcompcache
_comp_options+=(globdots)
set +o list_types

# Aliases
alias ls='ls -Avh --color --quoting-style=literal --group-directories-first'
alias grep='grep --color=auto'
alias reboot='osascript -e "tell app \"System Events\" to restart"'
alias shutdown='osascript -e "tell app \"System Events\" to shut down"'

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

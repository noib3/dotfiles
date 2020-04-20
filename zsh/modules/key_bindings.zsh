# Unbind 'Ctrl + S'
stty -ixon

# Close terminal window
close_window() {
    yabai -m window --close
}
zle -N close_window
bindkey '^W' close_window

# Edit terminal config
term_config() {
    $EDITOR ~/.config/alacritty/alacritty.yml
    printf '\e[5 q'
    if zle; then
        zle reset-prompt
    fi
}
zle -N term_config
bindkey '^X^T' term_config

# Use fd/fzf combo to edit a file..
fuzzy_edit() {
    dir=$(pwd)
    file=$(builtin cd &&
            fd -0 --type f --ignore-file ~/.config/fd/fdignore --hidden |
            fzf --read0 --height=50% --layout=reverse) \
    && builtin cd $dir && $EDITOR ~/$file && printf '\e[5 q'
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_edit
bindkey '^X^E' fuzzy_edit

# ..search a file..
fuzzy_search() {
    dir=$(pwd)
    file=$(builtin cd &&
            fd -0 --type f --ignore-file ~/.config/fd/fdignore --hidden |
            fzf --read0 --height=50% --layout=reverse) \
    && builtin cd $dir && LBUFFER="$LBUFFER~/$file "
    if zle; then
        zle reset-prompt
    fi
}
zle -N fuzzy_search
bindkey '^S' fuzzy_search

# ..or to change directory
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
    #ls
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

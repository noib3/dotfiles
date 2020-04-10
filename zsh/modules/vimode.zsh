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

# background and foreground colors in visual and v-block modes
zle_highlight=(region:bg=$vi_visl_bg,fg=$vi_visl_fg)

# change cursor shape depending on vi mode
# zle-keymap-select is executed everytime the mode changes
function zle-keymap-select() {
    if [[ $KEYMAP = viins ]] || [[ $KEYMAP = main ]] || [[ $KEYMAP = '' ]]; then
        echo -ne '\e[5 q'
    elif [[ $KEYMAP = vicmd ]]; then
        echo -ne '\e[1 q'
    fi
    zle reset-prompt
}
zle -N zle-keymap-select

# stripped down version of the vim-surround plugin implementation
# taken from 'https://github.com/softmoth/zsh-vim-mode'
#function vim-mode-bindkey () {
#    local -a maps
#    local command
#
#    while (( $# )); do
#        [[ $1 = '--' ]] && break
#        maps+=$1
#        shift
#    done
#    shift
#
#    command=$1
#    shift
#
#    function vim-mode-accum-combo () {
#        typeset -g -a combos
#        local combo="$1"; shift
#        if (( $#@ )); then
#            local cur="$1"; shift
#            vim-mode-accum-combo "$combo$cur" "$@"
#        else
#            combos+="$combo"
#        fi
#    }
#
#    local -a combos
#    vim-mode-accum-combo '' "$@"
#    for c in ${combos}; do
#        for m in ${maps}; do
#            bindkey -M $m "$c" $command
#        done
#    done
#}

autoload -U select-bracketed
zle -N select-bracketed
for m in visual viopp; do
    for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
        bindkey -M $m "$c" select-bracketed
        #vim-mode-bindkey $m -- select-bracketed $c
    done
done

autoload -U select-quoted
zle -N select-quoted
for m in visual viopp; do
    for c in {a,i}{\',\",\`}; do
        bindkey -M $m "$c" select-quoted
        #vim-mode-bindkey $m -- select-quoted $c
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
#vim-mode-bindkey vicmd  -- change-surround cs
#vim-mode-bindkey vicmd  -- delete-surround ds
#vim-mode-bindkey vicmd  -- add-surround    ys
#vim-mode-bindkey visual -- add-surround    S

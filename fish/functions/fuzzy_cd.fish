function fuzzy_cd --description "Fuzzy search a directory in ~ and cd into it"
    set -l dirname (eval (echo $FZF_DEFAULT_COMMAND | sed "s/-t f/-t d/") |
                    sed "s/\(.*\)\[1;90m/\1\[1;34m/" |
                    fzf --height=8) \
    && cd ~/$dirname
    commandline -f repaint
end

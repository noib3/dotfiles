set fish_greeting ""

fish_vi_key_bindings

function reset_line_cursor --on-event fish_prompt
    printf "\e[5 q"
end

alias ls="ls -Avh --color --quoting-style=literal --group-directories-first"

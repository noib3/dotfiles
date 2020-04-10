autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%F{$git_main_clr}$(repo) %F{$git_onbr_clr}on %F{$git_main_clr} %b%f'
repo() { basename $(git remote get-url origin) | sed 's/.git//' }

precmd() {
    vcs_info
    echo -ne '\e[5 q'
    RPROMPT="${vcs_info_msg_0_}"
}

PROMPT='%F{$reg_dir_clr}%1~ %F{$reg_div_clr}>%f '

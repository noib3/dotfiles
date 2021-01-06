alias ls="ls -Ahv --color --file-type --group-directories-first \
--quoting-style=literal"
alias grep="grep --ignore-case --color=auto"
alias wget="wget --hsts-file=~/.cache/wget/wget-hsts"

alias reboot='osascript -e "tell app \"System Events\" to restart"'
alias shutdown='osascript -e "tell app \"System Events\" to shut down"'

alias pipupg="pip3 list --outdated --format=freeze | grep -v '^\-e' | \
cut -d = -f 1 | xargs -n1 pip3 install -U"

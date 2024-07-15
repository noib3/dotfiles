set -l dirname (eval "$FZF_ALT_C_COMMAND" | eval "fzf $FZF_ALT_C_OPTS")
test -z "$dirname" || cd "$HOME/$dirname"

emit fish_prompt
commandline -f repaint

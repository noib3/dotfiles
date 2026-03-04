set -l dirname (eval "$FZF_ALT_C_COMMAND" | eval "fzf $FZF_ALT_C_OPTS")

if test -n "$dirname"
  if string match -qr '^/' -- "$dirname"
    cd "$dirname"
  else
    cd "$HOME/$dirname"
  end
end

emit fish_prompt
commandline -f repaint

set -l dirname
set -l reload_command (string escape -- "$FZF_ALT_C_COMMAND")

set dirname (
  printf "" \
    | eval "fzf $FZF_ALT_C_OPTS --bind start:reload:$reload_command"
)

if test -n "$dirname"
  if string match -qr '^/' -- "$dirname"
    cd "$dirname"
  else
    cd "$HOME/$dirname"
  end
end

emit fish_prompt
commandline -f repaint

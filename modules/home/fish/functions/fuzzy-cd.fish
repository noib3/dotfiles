set -l dirname (fuzzy-cd-directory)

if test -n "$dirname"
  cd "$dirname"
end

emit fish_prompt
commandline -f repaint

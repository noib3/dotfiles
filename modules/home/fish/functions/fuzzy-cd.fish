set -l dirname (fuzzy-cd-directory)

if test -n "$dirname"
  cd "$dirname"
end

commandline -f repaint

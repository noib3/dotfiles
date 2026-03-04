set -l root

if git status &>/dev/null
  set root (git rev-parse --show-toplevel)
else
  set root "$HOME"
end

set -l root_for_preview (string escape --style=script -- "$root")

set -l selected_files (
  lf-recursive "$root" \
    | fzf --multi --prompt="Edit> " --preview="preview $root_for_preview/{}"
)

if test (count $selected_files) -gt 0
  set -l escaped_paths

  for filename in $selected_files
    set -a escaped_paths (string escape -- "$root/$filename")
  end

  set -l cmd (string join " " "$EDITOR" $escaped_paths)
  commandline "$cmd"
  commandline -f execute
end

commandline -f repaint

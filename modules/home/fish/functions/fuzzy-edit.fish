set -l selected_files (fuzzy-edit-files)

if test (count $selected_files) -gt 0
  set -l escaped_paths

  for filename in $selected_files
    set -a escaped_paths (string escape -- "$filename")
  end

  set -l cmd (string join " " "$EDITOR" $escaped_paths)
  commandline "$cmd"
  commandline -f repaint
  commandline -f execute
else
  commandline -f repaint
end

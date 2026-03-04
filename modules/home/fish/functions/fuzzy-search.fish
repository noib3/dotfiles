set -l selected_files (
  fzf --multi --prompt='Paste> ' --preview="preview $HOME/{}"
)

if test (count $selected_files) -gt 0
  set -l escaped_paths

  for filename in $selected_files
    if string match -qr '^/' -- "$filename"
      set -a escaped_paths (string escape -- "$filename")
    else
      set -a escaped_paths (string escape -- "$HOME/$filename")
    end
  end

  commandline --insert (string join ' ' $escaped_paths)
end

commandline -f repaint

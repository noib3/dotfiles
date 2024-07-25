# The path to the given directory.
local dir_path="$1"

# The color of the directories in fd's output in ANSI format, e.g.
# "1;38;2;97;175;239".
local old_dirs_col="$2"

# The new color of the directories in ANSI format.
local new_dirs_col="$3"

fd --base-directory="$dir_path" --no-ignore --hidden --strip-cwd-prefix --type=f --color=always \
  | sort -r \
  | sed "s|\x1b\[${old_dirs_col}m|\x1b\[${new_dirs_col}m|g"

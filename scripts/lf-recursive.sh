# The path to the given directory.
local DIR_PATH="$1"

# The color of the directories in fd's output in ANSI format, e.g.
# "1;38;2;97;175;239".
local OLD_DIRS_COL="$2"

# The new color of the directories in ANSI format.
local NEW_DIRS_COL="$3"

fd --base-directory="$DIR_PATH" --hidden --strip-cwd-prefix --type=f --color=always \
  | sort -r \
  | sed "s|\x1b\[${OLD_DIRS_COL}m|\x1b\[${NEW_DIRS_COL}m|g"

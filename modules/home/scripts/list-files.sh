usage() {
  echo "usage: list-files [--frecent-first] <dir>" >&2
  exit 1
}

FRECENT_FIRST=false

if [ "${1-}" = "--frecent-first" ]; then
  FRECENT_FIRST=true
  shift
fi

[ $# -eq 1 ] || usage

if [ ! -d "$1" ]; then
  echo "error: the argument is not a path to a directory" >&2
  exit 1
fi

# The absolute path to the given directory.
DIR_PATH="$(cd "$1" && pwd)"

DOCS_NAME="${DOCS_DIR##*/}"

# Prints the frecent files under the given directory, from the most to the least
# frecent, colored like the ones printed by fd.
emit_frecent_files() {
  local frecent_files=()
  local parent_dirs=()
  local -A seen_parent_dirs=()

  while IFS= read -r path; do
    case "$path" in
      "$DIR_PATH"/*) ;;
      *) continue ;;
    esac

    local relative_path="${path#"$DIR_PATH"/}"
    local parent_dir="."

    if [[ "$relative_path" == */* ]]; then
      parent_dir="${relative_path%/*}"
    fi

    frecent_files+=("$relative_path")

    if [ -z "${seen_parent_dirs["$parent_dir"]-}" ]; then
      seen_parent_dirs["$parent_dir"]=1
      parent_dirs+=("$parent_dir")
    fi
  done < <(frecency list files)

  [ ${#frecent_files[@]} -gt 0 ] || return 0

  # A regex matching the absolute path of any of the frecent files.
  local regex
  regex="^($(
    printf '%s\n' "${frecent_files[@]/#/"$DIR_PATH/"}" |
      sed 's/[][\\.+*?(){}|^$#&~-]/\\&/g' |
      paste -s -d '|'
  ))\$"

  fd --base-directory="$DIR_PATH" --hidden --type=f --color=always \
    --max-depth=1 --full-path --regex "$regex" -- "${parent_dirs[@]}" |
    sed "s|^\x1b\[${OLD_DIRS_COL}m\./\x1b\[0m||" |
    awk '
      FILENAME != "-" { rank[$0] = FNR; num_frecent = FNR; next }
      {
        key = $0
        gsub(/\x1b\[[0-9;]*m/, "", key)
        if (key in rank) line[rank[key]] = $0
      }
      END { for (i = 1; i <= num_frecent; i++) if (i in line) print line[i] }
    ' <(printf '%s\n' "${frecent_files[@]}") -
}

emit_files() {
  if [ "$FRECENT_FIRST" = true ]; then
    emit_frecent_files
  fi

  fd --base-directory="$DIR_PATH" --hidden --strip-cwd-prefix --type=f --color=always

  # If the documents directory is a symlink, scan it explicitly since fd doesn't
  # follow symlinks.
  if [ -L "$DIR_PATH/$DOCS_NAME" ]; then
    fd --base-directory="$DOCS_DIR" --hidden --strip-cwd-prefix --type=f --color=always |
      sed -u "s|^|"$'\x1b['"${OLD_DIRS_COL}m${DOCS_NAME}/|"
  fi
}

recolor_dirs() {
  sed -u "s|\x1b\[${OLD_DIRS_COL}m|\x1b\[${NEW_DIRS_COL}m|g"
}

if [ "$FRECENT_FIRST" = true ]; then
  emit_files |
    recolor_dirs |
    awk '{ key = $0; gsub(/\x1b\[[0-9;]*m/, "", key) } !seen[key]++ { print; fflush() }'
else
  emit_files | recolor_dirs
fi

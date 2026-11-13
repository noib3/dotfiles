usage() {
  echo "usage: list-dirs [--frecent-first] <dir>" >&2
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

# Prints the frecent directories under the given directory, from the most to
# the least frecent.
emit_frecent_dirs() {
  frecency list dirs | while IFS= read -r path; do
    case "$path" in
      "$DIR_PATH"/*) printf '%s\n' "${path#"$DIR_PATH"/}" ;;
    esac
  done
}

# Prints the directories under the given one, prefixed with the given path.
emit_subdirs() {
  fd --base-directory="$1" --hidden --strip-cwd-prefix --type=d --color=never |
    awk -v prefix="$2" '{ sub(/\/$/, ""); print prefix $0; fflush() }'
}

# Prints a root and the directories under it, relative to the given directory
# if the root is in it.
emit_root() {
  local root="$1"
  [ -d "$root" ] || return 0

  local path="$root"
  case "$root" in
    "$DIR_PATH"/*) path="${root#"$DIR_PATH"/}" ;;
  esac

  printf '%s\n' "$path"
  emit_subdirs "$root" "$path/"
}

emit_dirs() {
  if [ "$FRECENT_FIRST" = true ]; then
    emit_frecent_dirs
  fi

  # The home directory is only scanned under its roots.
  if [ "$DIR_PATH" = "$HOME" ]; then
    for root in "${HOME_ROOTS[@]}"; do
      emit_root "$root"
    done
  else
    emit_subdirs "$DIR_PATH" ""
  fi
}

# Drops the duplicates, and grays out the parent directories of each path.
emit_dirs |
  awk -v dirs="$DIRS_COL" -v grayed_out="$GRAYED_OUT_DIRS_COL" '
    seen[$0]++ { next }
    {
      parent = ""
      name = $0
      if (match($0, /.*\//)) {
        parent = substr($0, 1, RLENGTH)
        name = substr($0, RLENGTH + 1)
      }
      if (parent != "") printf "\033[%sm%s\033[0m", grayed_out, parent
      printf "\033[%sm%s\033[0m\n", dirs, name
      fflush()
    }
  '

# Prints the given directory path with its parent directories grayed out.
print_dir() {
  local dir="$1"

  if [[ "$dir" == */* ]]; then
    printf '\e[%sm%s/\e[0m' "$COL_GRAYED_OUT_DIRS" "${dir%/*}"
  fi

  printf '\e[%sm%s\e[0m\n' "$COL_DIRS" "${dir##*/}"
}

emit_dir_tree() {
  root="$1"

  if [ ! -d "$root" ]; then
    return
  fi

  case "$root" in
    "$HOME"/*)
      prefix="${root#"$HOME"/}"
      ;;
    *)
      prefix="$root"
      ;;
  esac

  print_dir "$prefix"

  (cd "$root" && fd --strip-cwd-prefix --hidden --type=d --color=always) |
    sed -u "s|^|"$'\x1b['"${COL_DIRS}m$prefix/|"
}

# Prints the frecent directories under the home directory.
emit_frecent_dirs() {
  frecency list dirs | while IFS= read -r dir; do
    case "$dir" in
      "$HOME"/*)
        print_dir "${dir#"$HOME"/}"
        ;;
    esac
  done
}

{
  emit_frecent_dirs

  for root in "${ROOTS[@]}"; do
    emit_dir_tree "$root"
  done |
    sed -u "s|\(.*\)\x1b\[${COL_DIRS}m/|\1|" |
    sed -u "s|\x1b\[${COL_DIRS}m|\x1b\[${COL_GRAYED_OUT_DIRS}m|g" |
    sed -u "s|\(.*\)\x1b\[${COL_GRAYED_OUT_DIRS}m|\1\x1b\[${COL_DIRS}m|"
} |
  awk '{ key = $0; gsub(/\x1b\[[0-9;]*m/, "", key) } !seen[key]++ { print; fflush() }'

if [ $# -gt 1 ]; then
  printf '%s\n' "$0: usage: $0 [directory]" >&2
  exit 2
fi

input_directory=${1:-.}
if ! directory=$(canonical_dir "$input_directory"); then
  printf '%s\n' "$0: directory does not exist: $input_directory" >&2
  exit 2
fi

if ! command -v cargo >/dev/null 2>&1; then
  exit 1
fi

if ! cargo_toml=$(
  cd "$directory"
  cargo locate-project --workspace --message-format plain 2>/dev/null
); then
  exit 1
fi

project_root=$(canonical_dir "$(dirname "$cargo_toml")") || {
  exit 2
}

hash_input=$(stable_hash_input "$project_root")

if ! hash=$(hash_value "$hash_input"); then
  exit 2
fi

state_home=${XDG_STATE_HOME:-$HOME/.local/state}
project_basename=$(sanitize_basename "$(basename "$project_root")")
target_dir=$state_home/cargo/$hash-$project_basename/target

if ! mkdir -p "$target_dir"; then
  exit 2
fi

printf '%s' "$target_dir"

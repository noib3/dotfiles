VALID_SHELLS='fish'

shell_quote_fish() {
  value=$1
  printf '%s' "$value" | sed "s/'/'\\\\''/g; 1 s/^/'/; \$ s/\$/'/"
}

emit_unset_fish() {
  printf '%s\n' 'if set -q __cargo_target_dir_dynamic; set -e CARGO_TARGET_DIR; set -e __cargo_target_dir_dynamic; end'
}

emit_set_fish() {
  target_dir=$1
  quoted_target_dir=$(shell_quote_fish "$target_dir")
  printf 'set -gx CARGO_TARGET_DIR %s\n' "$quoted_target_dir"
  printf '%s\n' 'set -gx __cargo_target_dir_dynamic 1'
}

emit_unset() {
  case "$shell" in
    fish)
      emit_unset_fish
      ;;
  esac
}

emit_set() {
  target_dir=$1

  case "$shell" in
    fish)
      emit_set_fish "$target_dir"
      ;;
  esac
}

shell=
if [ $# -ne 2 ]; then
  printf '%s\n' "$0: usage: $0 --shell <shell>" >&2
  exit 2
fi

if [ "$1" != "--shell" ]; then
  printf '%s\n' "$0: expected --shell as first argument" >&2
  exit 2
fi

shell=$2

is_valid_shell=false
for valid_shell in $VALID_SHELLS; do
  if [ "$shell" = "$valid_shell" ]; then
    is_valid_shell=true
    break
  fi
done

if [ "$is_valid_shell" != true ]; then
  printf '%s\n' "$0: unsupported shell '$shell' (expected one of: $VALID_SHELLS)" >&2
  exit 2
fi

is_dynamic_cargo_target_dir=false
if [ "${__cargo_target_dir_dynamic+x}" = x ]; then
  is_dynamic_cargo_target_dir=true
fi

if ! command -v cargo >/dev/null 2>&1; then
  if [ "$is_dynamic_cargo_target_dir" = true ]; then
    emit_unset
  fi
  exit 0
fi

if ! cargo_toml=$(cargo locate-project --workspace --message-format plain 2>/dev/null); then
  if [ "$is_dynamic_cargo_target_dir" = true ]; then
    emit_unset
  fi
  exit 0
fi

project_root=$(canonical_dir "$(dirname "$cargo_toml")") || {
  if [ "$is_dynamic_cargo_target_dir" = true ]; then
    emit_unset
  fi
  exit 0
}

hash_input=$(stable_hash_input "$project_root")

if ! hash=$(hash_value "$hash_input"); then
  exit 0
fi

state_home=${XDG_STATE_HOME:-$HOME/.local/state}
project_basename=$(sanitize_basename "$(basename "$project_root")")
target_dir=$state_home/cargo/$hash-$project_basename/target

if ! mkdir -p "$target_dir"; then
  exit 0
fi

if [ "${CARGO_TARGET_DIR+x}" = x ] && [ "$is_dynamic_cargo_target_dir" != true ]; then
  # Respect user-managed values.
  exit 0
fi

if [ "$is_dynamic_cargo_target_dir" = true ] && [ "${CARGO_TARGET_DIR:-}" = "$target_dir" ]; then
  exit 0
fi

emit_set "$target_dir"

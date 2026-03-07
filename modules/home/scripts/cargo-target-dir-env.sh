set -eu

VALID_SHELLS='fish'

canonical_dir() {
  dir=$1

  if [ ! -d "$dir" ]; then
    return 1
  fi

  (
    cd "$dir" && pwd -P
  )
}

hash_value() {
  value=$1
  full_hash=

  if command -v sha256sum >/dev/null 2>&1; then
    full_hash=$(printf '%s' "$value" | sha256sum | cut -d ' ' -f 1)
  elif command -v shasum >/dev/null 2>&1; then
    full_hash=$(printf '%s' "$value" | shasum -a 256 | cut -d ' ' -f 1)
  else
    return 1
  fi

  # Keep paths compact while still using enough bits to avoid collisions.
  printf '%s' "$full_hash" | cut -c 1-20
}

sanitize_basename() {
  name=$1
  sanitized=$(printf '%s' "$name" | tr -cs '[:alnum:]._-' '-')
  sanitized=$(printf '%s' "$sanitized" | sed 's/^-*//; s/-*$//')

  if [ -z "$sanitized" ]; then
    sanitized=project
  fi

  printf '%s' "$sanitized"
}

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

hash_input=$project_root

if [ -n "${DOCUMENTS:-}" ]; then
  if docs_root=$(canonical_dir "$DOCUMENTS"); then
    # If the project is inside $DOCUMENTS, hash the path relative to $DOCUMENTS
    # so moving $DOCUMENTS doesn't invalidate all existing target directories.
    #
    # We then prepend a literal "$DOCUMENTS" marker before hashing to avoid
    # collisions with absolute paths that could share the same relative suffix
    # (for example "$DOCUMENTS/foo" vs "/foo").
    case "$project_root" in
      "$docs_root")
        # shellcheck disable=SC2016
        hash_input='$DOCUMENTS'
        ;;
      "$docs_root"/*)
        stripped_path=${project_root#"$docs_root"}
        hash_input="\$DOCUMENTS$stripped_path"
        ;;
    esac
  fi
fi

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

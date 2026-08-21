if [ "${CARGO_TARGET_DIR+x}" = x ]; then
  exec cargo "$@"
fi

if cargo_toml=$(
  cargo locate-project --workspace --message-format plain 2>/dev/null
); then
  project_root=$(canonical_dir "$(dirname "$cargo_toml")") || {
    printf '%s\n' "cargo: failed to resolve workspace root: $cargo_toml" >&2
    exit 1
  }

  hash_input=$(stable_hash_input "$project_root")
  hash=$(hash_value "$hash_input") || {
    printf '%s\n' "cargo: failed to hash workspace root: $project_root" >&2
    exit 1
  }

  state_home=${XDG_STATE_HOME:-$HOME/.local/state}
  project_basename=$(sanitize_basename "$(basename "$project_root")")
  export CARGO_TARGET_DIR=$state_home/cargo/target/$hash-$project_basename
fi

exec cargo "$@"

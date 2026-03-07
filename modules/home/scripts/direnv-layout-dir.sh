set -eu

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

project_root=$(canonical_dir "$PWD") || {
  printf '%s\n' "$PWD/.direnv"
  exit 0
}

hash_input=$project_root

if [ -n "${DOCUMENTS:-}" ]; then
  if docs_root=$(canonical_dir "$DOCUMENTS"); then
    # If the project is inside $DOCUMENTS, hash the path relative to $DOCUMENTS
    # so moving $DOCUMENTS doesn't invalidate all existing layout directories.
    #
    # We prepend a literal "$DOCUMENTS" marker before hashing to avoid
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

hash=$(hash_value "$hash_input") || {
  printf '%s\n' "$project_root/.direnv"
  exit 0
}

project_name=$(sanitize_basename "$(basename "$project_root")")
printf '%s\n' "$XDG_STATE_HOME/direnv/$hash-$project_name"

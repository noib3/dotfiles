canonical_dir() {
  local dir=$1

  if [ ! -d "$dir" ]; then
    return 1
  fi

  (
    cd "$dir" && pwd -P
  )
}

hash_value() {
  local value=$1
  local full_hash

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
  local name=$1
  local sanitized

  sanitized=$(printf '%s' "$name" | tr -cs '[:alnum:]._-' '-')
  sanitized=$(printf '%s' "$sanitized" | sed 's/^-*//; s/-*$//')

  if [ -z "$sanitized" ]; then
    sanitized=project
  fi

  printf '%s' "$sanitized"
}

# Computes a hash input for the given project root that is stable across moves
# of $DOCUMENTS.
#
# If the project is inside $DOCUMENTS, the returned hash input is relative to
# $DOCUMENTS (with a literal "$DOCUMENTS" prefix to avoid collisions with
# absolute paths that share the same suffix, for example "$DOCUMENTS/foo" vs
# "/foo").
stable_hash_input() {
  local project_root=$1
  local hash_input=$project_root

  if [ -n "${DOCUMENTS:-}" ]; then
    local docs_root
    if docs_root=$(canonical_dir "$DOCUMENTS"); then
      case "$project_root" in
        "$docs_root")
          # shellcheck disable=SC2016
          hash_input='$DOCUMENTS'
          ;;
        "$docs_root"/*)
          local stripped_path=${project_root#"$docs_root"}
          hash_input="\$DOCUMENTS$stripped_path"
          ;;
      esac
    fi
  fi

  printf '%s' "$hash_input"
}

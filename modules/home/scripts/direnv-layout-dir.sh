project_root=$(canonical_dir "$PWD") || {
  printf '%s\n' "$PWD/.direnv"
  exit 0
}

hash_input=$(stable_hash_input "$project_root")

hash=$(hash_value "$hash_input") || {
  printf '%s\n' "$project_root/.direnv"
  exit 0
}

project_name=$(sanitize_basename "$(basename "$project_root")")
printf '%s\n' "$XDG_STATE_HOME/direnv/$hash-$project_name"

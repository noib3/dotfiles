# Pass through to the real nix for shell completions. The completion mechanism
# uses arg indices that would be invalidated by our arg reshuffling.
if [ -n "${NIX_GET_COMPLETIONS:-}" ]; then
  exec nix "$@"
fi

# Where we store our GC root symlinks.
build_roots=${XDG_STATE_HOME:?}/nix/build-roots

# --- Flake root detection ---

# Finds the flake root by walking up from $PWD looking for flake.nix.
find_flake_root() {
  local dir=$PWD

  while true; do
    if [ -f "$dir/flake.nix" ]; then
      printf '%s' "$dir"
      return 0
    fi

    local parent
    parent=$(dirname "$dir")

    if [ "$parent" = "$dir" ]; then
      return 1
    fi

    dir=$parent
  done
}

# Given a flake root directory, compute the build-roots directory path for it.
project_build_roots_dir() {
  local flake_root=$1
  local project_root hash_input hash project_name

  project_root=$(canonical_dir "$flake_root") || return 1
  hash_input=$(stable_hash_input "$project_root")
  hash=$(hash_value "$hash_input") || return 1
  project_name=$(sanitize_basename "$(basename "$project_root")")
  printf '%s' "$build_roots/$hash-$project_name"
}

# --- Installable parsing ---

# Checks whether a string looks like a local flake reference.
#
# Local flake references are:
#   "."         ".#foo"       ".#foo^*"
#   "./sub"     "./sub#foo"
#   "/abs/path" "/abs/path#foo"
#   "path:..."
#
# NOT local:
#   "nixpkgs#foo"  "github:owner/repo"  "https://..."
is_local_installable() {
  local ref=$1

  case "$ref" in
    . | .#* | ./* | /* | path:*) return 0 ;;
    *) return 1 ;;
  esac
}

# Extracts the attribute name from an installable reference.
# ".#foo"         -> "foo"
# ".#foo^out"     -> "foo"
# ".#foo^*"       -> "foo"
# "."             -> "default"
# ".#"            -> "default"
# "./sub#bar"     -> "bar"
# "/abs/path#baz" -> "baz"
extract_attr_name() {
  local ref=$1

  case "$ref" in
    *"#"*)
      local attr=${ref#*"#"}
      # Strip output specifiers (^out, ^*, etc.)
      attr=${attr%%"^"*}
      if [ -z "$attr" ]; then
        printf 'default'
      else
        printf '%s' "$attr"
      fi
      ;;
    *)
      printf 'default'
      ;;
  esac
}

# Extracts the flake directory from an installable reference.
# ".#foo"           -> "."
# "./sub#bar"       -> "./sub"
# "/abs/path#baz"   -> "/abs/path"
# "path:./sub#bar"  -> "./sub"
# "."               -> "."
extract_flake_dir() {
  local ref=$1

  # Strip path: prefix.
  case "$ref" in
    path:*) ref=${ref#path:} ;;
  esac

  # Strip fragment.
  case "$ref" in
    *"#"*) ref=${ref%%"#"*} ;;
  esac

  # Strip query parameters (?dir=...).
  case "$ref" in
    *"?"*) ref=${ref%%"?"*} ;;
  esac

  if [ -z "$ref" ]; then
    printf '.'
  else
    printf '%s' "$ref"
  fi
}

# --- Nix CLI argument classification ---

# These flags consume 1 argument after them.
flag_takes_1_arg() {
  case "$1" in
    --out-link | -o | --profile | --eval-store | --include | -I | --expr | \
      --inputs-from | --output-lock-file | --reference-lock-file | --file | \
      -f | --update-input | --log-format | --arg-from-stdin | --redirect)
      return 0
      ;;
    *) return 1 ;;
  esac
}

# These flags consume 2 arguments after them.
flag_takes_2_args() {
  case "$1" in
    --arg | --arg-from-file | --argstr | --override-flake | --override-input | \
      --option)
      return 0
      ;;
    *) return 1 ;;
  esac
}

# --- Resolve a local installable to its flake root and build-roots dir ---
#
# Sets: flake_root, roots_dir, safe_attr
# Returns 1 if the installable is not local or can't be resolved.
resolve_local_installable() {
  local installable=$1
  local attr flake_dir resolved_flake_dir

  if ! is_local_installable "$installable"; then
    return 1
  fi

  attr=$(extract_attr_name "$installable")
  flake_dir=$(extract_flake_dir "$installable")

  case "$flake_dir" in
    /*) resolved_flake_dir=$flake_dir ;;
    *) resolved_flake_dir=$PWD/$flake_dir ;;
  esac

  if [ -d "$resolved_flake_dir" ] && [ -f "$resolved_flake_dir/flake.nix" ]; then
    flake_root=$resolved_flake_dir
  elif flake_root=$(cd "$resolved_flake_dir" 2>/dev/null && find_flake_root); then
    : # found it
  else
    return 1
  fi

  roots_dir=$(project_build_roots_dir "$flake_root") || return 1
  safe_attr=$(printf '%s' "$attr" | tr '/' '-')
}

# --- Subcommand handlers ---

# Handle `nix build [options] installables...`
handle_build() {
  local -a installables=()
  local -a pass_through=()
  local has_out_link=false
  local has_no_link=false

  while [ $# -gt 0 ]; do
    case "$1" in
      --)
        shift
        installables+=("$@")
        break
        ;;
      --out-link | -o)
        has_out_link=true
        pass_through+=("$1" "$2")
        shift 2
        ;;
      --out-link=*)
        has_out_link=true
        pass_through+=("$1")
        shift
        ;;
      --no-link)
        has_no_link=true
        pass_through+=("$1")
        shift
        ;;
      -*)
        if flag_takes_2_args "$1"; then
          pass_through+=("$1" "$2" "$3")
          shift 3
        elif flag_takes_1_arg "$1"; then
          pass_through+=("$1" "$2")
          shift 2
        else
          pass_through+=("$1")
          shift
        fi
        ;;
      *)
        installables+=("$1")
        shift
        ;;
    esac
  done

  # Default installable is "." if none specified.
  if [ ${#installables[@]} -eq 0 ]; then
    installables=(".")
  fi

  # If user specified --no-link or --out-link, respect their choice and just
  # pass through (no GC root management).
  if [ "$has_out_link" = true ] || [ "$has_no_link" = true ]; then
    exec nix build "${pass_through[@]}" "${installables[@]}"
  fi

  # Check if any installable references a local flake.
  local has_local=false
  for inst in "${installables[@]}"; do
    if is_local_installable "$inst"; then
      has_local=true
      break
    fi
  done

  if [ "$has_local" = false ]; then
    exec nix build "${pass_through[@]}" "${installables[@]}"
  fi

  # Process each installable. For local ones, build with --out-link into
  # build-roots and create result-<attr> symlinks in the flake root.
  # For non-local ones, build normally.
  local exit_code=0
  local flake_root roots_dir safe_attr

  for inst in "${installables[@]}"; do
    if ! resolve_local_installable "$inst"; then
      nix build "${pass_through[@]}" "$inst" || exit_code=$?
      continue
    fi

    mkdir -p "$roots_dir"

    local root_link="$roots_dir/package-$safe_attr"

    if nix build "${pass_through[@]}" --out-link "$root_link" "$inst"; then
      local result_name="result-$safe_attr"
      if [ "$safe_attr" = "default" ]; then
        result_name="result"
      fi

      ln -sfn "$root_link" "$flake_root/$result_name"
    else
      exit_code=$?
    fi
  done

  return "$exit_code"
}

# Handle `nix develop [options] installables...`
handle_develop() {
  local installable=""
  local -a pass_through=()
  local has_profile=false

  while [ $# -gt 0 ]; do
    case "$1" in
      # `--command`/`-c` consumes all remaining arguments as the command
      # to run inside the dev shell.
      --command | -c)
        pass_through+=("$@")
        break
        ;;
      --)
        pass_through+=("--")
        shift
        pass_through+=("$@")
        break
        ;;
      --profile)
        has_profile=true
        pass_through+=("$1" "$2")
        shift 2
        ;;
      --profile=*)
        has_profile=true
        pass_through+=("$1")
        shift
        ;;
      -*)
        if flag_takes_2_args "$1"; then
          pass_through+=("$1" "$2" "$3")
          shift 3
        elif flag_takes_1_arg "$1"; then
          pass_through+=("$1" "$2")
          shift 2
        else
          pass_through+=("$1")
          shift
        fi
        ;;
      *)
        if [ -z "$installable" ]; then
          installable=$1
        else
          pass_through+=("$1")
        fi
        shift
        ;;
    esac
  done

  if [ -z "$installable" ]; then
    installable="."
  fi

  # If user specified --profile, respect their choice.
  if [ "$has_profile" = true ]; then
    exec nix develop "$installable" "${pass_through[@]}"
  fi

  local flake_root roots_dir safe_attr

  if ! resolve_local_installable "$installable"; then
    exec nix develop "$installable" "${pass_through[@]}"
  fi

  mkdir -p "$roots_dir"

  exec nix develop \
    --profile "$roots_dir/devshell-$safe_attr" \
    "$installable" "${pass_through[@]}"
}

# Handle `nix run [options] installables... [-- args...]`
handle_run() {
  local installable=""
  local -a pass_through=()
  local -a run_args=()
  local seen_dashdash=false

  while [ $# -gt 0 ]; do
    if [ "$seen_dashdash" = true ]; then
      run_args+=("$1")
      shift
      continue
    fi

    case "$1" in
      --)
        seen_dashdash=true
        shift
        ;;
      -*)
        if flag_takes_2_args "$1"; then
          pass_through+=("$1" "$2" "$3")
          shift 3
        elif flag_takes_1_arg "$1"; then
          pass_through+=("$1" "$2")
          shift 2
        else
          pass_through+=("$1")
          shift
        fi
        ;;
      *)
        if [ -z "$installable" ]; then
          installable=$1
        else
          run_args+=("$1")
        fi
        shift
        ;;
    esac
  done

  if [ -z "$installable" ]; then
    installable="."
  fi

  local flake_root roots_dir safe_attr

  if ! resolve_local_installable "$installable"; then
    if [ ${#run_args[@]} -gt 0 ]; then
      exec nix run "${pass_through[@]}" "$installable" -- "${run_args[@]}"
    else
      exec nix run "${pass_through[@]}" "$installable"
    fi
  fi

  mkdir -p "$roots_dir"

  local root_link="$roots_dir/app-$safe_attr"

  # Pre-build to create the GC root, then run. The second `nix run` will be
  # a no-op build since it's already in the store.
  nix build --out-link "$root_link" "${pass_through[@]}" "$installable"

  if [ ${#run_args[@]} -gt 0 ]; then
    exec nix run "${pass_through[@]}" "$installable" -- "${run_args[@]}"
  else
    exec nix run "${pass_through[@]}" "$installable"
  fi
}

# Handle `nix shell [options] installables...`
#
# `nix shell` is like `nix build` in that it takes multiple installables and
# builds them, but instead of creating result symlinks it spawns a shell with
# the packages on $PATH. We pre-build each local installable with --out-link to
# create GC roots, then run the real `nix shell`.
handle_shell() {
  local -a installables=()
  local -a pass_through=()

  while [ $# -gt 0 ]; do
    case "$1" in
      # `--command`/`-c` consumes all remaining arguments as the command.
      --command | -c)
        pass_through+=("$@")
        break
        ;;
      --)
        pass_through+=("--")
        shift
        pass_through+=("$@")
        break
        ;;
      -*)
        if flag_takes_2_args "$1"; then
          pass_through+=("$1" "$2" "$3")
          shift 3
        elif flag_takes_1_arg "$1"; then
          pass_through+=("$1" "$2")
          shift 2
        else
          pass_through+=("$1")
          shift
        fi
        ;;
      *)
        installables+=("$1")
        shift
        ;;
    esac
  done

  if [ ${#installables[@]} -eq 0 ]; then
    installables=(".")
  fi

  # Pre-build each local installable to create GC roots.
  local flake_root roots_dir safe_attr
  for inst in "${installables[@]}"; do
    if resolve_local_installable "$inst"; then
      mkdir -p "$roots_dir"
      nix build --out-link "$roots_dir/package-$safe_attr" \
        "$inst" 2>/dev/null || true
    fi
  done

  exec nix shell "${installables[@]}" "${pass_through[@]}"
}

# Handle `nix flake check [options] [flake-url]`
handle_flake_check() {
  local flake_url=""
  local -a pass_through=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --)
        pass_through+=("--")
        shift
        break
        ;;
      -*)
        if flag_takes_2_args "$1"; then
          pass_through+=("$1" "$2" "$3")
          shift 3
        elif flag_takes_1_arg "$1"; then
          pass_through+=("$1" "$2")
          shift 2
        else
          pass_through+=("$1")
          shift
        fi
        ;;
      *)
        flake_url=$1
        shift
        ;;
    esac
  done

  if [ -z "$flake_url" ]; then
    flake_url="."
  fi

  local flake_root roots_dir safe_attr

  if ! is_local_installable "$flake_url"; then
    exec nix flake check "${pass_through[@]}" "$flake_url"
  fi

  local flake_dir
  flake_dir=$(extract_flake_dir "$flake_url")

  local resolved_flake_dir
  case "$flake_dir" in
    /*) resolved_flake_dir=$flake_dir ;;
    *) resolved_flake_dir=$PWD/$flake_dir ;;
  esac

  if [ -d "$resolved_flake_dir" ] && [ -f "$resolved_flake_dir/flake.nix" ]; then
    flake_root=$resolved_flake_dir
  elif flake_root=$(cd "$resolved_flake_dir" 2>/dev/null && find_flake_root); then
    : # found it
  else
    exec nix flake check "${pass_through[@]}" "$flake_url"
  fi

  roots_dir=$(project_build_roots_dir "$flake_root") || {
    exec nix flake check "${pass_through[@]}" "$flake_url"
  }

  mkdir -p "$roots_dir"

  # Run the actual flake check.
  nix flake check "${pass_through[@]}" "$flake_url"
  local check_exit=$?

  # If checks passed, build each check output to create GC roots.
  if [ $check_exit -eq 0 ]; then
    local system
    system=$(nix eval --raw --impure --expr 'builtins.currentSystem' 2>/dev/null) || system=""

    if [ -n "$system" ]; then
      local check_names
      check_names=$(nix flake show "$flake_url" --json 2>/dev/null |
        jq -r ".checks.\"$system\" // {} | keys[]" 2>/dev/null) || check_names=""

      local name safe_name
      for name in $check_names; do
        safe_name=$(printf '%s' "$name" | tr '/' '-')
        nix build --out-link "$roots_dir/check-$safe_name" \
          "$flake_url#checks.$system.$name" 2>/dev/null || true
      done
    fi
  fi

  return "$check_exit"
}

# Handle `nix fmt [options] [args...]`
handle_fmt() {
  local -a pass_through=("$@")
  local flake_root roots_dir

  flake_root=$(find_flake_root) || {
    exec nix fmt "${pass_through[@]}"
  }

  roots_dir=$(project_build_roots_dir "$flake_root") || {
    exec nix fmt "${pass_through[@]}"
  }

  mkdir -p "$roots_dir"

  # Build the formatter to create a GC root, then run fmt.
  local system
  system=$(nix eval --raw --impure --expr 'builtins.currentSystem' 2>/dev/null) || system=""

  if [ -n "$system" ]; then
    nix build --out-link "$roots_dir/formatter" \
      ".#formatter.$system" 2>/dev/null || true
  fi

  exec nix fmt "${pass_through[@]}"
}

# --- Main dispatch ---

# If no arguments at all, just pass through.
if [ $# -eq 0 ]; then
  exec nix
fi

# Identify the subcommand and collect all arguments to pass to its handler.
subcommand=""
subcommand_args=()

while [ $# -gt 0 ]; do
  case "$1" in
    -*)
      if flag_takes_2_args "$1"; then
        subcommand_args+=("$1" "$2" "$3")
        shift 3
      elif flag_takes_1_arg "$1"; then
        subcommand_args+=("$1" "$2")
        shift 2
      else
        subcommand_args+=("$1")
        shift
      fi
      ;;
    *)
      subcommand=$1
      shift
      subcommand_args+=("$@")
      break
      ;;
  esac
done

# If no subcommand found (e.g., `nix --version`), pass through.
if [ -z "$subcommand" ]; then
  exec nix "${subcommand_args[@]}"
fi

case "$subcommand" in
  build)
    handle_build "${subcommand_args[@]}"
    ;;
  develop)
    handle_develop "${subcommand_args[@]}"
    ;;
  run)
    handle_run "${subcommand_args[@]}"
    ;;
  shell)
    handle_shell "${subcommand_args[@]}"
    ;;
  flake)
    if [ ${#subcommand_args[@]} -gt 0 ] && [ "${subcommand_args[0]}" = "check" ]; then
      handle_flake_check "${subcommand_args[@]:1}"
    else
      exec nix flake "${subcommand_args[@]}"
    fi
    ;;
  fmt)
    handle_fmt "${subcommand_args[@]}"
    ;;
  *)
    exec nix "$subcommand" "${subcommand_args[@]}"
    ;;
esac

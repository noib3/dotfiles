# Pass through to the real nix for shell completions. The completion mechanism
# uses arg indices that would be invalidated by our arg reshuffling.
if [ -n "${NIX_GET_COMPLETIONS:-}" ]; then
  exec nix "$@"
fi

# Allow `nix -- ...` to bypass the wrapper entirely.
if [ "${1:-}" = "--" ]; then
  shift
  exec nix "$@"
fi

wrapper_bin_dir=$(dirname "$0")

# When entering a shell we call the real `nix` by absolute path because `env
# PATH=... nix` would resolve `nix` using the new PATH (which has the wrapper
# first), causing infinite recursion.
real_nix=$(command -v nix)

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
    /nix/store/*) return 1 ;;
    . | .#* | ./* | /* | path:*) return 0 ;;
    *) return 1 ;;
  esac
}

# Extracts a filesystem-safe attribute name from an installable reference.
# ".#foo"         -> "foo"
# ".#foo^out"     -> "foo"
# ".#foo^*"       -> "foo"
# "."             -> "default"
# ".#"            -> "default"
# "./sub#bar"     -> "bar"
# "/abs/path#baz" -> "baz"
# ".#packages.aarch64-darwin.foo" -> "packages-aarch64-darwin-foo"
fs_safe_attr_name() {
  local ref=$1

  case "$ref" in
    *"#"*)
      local attr=${ref#*"#"}
      # Strip output specifiers (^out, ^*, etc.)
      attr=${attr%%"^"*}
      if [ -z "$attr" ]; then
        printf 'default'
      else
        printf '%s' "$attr" | tr '/' '-'
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
      -f | --update-input | --log-format | --arg-from-stdin | --redirect | \
      --extra-experimental-features | --store)
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

current_system() {
  nix eval --raw --impure --expr 'builtins.currentSystem' 2>/dev/null
}

# --- Resolve a local installable to its flake root and build-roots dir ---
#
# Sets: flake_root, roots_dir
# Returns 1 if the installable is not local or can't be resolved.
resolve_local_installable() {
  local installable=$1
  local flake_dir resolved_flake_dir

  if ! is_local_installable "$installable"; then
    return 1
  fi

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
}

# --- Flake input rooting ---

# Root the flake source closure so it survives garbage collection. Without this,
# GC would remove eval-time flake sources (nixpkgs tarball, etc.) when they're
# not referenced by any build output, forcing a re-download on the next
# evaluation.
root_flake_inputs() {
  local flake_root=$1
  local roots_dir=$2
  local inputs_dir="$roots_dir/inputs"

  # Skip if we already rooted inputs for this flake root in this invocation.
  case " ${_rooted_flakes:-} " in
    *" $flake_root "*) return ;;
  esac
  _rooted_flakes="${_rooted_flakes:-} $flake_root"

  # Run in background to avoid adding latency to the main command. The inputs
  # are already in the store from the evaluation that's about to happen (or just
  # happened), so this is just creating GC root symlinks.
  (
    mkdir -p "$inputs_dir"

    # Remove old input roots so removed flake inputs don't stay rooted.
    rm -f "$inputs_dir"/* 2>/dev/null

    # Walk the nested flake-input tree from `nix flake archive --json` and emit
    # tab-separated pairs of (<input_name>, <store_path>). For example, this:
    #   {"inputs":{"rust-overlay":{"path":"/nix/store/...-source","inputs":{"nixpkgs":{"path":"/nix/store/...-source"}}}}}
    # would emit:
    #   rust-overlay⇥/nix/store/...-source
    #   rust-overlay.nixpkgs⇥/nix/store/...-source
    nix flake archive --json "$flake_root" 2>/dev/null |
      jq -r '
        def emit($prefix):
          ([($prefix | join(".")), .path] | @tsv),
          ((.inputs // {}) | to_entries[] | . as $entry | $entry.value | emit($prefix + [ $entry.key ]));

        (.inputs // {}) | to_entries[] | . as $entry | $entry.value | emit([ $entry.key ])
      ' 2>/dev/null |
      while IFS=$'\t' read -r input_name store_path; do
        # Skip inputs that don't have store paths.
        [ -n "$store_path" ] || continue
        input_name=$(sanitize_basename "$input_name")
        nix-store --add-root "$inputs_dir/$input_name" \
          --indirect -r "$store_path" >/dev/null 2>&1 || true
      done
  ) &
}

# Resolve a local `nix run` installable to the store path `nix run` would
# realize.
resolve_run_target_path() {
  local installable=$1
  shift
  local -a options=("$@")
  local fragment
  local flake_ref
  local system
  local candidate

  system=$(current_system) || return 1

  case "$installable" in
    *"#"*)
      flake_ref=${installable%%"#"*}
      fragment=${installable#*"#"}
      fragment=${fragment%%"^"*}
      ;;
    *)
      fragment=""
      ;;
  esac

  [ -n "$flake_ref" ] || flake_ref='.'

  case "$fragment" in
    "")
      candidate="$flake_ref#apps.$system.default"
      ;;
    apps.* | defaultApp.*)
      candidate="$flake_ref#$fragment"
      ;;
    packages.* | legacyPackages.*)
      candidate=""
      ;;
    *)
      candidate="$flake_ref#apps.$system.$fragment"
      ;;
  esac

  if [ -n "$candidate" ]; then
    local target
    target=$(nix eval --raw "${options[@]}" "$candidate.program" 2>/dev/null) || target=""
    if [ -n "$target" ]; then
      printf '%s' "$target"
      return 0
    fi
  fi

  case "$fragment" in
    "")
      candidate="$flake_ref#packages.$system.default"
      ;;
    packages.* | legacyPackages.*)
      candidate="$flake_ref#$fragment"
      ;;
    apps.* | defaultApp.*)
      return 1
      ;;
    *)
      candidate="$flake_ref#packages.$system.$fragment"
      local target
      target=$(nix eval --raw "${options[@]}" "$candidate.outPath" 2>/dev/null) || target=""
      if [ -n "$target" ]; then
        printf '%s' "$target"
        return 0
      fi
      candidate="$flake_ref#legacyPackages.$system.$fragment"
      ;;
  esac

  nix eval --raw "${options[@]}" "$candidate.outPath" 2>/dev/null || return 1
}

# --- Subcommand handlers ---

# Handle `nix build [options] installables...`
handle_build() {
  local -a installables=()
  local -a pass_through=()
  local has_out_link=false
  local has_no_link=false
  local has_json=false
  local has_print_out_paths=false

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
      --json)
        has_json=true
        pass_through+=("$1")
        shift
        ;;
      --print-out-paths)
        has_print_out_paths=true
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

  # If user specified --no-link or --out-link, respect their choice and skip
  # output GC root management, but still root flake inputs.
  if [ "$has_out_link" = true ] || [ "$has_no_link" = true ]; then
    for inst in "${installables[@]}"; do
      if resolve_local_installable "$inst"; then
        mkdir -p "$roots_dir"
        root_flake_inputs "$flake_root" "$roots_dir"
      fi
    done
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

  local flake_root roots_dir
  local -a internal_pass_through=()
  local arg

  for arg in "${pass_through[@]}"; do
    case "$arg" in
      --json | --print-out-paths) ;;
      *) internal_pass_through+=("$arg") ;;
    esac
  done

  # Build all installables in one invocation so Nix can schedule work across
  # them in parallel, then root the realized outputs for local flakes.
  for inst in "${installables[@]}"; do
    if resolve_local_installable "$inst"; then
      mkdir -p "$roots_dir"
      root_flake_inputs "$flake_root" "$roots_dir"
    fi
  done

  local build_json
  build_json=$(nix build --json --no-link "${internal_pass_through[@]}" "${installables[@]}") || return $?

  local i=0
  for inst in "${installables[@]}"; do
    if resolve_local_installable "$inst"; then
      local attr_name packages_dir output_count
      attr_name=$(fs_safe_attr_name "$inst")
      packages_dir="$roots_dir/packages"
      mkdir -p "$packages_dir"

      output_count=$(printf '%s' "$build_json" | jq ".[$i].outputs | length" 2>/dev/null) || output_count=0

      while IFS=$'\t' read -r output_name store_path; do
        [ -n "$store_path" ] || continue

        local root_name=$attr_name
        if [ "$output_name" != "out" ] || [ "$output_count" -gt 1 ]; then
          root_name="$attr_name-$output_name"
        fi

        nix-store --add-root "$packages_dir/$root_name" --indirect -r "$store_path" >/dev/null 2>&1 || true
      done < <(printf '%s' "$build_json" |
        jq -r ".[$i].outputs | to_entries[] | [.key, .value] | @tsv" 2>/dev/null)

      ln -sfn "$packages_dir" "$flake_root/result"
    fi

    i=$((i + 1))
  done

  if [ "$has_json" = true ]; then
    printf '%s\n' "$build_json"
  elif [ "$has_print_out_paths" = true ]; then
    printf '%s' "$build_json" | jq -r '.[] | .outputs | to_entries[] | .value' 2>/dev/null
  fi
}

# Handle `nix develop [options] installables...`
handle_develop() {
  local installable=""
  local -a pass_through=()
  local has_profile=false

  while [ $# -gt 0 ]; do
    case "$1" in
      # `--command`/`-c` consumes all remaining arguments as the command
      # to run inside the devshell.
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
    exec env PATH="$wrapper_bin_dir:$PATH" "$real_nix" develop \
      "$installable" "${pass_through[@]}"
  fi

  local flake_root roots_dir

  if ! resolve_local_installable "$installable"; then
    exec env PATH="$wrapper_bin_dir:$PATH" "$real_nix" develop \
      "$installable" "${pass_through[@]}"
  fi

  local attr_name
  attr_name=$(fs_safe_attr_name "$installable")

  mkdir -p "$roots_dir"
  root_flake_inputs "$flake_root" "$roots_dir"
  mkdir -p "$roots_dir/devshells"

  exec env PATH="$wrapper_bin_dir:$PATH" "$real_nix" develop \
    --profile "$roots_dir/devshells/$attr_name" \
    "$installable" "${pass_through[@]}"
}

# Handle `nix run [options] installables... [-- args...]`
handle_run() {
  local installable=""
  local -a options=()
  local -a passthrough_args=()
  local seen_dashdash=false

  while [ $# -gt 0 ]; do
    if [ "$seen_dashdash" = true ]; then
      passthrough_args+=("$1")
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
          options+=("$1" "$2" "$3")
          shift 3
        elif flag_takes_1_arg "$1"; then
          options+=("$1" "$2")
          shift 2
        else
          options+=("$1")
          shift
        fi
        ;;
      *)
        if [ -z "$installable" ]; then
          installable=$1
        else
          passthrough_args+=("$1")
        fi
        shift
        ;;
    esac
  done

  if [ -z "$installable" ]; then
    installable="."
  fi

  local flake_root roots_dir

  if ! resolve_local_installable "$installable"; then
    if [ ${#passthrough_args[@]} -gt 0 ]; then
      exec nix run "${options[@]}" "$installable" -- "${passthrough_args[@]}"
    else
      exec nix run "${options[@]}" "$installable"
    fi
  fi

  mkdir -p "$roots_dir"
  root_flake_inputs "$flake_root" "$roots_dir"

  if [ ${#passthrough_args[@]} -gt 0 ]; then
    nix run "${options[@]}" "$installable" -- "${passthrough_args[@]}"
  else
    nix run "${options[@]}" "$installable"
  fi

  local run_exit=$?

  # After a successful run, root the resulting store path in the background.
  if [ "$run_exit" -eq 0 ]; then
    mkdir -p "$roots_dir/apps"

    (
      local target
      target=$(resolve_run_target_path "$installable" "${options[@]}") || exit 0
      [ -n "$target" ] || exit 0
      local attr_name
      attr_name=$(fs_safe_attr_name "$installable")
      nix-store --add-root "$roots_dir/apps/$attr_name" --indirect -r "$target" >/dev/null 2>&1 || true
    ) >/dev/null 2>&1 &
  fi

  return "$run_exit"
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
  local flake_root roots_dir
  for inst in "${installables[@]}"; do
    if resolve_local_installable "$inst"; then
      local attr_name
      attr_name=$(fs_safe_attr_name "$inst")
      mkdir -p "$roots_dir"
      root_flake_inputs "$flake_root" "$roots_dir"
      mkdir -p "$roots_dir/packages"
      nix build --out-link "$roots_dir/packages/$attr_name" \
        "$inst" 2>/dev/null || true
    fi
  done

  exec env PATH="$wrapper_bin_dir:$PATH" "$real_nix" shell \
    "${installables[@]}" "${pass_through[@]}"
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

  local flake_root roots_dir

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
  root_flake_inputs "$flake_root" "$roots_dir"

  # Run the actual flake check.
  nix flake check "${pass_through[@]}" "$flake_url"
  local check_exit=$?

  # If checks passed, build each check output to create GC roots.
  if [ $check_exit -eq 0 ]; then
    local system
    system=$(current_system)

    if [ -n "$system" ]; then
      local check_names
      check_names=$(nix flake show "$flake_url" --json 2>/dev/null |
        jq -r ".checks.\"$system\" // {} | keys[]" 2>/dev/null) || check_names=""

      mkdir -p "$roots_dir/checks"

      local name safe_name
      for name in $check_names; do
        safe_name=$(printf '%s' "$name" | tr '/' '-')
        nix build --out-link "$roots_dir/checks/$safe_name" \
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
  root_flake_inputs "$flake_root" "$roots_dir"

  # Build the formatter to create a GC root, then run fmt.
  local system
  system=$(current_system)

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

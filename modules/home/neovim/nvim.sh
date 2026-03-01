# Flattens `nvim` calls made from Neovim's embedded terminal by opening the
# target files in the parent instance.

if [[ -z "${NVIM:-}" ]]; then
  exec "$NVIM_EXE" "$@"
fi

files_only=true
after_double_dash=false

for arg in "$@"; do
  if [[ "$arg" == "--" ]]; then
    after_double_dash=true
    continue
  fi

  if [[ "$after_double_dash" == false && ("$arg" == -* || "$arg" == +*) ]]; then
    files_only=false
    break
  fi
done

# If the arguments contain any non-file arguments, launch a new instance.
[[ "$files_only" == true ]] || exec "$NVIM_EXE" "$@"

filenames=""
for arg in "$@"; do
  escaped_arg=${arg//\\/\\\\}
  escaped_arg=${escaped_arg//\"/\\\"}
  filenames+="\"$escaped_arg\","
done

# If dispatch fails, launch a new instance.
"$NVIM_EXE" --server "$NVIM" --remote-expr \
  "luaeval('vim.api.nvim_exec_autocmds(\"User\", { pattern = \"NvimLaunch\", modeline = false, data = { $filenames } })')" \
  2>/dev/null || exec "$NVIM_EXE" "$@"

# Flattens `nvim` calls made from Neovim's embedded terminal by opening the
# target files in the parent instance.

nvim=$NVIM_EXE

if [[ -z ${NVIM:-} ]]; then
  exec "$nvim" "$@"
fi

files_only=true
after_double_dash=false

for arg in "$@"; do
  if [[ $arg == "--" ]]; then
    after_double_dash=true
    continue
  fi

  if [[ $after_double_dash == false && ($arg == -* || $arg == +*) ]]; then
    files_only=false
    break
  fi
done

# If the arguments contain any non-file arguments, launch a new instance.
[[ $files_only == true ]] || exec "$nvim" "$@"

filepaths=""
for arg in "$@"; do
  filepath=$(realpath -m -- "$arg")
  escaped_filepath=${filepath//\\/\\\\}
  escaped_filepath=${escaped_filepath//\"/\\\"}
  filepaths+="\"$escaped_filepath\","
done

# We need to block until the opened buffers are closed so that callers that
# expect the editor to be synchronous (e.g. `git rebase -i`) don't continue
# before the user is done editing.
#
# TODO: replace the FIFO with `--remote-wait` once Neovim implements it
# (currently returns `E5600: Wait commands not yet implemented`).
fifo=$(mktemp -u)
mkfifo "$fifo"
trap 'rm -f "$fifo"' EXIT

escaped_fifo=${fifo//\\/\\\\}
escaped_fifo=${escaped_fifo//\"/\\\"}

if "$nvim" --server "$NVIM" --remote-expr \
  "luaeval('vim.api.nvim_exec_autocmds(\"User\", { pattern = \"NvimLaunch\", modeline = false, data = { filepaths = { $filepaths }, on_done = function() local f = io.open(\"$escaped_fifo\", \"w\"); if f then f:close() end end } })')" \
  2>/dev/null; then
  read -r <"$fifo" || true
  exit 0
fi

exec "$nvim" "$@"

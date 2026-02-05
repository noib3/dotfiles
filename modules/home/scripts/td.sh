# Opens today's todo file (<documentsDir>/tdtd/<yyyy>-<mm>-<dd>.md), creating
# it first if it doesn't already exist.

local DOCUMENTS_DIR="$1"

filepath="${DOCUMENTS_DIR}/tdtd/$(date +%Y-%m-%d).md"

[[ -f "$filepath" ]] || touch "$filepath"

# If we're running inside Neovim, we use `nvim --server "$NVIM" --remote-send`
# to feed keystrokes into the parent Neovim instance.
if [[ -n "${NVIM:-}" ]]; then
  # The leading <C-\><C-n> switches from terminal mode to normal mode, which is
  # needed when `td` is called from Neovim's embedded terminal. In normal mode
  # it's a no-op.
  nvim --server "$NVIM" --remote-send \
    "<C-\\><C-n>:lua require('utils.edit').open('$filepath')<CR>"
else
  $EDITOR "$filepath"
fi

local has_bufdelete, _ = pcall(require, "bufdelete")
local has_cokeline, _ = pcall(require, "cokeline")

local diagnostic = vim.diagnostic
local keymap = vim.keymap

vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Disable `s`.
keymap.set({ "n", "v" }, "s", "")

-- Save the file
keymap.set("n", "<C-s>", "<Cmd>w<CR>")

-- Either quit Neovim, close a window or delete a buffer.
local close = function()
  -- Returns `true` if there's only one buffer left.
  local is_last_buffer = function()
    return #vim.fn.getbufinfo({ buflisted = 1 }) == 1
  end

  -- The current buffer filetype and buffer type.
  local filetype, buftype = vim.bo.filetype, vim.bo.buftype

  -- Use `Bdelete` from `https://github.com/famiu/bufdelete.nvim` if available
  -- to avoid messing w/ the window layout.
  local bd = has_bufdelete and "Bdelete" or "bdelete"

  local cmd =
  ((filetype == "help" or buftype == "nofile" or is_last_buffer()) and "q")
      or (buftype == "terminal" and bd .. "!")
      or bd

  vim.cmd(cmd)
end

keymap.set("n", "<C-w>", close)

-- Jump to the first non-whitepspace character in the displayed line.
keymap.set({ "n", "v" }, "<C-a>", "g^")
keymap.set("i", "<C-a>", "<C-o>g^")

-- Jump to the end of the displayed line.
keymap.set({ "n", "v" }, "<C-e>", "g$")
keymap.set("i", "<C-e>", "<C-o>g$")

-- Move between displayed lines instead of physical ones (i.e. take count of
-- soft-wrapping).
keymap.set({ "n", "v" }, "<Up>", "g<Up>", { noremap = true })
keymap.set({ "n", "v" }, "<Down>", "g<Down>", { noremap = true })

keymap.set("i", "<Up>", "<C-o>g<Up>", { noremap = true })
keymap.set("i", "<Down>", "<C-o>g<Down>", { noremap = true })

-- Navigate window splits.
keymap.set("n", "<S-Up>", "<C-w>k", { noremap = true })
keymap.set("n", "<S-Down>", "<C-w>j", { noremap = true })
keymap.set("n", "<S-Left>", "<C-w>h", { noremap = true })
keymap.set("n", "<S-Right>", "<C-w>l", { noremap = true })

-- Delete the previou word in insert mode.
keymap.set("n", "<M-BS>", "<C-w>", { noremap = true })

-- Escape terminal mode.
keymap.set("t", "<M-Esc>", "<C-\\><C-n>", { noremap = true })

-- Jump to the beginning of the line in command mode.
keymap.set("c", "<C-a>", "<C-b>")

-- Substitute globally and in the visually selected region.
keymap.set("n", "ss", ":%s///g<Left><Left><Left>")
keymap.set("v", "ss", ":s///g<Left><Left><Left>")

-- Display diagnostics in a floating window.
keymap.set("n", "?", diagnostic.open_float)

-- Navigate to the previous/next diagnostic.
keymap.set("n", "dp", diagnostic.goto_prev)
keymap.set("n", "dn", diagnostic.goto_next)

if has_cokeline then
  keymap.set("n", "<Tab>", "<Plug>(cokeline-focus-next)")
  keymap.set("n", "<S-Tab>", "<Plug>(cokeline-focus-prev)")
  keymap.set("n", "<Leader>p", "<Plug>(cokeline-switch-prev)")
  keymap.set("n", "<Leader>n", "<Plug>(cokeline-switch-next)")
  keymap.set("n", "<Leader>a", "<Plug>(cokeline-pick-focus)")
  keymap.set("n", "<Leader>b", "<Plug>(cokeline-pick-close)")
  for i = 1, 9 do
    keymap.set(
      "n",
      ("<F%s>"):format(i),
      ("<Plug>(cokeline-focus-%s)"):format(i)
    )
  end
end

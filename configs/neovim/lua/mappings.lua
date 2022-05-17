local has_bufdelete, _ = pcall(require, "bufdelete")
local has_cokeline, _ = pcall(require, "cokeline")
local has_compleet, compleet = pcall(require, "compleet")

local keymap = vim.keymap
local eval_viml = vim.api.nvim_eval

---@return string
local i_Tab = function()
  return (compleet.is_menu_open() and "<Plug>(compleet-next-completion)")
      or (compleet.has_completions() and "<Plug>(compleet-show-completions)")
      or "<Tab>"
end

---@return string
local i_STab = function()
  return (compleet.is_menu_open() and "<Plug>(compleet-prev-completion)")
      or (eval_viml("delimitMate#ShouldJump()") and "<Plug>delimitMateS-Tab")
      or "<S-Tab>"
end

---@return string
local i_Right = function()
  return compleet.is_hint_visible()
      and "<Plug>(compleet-insert-first-completion)"
      or "<Right>"
end

---@return string
local i_CR = function()
  return compleet.is_completion_selected()
      and "<Plug>(compleet-insert-selected-completion)"
      or "<Plug>delimitMateCR"
end

-- Either closes the window or deletes the current buffer.
local close = function()
  local bdelete = has_bufdelete and "Bdelete" or "bdelete"
  local filetype, buftype = vim.bo.filetype, vim.bo.buftype

  if filetype == "startify" then
    vim.cmd("bd")
  elseif filetype == "help"
      or buftype == "nofile"
      or #vim.fn.getbufinfo({ buflisted = 1 }) == 1
  then
    vim.cmd("q")
  elseif buftype == "terminal" then
    vim.cmd(bdelete .. "!")
  else
    vim.cmd(bdelete)
  end
end

local setup = function()
  vim.g.mapleader = ","
  vim.g.maplocalleader = ","

  -- Save the file.
  keymap.set("n", "<C-s>", "<Cmd>w<CR>")

  -- Either quit, close a window or delete a buffer depending on a bunch of
  -- conditions.
  keymap.set("n", "<C-w>", close)

  -- Jump to the first non-whitespace character in the displayed line.
  keymap.set({ "n", "v" }, "<C-a>", "g^")
  keymap.set("i", "<C-a>", "<C-o>g^")

  -- Jump to the end of the displayed line.
  keymap.set({ "n", "v" }, "<C-e>", "g$")
  keymap.set(
    "i",
    "<C-e>",
    'pumvisible() ? "\\<C-e>" : "\\<C-o>g$"',
    { expr = true, noremap = true }
  )

  -- Move between displayed lines instead of physical ones.
  keymap.set({ "n", "v" }, "<Up>", "g<Up>", { noremap = true })
  keymap.set(
    "i",
    "<Up>",
    'pumvisible() ? "<C-p>" : "<C-o>g<Up>"',
    { expr = true, noremap = true }
  )
  keymap.set({ "n", "v" }, "<Down>", "g<Down>", { noremap = true })
  keymap.set(
    "i",
    "<Down>",
    'pumvisible() ? "<C-n>" : "<C-o>g<Down>"',
    { expr = true, noremap = true }
  )

  -- Make escape behave nicely when the popup menu is visible
  keymap.set(
    "i",
    "<Esc>",
    'pumvisible() ? "\\<C-e>\\<Esc>" : "\\<Esc>"',
    { expr = true, noremap = true }
  )

  -- Display diagnostics in a floating window.
  keymap.set("n", "?", vim.diagnostic.open_float)

  -- Open a new terminal buffer in a horizontal or vertical split.
  keymap.set("n", "<Leader>spt", "<Cmd>sp<Bar>term<CR>")
  keymap.set("n", "<Leader>vspt", "<Cmd>vsp<Bar>term<CR>")

  -- Toggle code folds.
  keymap.set("n", "<Space>", '<Cmd>silent! execute "normal! za"<CR>')

  -- Disable the `s` mapping in normal and visual mode.
  keymap.set({ "n", "v" }, "s", "")

  -- Navigate window splits.
  keymap.set("n", "<S-Up>", "<C-w>k", { noremap = true })
  keymap.set("n", "<S-Down>", "<C-w>j", { noremap = true })
  keymap.set("n", "<S-Left>", "<C-w>h", { noremap = true })
  keymap.set("n", "<S-Right>", "<C-w>l", { noremap = true })

  -- Delete the previous word in insert mode.
  keymap.set("i", "<M-BS>", "<C-w>", { noremap = true })

  -- Escape terminal mode.
  keymap.set("t", "<M-Esc>", "<C-\\><C-n>", { noremap = true })

  -- Jump to the beginning of the line in command mode.
  keymap.set("c", "<C-a>", "<C-b>")

  -- Substitute globally and locally in the selected region.
  keymap.set("n", "ss", ":%s//g<Left><Left>")
  keymap.set("v", "ss", ":s//<Left>")

  -- Stop highlighting the latest search results.
  keymap.set("n", "<C-g>", "<Cmd>noh<CR>", { silent = true })

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

  if has_compleet then
    keymap.set("i", "<Tab>", i_Tab, { expr = true, remap = true })
    keymap.set("i", "<S-Tab>", i_STab, { expr = true, remap = true })
    keymap.set("i", "<Right>", i_Right, { expr = true, remap = true })
    keymap.set("i", "<CR>", i_CR, { expr = true, remap = true })
  end
end

return {
  setup = setup,
}

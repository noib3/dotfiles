---@param name string
---@return number
local create_augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

vim.api.nvim_create_autocmd("VimResized", {
  group = create_augroup("noib3/rebalance-splits"),
  desc = "Rebalances window splits when terminal is resized",
  command = "wincmd =",
})

vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  group = create_augroup("noib3/reset-cursor"),
  desc = "Resets the cursor to a vertical bar before exiting Neovim",
  command = "set guicursor=a:ver25",
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = create_augroup("noib3/remove-trailing-whitespace-on-save"),
  desc = "Removes trailing whitespace on save",
  callback = function()
    local cur_search = vim.fn.getreg("/")
    local cur_view = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setreg("/", cur_search)
    vim.fn.winrestview(cur_view)
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = create_augroup("noib3/setup-terminal"),
  desc = "Disables line numbers and enters insert mode in terminals",
  callback = function()
    vim.opt_local.statusline = "%{b:term_title}"
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    if vim.startswith(vim.api.nvim_buf_get_name(0), "term://") then
      vim.cmd("startinsert")
    end
  end,
})

vim.api.nvim_create_autocmd("BufAdd", {
  group = create_augroup("noib3/disable-wrapping-in-lock-files"),
  pattern = "*.lock,lazy-lock.json",
  desc = "Disable soft wrapping in lock files",
  callback = function()
    vim.wo.wrap = false
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = create_augroup("noib3/set-cursor-hl-group"),
  desc = "Sets the Cursor highlight group to be the opposite of Normal",
  callback = function()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    vim.api.nvim_set_hl(0, "Cursor", {
      fg = normal.bg,
      bg = normal.fg,
    })
  end,
})

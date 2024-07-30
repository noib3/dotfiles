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

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
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

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  group = create_augroup("noib3/rust-rerun-tests-on-save"),
  pattern = "*.rs",
  desc = "In Rust files, reruns all the tests on save",
  callback = function()
    local neotest = require("neotest")
    neotest.run.run(vim.fn.expand("%:p"))
  end,
})

-- TODO: this doesnt' work. The callback is executed but the tests are not run.
vim.api.nvim_create_autocmd({ "BufAdd" }, {
  group = create_augroup("noib3/rust-run-tests-on-open"),
  pattern = "*.rs",
  desc = "In Rust files, runs all the tests when a file is opened for the 1st time",
  callback = function()
    local neotest = require("neotest")
    neotest.run.run(vim.fn.expand("%:p"))
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

-- Bootstrap lazy.nvim.
local lazypath = vim.fn.stdpath("data") .. "lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=main",
    lazypath,
  })
end

vim.opt.runtimepath:append(lazypath)

-- Set options.
local options = require("options")

for key, value in pairs(options) do
  vim.opt[key] = value
end

-- Set keymaps.
local keymaps = require("keymaps")

for _, opts in ipairs(keymaps) do
  vim.keymap.set(opts.mode, opts.lhs, opts.rhs, opts.opts)
end

-- Load plugins.
require("lazy").setup(
  "plugins",
  {
    change_detection = {
      notify = false,
    },
  }
)

-- Load custom settings for LSPs.
require("lsp")

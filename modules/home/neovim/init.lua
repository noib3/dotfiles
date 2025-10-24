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

require("autocmds")
require("diagnostic")
require("lsp")
require("options")

-- These have to be set before loading the plugins or lazy will complain.
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Load plugins.
require("lazy").setup("plugins", {
  change_detection = {
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = { "netrwPlugin", "tutor" }
    },
  },
})

-- Some keymaps depend on plugins being loaded, so load them last.
require("keymaps")

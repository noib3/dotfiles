-- Disable built-in plugins we don't use to speed up startup. Each of these
-- guards a `$VIMRUNTIME/plugin/*.{vim,lua}` file that would otherwise be
-- sourced unconditionally.
vim.g.loaded_gzip = 1 -- transparent editing of gzipped files
vim.g.loaded_man = 1 -- :Man command
vim.g.loaded_matchit = 1 -- extended % matching (superseded by treesitter)
vim.g.loaded_netrwPlugin = 1 -- built-in file explorer (:Explore)
vim.g.loaded_remote_plugins = 1 -- remote plugin support (Python/Node/etc.)
vim.g.loaded_tarPlugin = 1 -- transparent editing of tar archives
vim.g.loaded_2html_plugin = 1 -- :TOhtml command
vim.g.loaded_tutor_mode_plugin = 1 -- :Tutor command
vim.g.loaded_zipPlugin = 1 -- transparent editing of zip archives

require("autocmds")
require("diagnostic")
require("keymaps")
require("lsp")
require("options")
require("plugins")

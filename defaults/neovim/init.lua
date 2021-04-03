local fn = vim.fn
local cmd = vim.cmd

-- Automatically install Packer if it's not already installed
local install_path = fn.stdpath('data') .. '/site/pack/packer/opt/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  cmd('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
end

require('colorscheme')
require('mappings')
require('options')
require('plugins')

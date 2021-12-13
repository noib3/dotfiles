require('globalutils')
local rq_colorscheme = require('colorscheme')
local rq_diagnostics = require('diagnostics')
local rq_highlights = require('highlights')
local rq_mappings = require('mappings')
local rq_misc = require('misc')
local rq_options = require('options')
local rq_plugins = require('plugins')

local vim_fn = vim.fn

-- Automatically install Packer if it's not already installed
local install_path =
  ('%s/site/pack/packer/opt/packer.nvim'):format(vim_fn.stdpath('data'))

if vim_fn.empty(vim_fn.glob(install_path)) > 0 then
  local packer_repo =  'https://github.com/wbthomason/packer.nvim'
  vim_fn.system({'git', 'clone', packer_repo, install_path})
end

rq_diagnostics.setup()
rq_highlights.setup()
rq_misc.setup()
rq_options.setup()
rq_plugins.setup()

-- Set the colorscheme and the key mappings after all the plugins have been
-- loaded.
rq_colorscheme.setup()
rq_mappings.setup()

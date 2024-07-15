-- Automatically install Packer if it's not already installed.

local fn = vim.fn

local install_path =
("%s/site/pack/packer/opt/packer.nvim"):format(fn.stdpath("data"))

if fn.empty(fn.glob(install_path)) > 0 then
  local packer_repo = "https://github.com/wbthomason/packer.nvim"
  fn.system({ "git", "clone", packer_repo, install_path })
end

--

-- require("ciao")
require("diagnostic")
require("options")
require("plugins")

-- Load these modules *after* loading the plugins.

require("colorscheme")
require("lsp")
require("mappings")

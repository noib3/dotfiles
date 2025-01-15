local utils = require("utils")

local setup_lazygit = function()
  local Terminal = require("toggleterm.terminal").Terminal
  local lazygit = Terminal:new({
    cmd = "lazygit",
    dir = "git_dir",
    hidden = true,
  })
  vim.keymap.set("n", "lg", function() lazygit:toggle() end, { silent = true })
end

return {
  {
    "akinsho/toggleterm.nvim",
    opts = {
      autochdir = true,
      direction = "float",
      float_opts = {
        border = "single",
        height = function() return utils.math.round(vim.o.lines * 0.8) end,
        width = function() return utils.math.round(vim.o.columns * 0.8) end,
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)
      setup_lazygit()
    end
  }
}

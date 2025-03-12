return {
  {
    "folke/trouble.nvim",
    opts = {},
    config = function(_, opts)
      local trouble = require("trouble")

      vim.keymap.set("n", "<S-d>", function()
        trouble.open({
          mode = "diagnostics",
          new = true,
        })
      end)

      trouble.setup(opts)
    end
  }
}

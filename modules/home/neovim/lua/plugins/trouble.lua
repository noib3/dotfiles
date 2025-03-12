return {
  {
    "folke/trouble.nvim",
    opts = {},
    config = function(_, opts)
      local trouble = require("trouble")

      vim.keymap.set("n", "<C-x><C-t>", function()
        trouble.toggle({
          focus = true,
          mode = "diagnostics",
          win = {
            type = "split",
            size = {
              height = 12,
            },
          },
        })
      end)

      vim.keymap.set("n", "<C-x><C-x>", function()
        trouble.toggle({
          focus = true,
          mode = "lsp_references",
          win = {
            type = "split",
            size = {
              height = 14,
            },
          },
        })
      end)

      trouble.setup(opts)
    end
  }
}

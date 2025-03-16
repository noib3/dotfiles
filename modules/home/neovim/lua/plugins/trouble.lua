local home = vim.env.HOME

local starts_with = function(str, start)
  return str:sub(1, #start) == start
end

return {
  {
    "folke/trouble.nvim",
    opts = {
      modes = {
        call_sites = {
          mode = "lsp_references",
          win = {
            type = "split",
            size = {
              height = 14,
            },
          },
        },
        errors_and_warnings = {
          mode = "diagnostics",
          filter = function(items)
            return vim.tbl_filter(function(item)
              return
                  item.severity <= vim.diagnostic.severity.WARN
                  and starts_with(item.filename, home)
            end, items)
          end,
          win = {
            type = "split",
            size = {
              height = 12,
            },
          },
        },
      }
    },
    config = function(_, opts)
      local trouble = require("trouble")

      vim.keymap.set("n", "<C-x><C-t>", function()
        trouble.toggle({ focus = true, mode = "errors_and_warnings" })
      end)

      vim.keymap.set("n", "<C-x><C-x>", function()
        trouble.toggle({ focus = true, mode = "call_sites" })
      end)

      trouble.setup(opts)
    end
  }
}

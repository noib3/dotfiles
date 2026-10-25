local utils = require("utils")

local home = assert(vim.env.HOME)

-- trouble's module is a metatable that forwards to `trouble.api`, which EmmyLua
-- can't see through.
local trouble = require("trouble")

vim.keymap.set(
  "n",
  "<D-t>",
  ---@diagnostic disable-next-line: undefined-field
  function() trouble.toggle({ focus = true, mode = "errors_and_warnings" }) end
)

vim.keymap.set(
  "n",
  "<D-x>",
  ---@diagnostic disable-next-line: undefined-field
  function() trouble.toggle({ focus = true, mode = "call_sites" }) end
)

---@diagnostic disable-next-line: undefined-field
trouble.setup({
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
      max_items = false,
      mode = "diagnostics",
      filter = function(items)
        return vim.tbl_filter(
          function(item)
            return item.severity <= vim.diagnostic.severity.WARN
              and utils.lua.starts_with(item.filename, home)
          end,
          items
        )
      end,
      win = {
        type = "split",
        size = {
          height = 12,
        },
      },
    },
  },
})

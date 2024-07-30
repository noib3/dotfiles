return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      attach_to_untracked = true,
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        local stage_selected = function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end

        local unstage_selected = function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end

        map("n", "th", gitsigns.toggle_linehl)
        map("v", "s", stage_selected)
        map("v", "u", unstage_selected)
      end,
      signcolumn = false,
    }
  }
}

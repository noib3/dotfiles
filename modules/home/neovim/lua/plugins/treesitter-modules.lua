local get_language = function(buf)
  local filetype = vim.bo[buf].filetype
  return vim.treesitter.language.get_lang(filetype) or filetype
end

local initial_cursor = {}

local save_initial_cursor = function(buf)
  initial_cursor[buf] = vim.api.nvim_win_get_cursor(0)
end

local restore_initial_cursor = function(buf)
  local cursor = initial_cursor[buf]

  if not cursor then return end

  vim.cmd.normal({
    vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
    bang = true
  })

  vim.api.nvim_win_set_cursor(0, cursor)

  initial_cursor[buf] = nil
end

return {
  {
    "MeanderingProgrammer/treesitter-modules.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      ensure_installed = {
        "c",
        "javascript",
        "lua",
        "markdown",
        "nix",
        "rust",
        "toml",
        "vimdoc",
      },
      highlight = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = false,
          node_incremental = false,
          node_decremental = false,
        },
      },
    },
    config = function(_, opts)
      require("treesitter-modules").setup(opts)

      local selection = require("treesitter-modules.lib.selection")

      vim.keymap.set({ "n", "x" }, "<Tab>", function()
          local buf = vim.api.nvim_get_current_buf()
          local lang = get_language(buf)

          if not initial_cursor[buf] then
            save_initial_cursor(buf)
            selection.init_selection(buf, lang)
          else
            selection.node_incremental(buf, lang)
          end
        end,
        { desc = "Start incremental selection or select larger syntax node" }
      )

      vim.keymap.set("x", "<S-Tab>", function()
          local buf = vim.api.nvim_get_current_buf()
          local lang = get_language(buf)

          local _, start_row, start_col = unpack(vim.fn.getpos("v"))
          local _, end_row, end_col = unpack(vim.fn.getpos("."))
          local old_pos = { start_row, start_col, end_row, end_col }

          selection.node_decremental(buf, lang)

          local _, start_row, start_col = unpack(vim.fn.getpos("v"))
          local _, end_row, end_col = unpack(vim.fn.getpos("."))
          local new_pos = { start_row, start_col, end_row, end_col }

          if vim.deep_equal(old_pos, new_pos) then
            -- Selection didn't change, restore initial cursor.
            restore_initial_cursor(buf)
          end
        end,
        { desc = "Select smaller syntax node or restore initial cursor position" }
      )
    end,
  },
}

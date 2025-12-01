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

local install_dir = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter"

local languages = {
  "c",
  "javascript",
  "lua",
  "markdown",
  "nix",
  "rust",
  "toml",
  "vimdoc",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    dependencies = {
      "RRethy/nvim-treesitter-endwise",
      {
        "MeanderingProgrammer/treesitter-modules.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        opts = {
          ensure_installed = languages,
          highlight = { enable = true },
          indent = { enable = true },
          incremental_selection = {
            enable = true,
            keymaps = {
              init_selection = false,
              node_incremental = false,
              node_decremental = false,
            },
          },
        },
      }
    },
    init = function()
      vim.opt.runtimepath:prepend(install_dir .. "/runtime")
    end,
    opts = {
      install_dir = install_dir,
    },
    config = function(_, opts)
      local treesitter = require("nvim-treesitter")
      local selection = require("treesitter-modules.lib.selection")

      treesitter.setup(opts)

      vim.keymap.set({ "n", "x" }, "<Tab>", function()
          local buf = vim.api.nvim_get_current_buf()
          local lang = get_language(buf)

          if vim.api.nvim_get_mode().mode == "n" or not initial_cursor[buf] then
            save_initial_cursor(buf)
            ---@diagnostic disable-next-line: invisible
            selection.nodes:clear(buf)
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

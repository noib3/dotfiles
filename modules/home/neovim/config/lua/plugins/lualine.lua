local lsp_progress = require("lsp-progress")
local lualine = require("lualine")
local utils = require("utils")

lualine.setup({
  options = {
    component_separators = "",
    globalstatus = true,
    ignore_focus = function(win)
      local buf = vim.api.nvim_win_get_buf(win)
      return vim.bo[buf].buftype ~= ""
    end,
    section_separators = "",
    -- Returns the theme table with colors sourced from the current
    -- highlights. This is a function so lualine re-evaluates it on
    -- ColorScheme/OptionSet.
    theme = function()
      local colors = {
        bg = utils.highlights.bg_of("StatusLine"),
        fg = utils.highlights.fg_of("StatusLine"),
      }
      local modes = { a = colors, b = colors, c = colors }
      return {
        normal = modes,
        insert = modes,
        visual = modes,
        replace = modes,
        command = modes,
        inactive = modes,
      }
    end,
  },
  sections = {
    lualine_a = {
      lsp_progress.progress,
    },
    lualine_b = {
      {
        "diagnostics",
        diagnostics_color = {
          error = "DiagnosticError",
          warn = "DiagnosticWarn",
        },
        sections = { "error", "warn" },
        sources = { "nvim_workspace_diagnostic" },
        symbols = { error = " ", warn = " " },
      },
    },
    lualine_c = {},
    lualine_x = {},
    lualine_y = {
      "selectioncount",
      "searchcount",
    },
    lualine_z = {
      {
        "branch",
        color = {
          ---@diagnostic disable-next-line: undefined-field
          fg = vim.opt.background:get() == "dark" and "#928374" or "#7c6f64",
        },
      },
    },
  },
})

-- Refresh lualine when the LSP progress status is updated.
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("noib3/lualine", { clear = true }),
  pattern = "LspProgressStatusUpdated",
  callback = lualine.refresh --[[@as fun()]],
})

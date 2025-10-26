local utils = require("utils")

---@return table
local config = function()
  local lsp_progress = require("lsp-progress")

  local colors = {
    bg = utils.highlights.bg_of("StatusLine"),
    fg = utils.highlights.fg_of("StatusLine"),
  }

  local mode = {
    a = colors,
    b = colors,
    c = colors
  }

  return {
    options = {
      component_separators = "",
      globalstatus = true,
      ignore_focus = function(win)
        local buf = vim.api.nvim_win_get_buf(win)
        return vim.bo[buf].buftype ~= ""
      end,
      section_separators = "",
      theme = {
        normal = mode,
        insert = mode,
        visual = mode,
        replace = mode,
        command = mode,
        inactive = mode,
      },
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
            warn  = "DiagnosticWarn",
          },
          sections = { "error", "warn" },
          sources = { "nvim_workspace_diagnostic" },
          symbols = { error = " ", warn = " " },
        }
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
            fg = vim.opt.background:get() == "dark" and "#928374" or "#7c6f64"
          }
        }
      },
    },
  }
end

return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "linrongbin16/lsp-progress.nvim",
    },
    opts = config,
    config = function(_, opts)
      local lualine = require("lualine")

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function() lualine.setup(config()) end,
      })

      vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "background",
        callback = function() lualine.setup(config()) end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "LspProgressStatusUpdated",
        callback = lualine.refresh,
      })

      lualine.setup(opts)
    end
  }
}

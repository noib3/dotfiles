return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "linrongbin16/lsp-progress.nvim",
    },
    opts = function()
      local lsp_progress = require("lsp-progress")
      local colors = { bg = "#3a3735", fg = "#d4be98" }
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
              color = { fg = "#928374" }
            }
          },
        },
      }
    end,
    config = function(_, opts)
      local lualine = require("lualine")

      lualine.setup(opts)

      local group_id = vim.api.nvim_create_augroup(
        "noib3/refresh-statusline-on-lsp-progress",
        { clear = true }
      )

      vim.api.nvim_create_autocmd("User", {
        group = group_id,
        pattern = "LspProgressStatusUpdated",
        callback = lualine.refresh,
      })
    end
  }
}

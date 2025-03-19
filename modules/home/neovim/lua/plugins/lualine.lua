return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function()
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
            {
              "lsp_status",
              icons_enabled = false,
            }
          },
          lualine_b = {
            {
              "diagnostics",
              sources = { "nvim_workspace_diagnostic" },
              sections = { "error", "warn" },
              diagnostics_color = {
                error = "DiagnosticError",
                warn  = "DiagnosticWarn",
              },
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
  }
}

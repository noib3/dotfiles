return {
  {
    "b0o/incline.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local incline = require("incline")
      local devicons = require("nvim-web-devicons")
      local palette = require("generated.palette")

      local bufname = function(bufnr)
        local bufpath = vim.api.nvim_buf_get_name(bufnr)
        local bufname = vim.fn.fnamemodify(bufpath, ":t")
        return bufname ~= "" and bufname or "[No Name]"
      end

      local diagnostics = function(bufnr)
        local ret = {}
        local add_diagnostic = function(severity, icon)
          local opts = { severity = vim.diagnostic.severity[severity:upper()] }
          local count = #vim.diagnostic.get(bufnr, opts)
          if count > 0 then
            local maybe_padding = vim.tbl_count(ret) > 0 and " " or ""
            local label = maybe_padding .. icon .. " " .. count
            table.insert(ret, { label, group = "DiagnosticSign" .. severity })
          end
        end
        add_diagnostic("Error", "")
        add_diagnostic("Warn", "")
        if #ret > 0 then
          table.insert(ret, { " ︳", guifg = "#928374" })
        end
        return ret
      end

      local dirty_indicator = function(bufnr)
        local is_dirty = vim.bo[bufnr].modified
        return
            is_dirty
            and { "•", guifg = palette.bright.green, gui = "bold" }
            or ""
      end

      local file_icon = function(bufnr)
        local bufnamee = bufname(bufnr)
        local extension = vim.fn.fnamemodify(bufnamee, ":e")
        local icon, color = devicons.get_icon_color(bufnamee, extension)
        local padding = vim.bo[bufnr].modified and " " or ""
        return icon and { padding, icon, "  ", guifg = color } or ""
      end

      incline.setup({
        render = function(props)
          return {
            " ",
            diagnostics(props.buf),
            dirty_indicator(props.buf),
            file_icon(props.buf),
            bufname(props.buf),
          }
        end,
        window = {
          padding = {
            left = 0,
            right = 1,
          },
          margin = {
            horizontal = 0,
            vertical = 0,
          },
          winhighlight = {
            active = {
              Normal = {
                guifg = "#ddc7a1",
                guibg = "#3a3735",
              },
            },
            inactive = {
              Normal = {
                guifg = "#928374",
                guibg = "#3a3735",
              },
            },
          }
        }
      })

      local group = vim.api.nvim_create_augroup("noib3/refresh-incline", {
        clear = true
      })

      vim.api.nvim_create_autocmd("DiagnosticChanged", {
        group = group,
        desc = "Re-render incline",
        callback = incline.refresh,
      })
    end,
  }
}

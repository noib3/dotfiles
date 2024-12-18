return {
  {
    "b0o/incline.nvim",
    config = function()
      local devicons = require("nvim-web-devicons")
      local palette = require("generated.palette")

      require("incline").setup({
        render = function(props)
          local bufname = vim.api.nvim_buf_get_name(props.buf)
          local filename = vim.fn.fnamemodify(bufname, ":t")
          if filename == "" then
            filename = "[No Name]"
          end

          local ft_icon, ft_color = devicons.get_icon_color(filename)

          local dirty = vim.bo[props.buf].modified

          return {
            dirty and { " •", guifg = palette.bright.green, gui = "bold" } or "",
            ft_icon and { " ", ft_icon, "  ", guifg = ft_color } or "",
            filename,
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
    end,
  }
}

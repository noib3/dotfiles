return {
  {
    "b0o/incline.nvim",
    config = function()
      local devicons = require("nvim-web-devicons")

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
            dirty and { " *", guifg = "#e0af68", gui = "bold" } or "",
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
            active = { Normal = "QuickFixLine" },
            inactive = { Normal = "LspInlayHint" },
          }
        }
      })
    end,
  }
}

require('lualine').setup({
  options = {
    theme = 'onedark',
  },

  sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filetype', 'filename', 'encoding'},
    lualine_x = {'branch'},
    lualine_y = {},
    lualine_z = {},
  },

  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filetype', 'filename', 'encoding'},
    lualine_x = {'branch'},
    lualine_y = {},
    lualine_z = {},
  },
})

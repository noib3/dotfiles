{ colorscheme, palette }:

''
  local vim_cmd = vim.cmd
  local vim_g = vim.g

  local palette = {
    primary = {
      foreground = '${palette.primary.foreground}',
      background = '${palette.primary.background}',
    },

    normal = {
      black = '${palette.normal.black}',
      red = '${palette.normal.red}',
      green = '${palette.normal.green}',
      yellow = '${palette.normal.yellow}',
      blue = '${palette.normal.blue}',
      magenta = '${palette.normal.magenta}',
      cyan = '${palette.normal.cyan}',
      white = '${palette.normal.white}',
    },

    bright = {
      black = '${palette.bright.black}',
      red = '${palette.bright.red}',
      green = '${palette.bright.green}',
      yellow = '${palette.bright.yellow}',
      blue = '${palette.bright.blue}',
      magenta = '${palette.bright.magenta}',
      cyan = '${palette.bright.cyan}',
      white = '${palette.bright.white}',
    },
  }

  local setup = function()
    for normal_or_bright, colors in pairs(palette) do
      for i, hexcolor in ipairs(colors) do
        local j = (normal_or_bright == 'normal') and i or i + 8
        vim_g['terminal_color_' .. (j - 1)] = hexcolor
      end
    end

    vim_cmd('colorscheme ${colorscheme}')
  end

  return {
    palette = palette,
    setup = setup,
  }
''

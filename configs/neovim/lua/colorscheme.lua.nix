{ colorscheme, palette }:

''
  local vim_cmd = vim.cmd
  local vim_g = vim.g

  local normal_mt = {
    __index = function(t, k)
      if k == 1 or k == 'black' then
        return '${palette.normal.black}'
      elseif k == 2 or k == 'red' then
        return '${palette.normal.red}'
      elseif k == 3 or k == 'green' then
        return '${palette.normal.green}'
      elseif k == 4 or k == 'yellow' then
        return '${palette.normal.yellow}'
      elseif k == 5 or k == 'blue' then
        return '${palette.normal.blue}'
      elseif k == 6 or k == 'magenta' then
        return '${palette.normal.magenta}'
      elseif k == 7 or k == 'cyan' then
        return '${palette.normal.cyan}'
      elseif k == 8 or k == 'white' then
        return '${palette.normal.white}'
      end
    end
  }

  local bright_mt = {
    __index = function(t, k)
      if k == 1 or k == 'black' then
        return '${palette.bright.black}'
      elseif k == 2 or k == 'red' then
        return '${palette.bright.red}'
      elseif k == 3 or k == 'green' then
        return '${palette.bright.green}'
      elseif k == 4 or k == 'yellow' then
        return '${palette.bright.yellow}'
      elseif k == 5 or k == 'blue' then
        return '${palette.bright.blue}'
      elseif k == 6 or k == 'magenta' then
        return '${palette.bright.magenta}'
      elseif k == 7 or k == 'cyan' then
        return '${palette.bright.cyan}'
      elseif k == 8 or k == 'white' then
        return '${palette.bright.white}'
      end
    end
  }

  local palette = {
    primary = {
      foreground = '${palette.primary.foreground}',
      background = '${palette.primary.background}',
    },

    normal = {
      [1] = '${palette.normal.black}',
      [2] = '${palette.normal.red}',
      [3] = '${palette.normal.green}',
      [4] = '${palette.normal.yellow}',
      [5] = '${palette.normal.blue}',
      [6] = '${palette.normal.magenta}',
      [7] = '${palette.normal.cyan}',
      [8] = '${palette.normal.white}',

      ['black'] = '${palette.normal.black}',
      ['red'] = '${palette.normal.red}',
      ['green'] = '${palette.normal.green}',
      ['yellow'] = '${palette.normal.yellow}',
      ['blue'] = '${palette.normal.blue}',
      ['magenta'] = '${palette.normal.magenta}',
      ['cyan'] = '${palette.normal.cyan}',
      ['white'] = '${palette.normal.white}',
    },

    bright = {
      [1] = '${palette.bright.black}',
      [2] = '${palette.bright.red}',
      [3] = '${palette.bright.green}',
      [4] = '${palette.bright.yellow}',
      [5] = '${palette.bright.blue}',
      [6] = '${palette.bright.magenta}',
      [7] = '${palette.bright.cyan}',
      [8] = '${palette.bright.white}',

      ['black'] = '${palette.bright.black}',
      ['red'] = '${palette.bright.red}',
      ['green'] = '${palette.bright.green}',
      ['yellow'] = '${palette.bright.yellow}',
      ['blue'] = '${palette.bright.blue}',
      ['magenta'] = '${palette.bright.magenta}',
      ['cyan'] = '${palette.bright.cyan}',
      ['white'] = '${palette.bright.white}',
    },
  }

  -- Not sure why this approach doesn't work
  -- setmetatable(palette.normal, normal_mt)
  -- setmetatable(palette.bright, bright_mt)

  local setup = function()
    for i, hex in ipairs(palette.normal) do
      vim_g['terminal_color_' .. (i - 1)] = hex
    end
    for i, hex in ipairs(palette.bright) do
      vim_g['terminal_color_' .. (i + 7)] = hex
    end

    vim_cmd('colorscheme ${colorscheme}')
  end

  return {
    palette = palette,
    setup = setup,
  }
''

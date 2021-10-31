local get_hex = require('cokeline/utils').get_hex

local format = string.format
local keymap = vim.api.nvim_set_keymap

local nmaps = function(lhs, rhs)
  keymap('n', lhs, rhs, {silent = true})
end

nmaps('<S-Tab>', '<Plug>(cokeline-focus-prev)')
nmaps('<Tab>', '<Plug>(cokeline-focus-next)')
nmaps('<Leader>p', '<Plug>(cokeline-switch-prev)')
nmaps('<Leader>n', '<Plug>(cokeline-switch-next)')

for i = 1,9 do
  nmaps(format('<F%s>', i), format('<Plug>(cokeline-focus-%s)', i))
end

local saved_indicator = {
  text = '｜',
  hl = {
    fg = function(buffer)
      return
        buffer.is_modified
        and vim.g.terminal_color_3 -- yellow
         or vim.g.terminal_color_2 -- green
    end
  },
}

local devicon = {
  text = function(buffer) return buffer.devicon.icon .. ' ' end,
  hl = {
    fg = function(buffer) return buffer.devicon.color end,
  },
}

local index = {
  text = function(buffer) return buffer.index .. ': ' end,
  hl = {
    fg = function(buffer)
      return
        buffer.lsp.errors ~= 0
        and vim.g.terminal_color_1
         or nil
    end,
  },
}

local unique_prefix = {
  text = function(buffer) return buffer.unique_prefix end,
  hl = {
    fg = get_hex('Comment', 'fg'),
    style = 'italic',
  },
}

local filename = {
  text = function(buffer) return buffer.filename end,
  hl = {
    fg = function(buffer)
      if buffer.lsp.errors ~= 0 then
        return vim.g.terminal_color_1
      end
      if buffer.lsp.warnings ~= 0 then
        return vim.g.terminal_color_3
      end
      return nil
    end,
    style = function(buffer)
      local style
      if buffer.is_focused then
        style = 'bold'
      end
      if buffer.lsp.errors ~= 0 then
        if style then
          style = style .. ',underline'
        else
          style = 'underline'
        end
      end
      return style
    end,
  }
}

local space = {
  text = ' ',
}

require('cokeline').setup({
  hide_when_one_buffer = true,

  rendering = {
    min_line_width = 0,
    max_line_width = 25,
  },

  buffers = {
    filter = function(buffer)
      return buffer.type ~= 'terminal'
    end,
  },

  default_hl = {
    focused = {
      fg = get_hex('Normal', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
    unfocused = {
      fg = get_hex('Comment', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
  },

  components = {
    saved_indicator,
    devicon,
    index,
    unique_prefix,
    filename,
    space,
  },
})

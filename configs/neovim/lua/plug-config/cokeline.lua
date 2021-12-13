-- local rq_sliders = require('cokeline/sliders')
local rq_get_hex = require('cokeline/utils').get_hex

local vim_fn = vim.fn

local components = {
  space = {
    text = ' ',
    truncation = {
      priority = 1,
    }
  },

  separator = {
    text = function(buffer)
      return buffer.index ~= 1 and '▏' or ''
    end,
  },

  devicon = {
    text = function(buffer)
      return buffer.devicon.icon
    end,
    hl = {
      fg = function(buffer)
        return buffer.devicon.color
      end,
    },
  },

  index = {
    text = function(buffer)
      return buffer.index .. ': '
    end,
    hl = {
      fg = function(buffer)
        return
          buffer.diagnostics.errors ~= 0
          and rq_get_hex('DiagnosticError', 'fg')
           or nil
      end,
    },
  },

  unique_prefix = {
    text = function(buffer)
      return vim_fn.pathshorten(buffer.unique_prefix)
    end,
    hl = {
      fg = rq_get_hex('Comment', 'fg'),
      style = 'italic',
    },
    truncation = {
      priority = 7,
      direction = 'left',
    },
  },

  filename = {
    text = function(buffer)
      return buffer.filename
    end,
    hl = {
      fg = function(buffer)
        return
          (buffer.diagnostics.errors ~= 0 and rq_get_hex('DiagnosticError', 'fg'))
          or (buffer.diagnostics.warnings ~= 0 and rq_get_hex('DiagnosticWarn', 'fg'))
          or nil
      end,
      style = function(buffer)
        return
          ((buffer.is_focused and buffer.diagnostics.errors ~= 0)
            and 'bold,underline')
          or (buffer.is_focused and 'bold')
          or (buffer.diagnostics.errors ~= 0 and 'underline')
          or nil
      end
    },
    truncation = {
      direction = 'left',
    },
  },

  close_button = {
    text = '',
    delete_buffer_on_left_click = true,
    truncation = {
      priority = 5,
    },
  },
}

require('cokeline').setup({
  show_if_buffers_are_at_least = 2,

  buffers = {
    filter_valid = function(buffer) return buffer.type ~= 'terminal' end,
    new_buffers_position = 'next',
  },

  rendering = {
    max_buffer_width = 30,
    -- slider = rq_sliders.slide_if_needed,
  },

  default_hl = {
    focused = {
      fg = rq_get_hex('Normal', 'fg'),
      bg = rq_get_hex('ColorColumn', 'bg'),
    },
    unfocused = {
      fg = rq_get_hex('Comment', 'fg'),
      bg = rq_get_hex('ColorColumn', 'bg'),
    },
  },

  components = {
    components.space,
    components.separator,
    components.devicon,
    components.space,
    components.index,
    components.unique_prefix,
    components.filename,
    components.space,
    components.close_button,
    components.space,
  },
})

local get_hex = require("cokeline/utils").get_hex
local palette = require("colorscheme").palette
local mappings = require("cokeline/mappings")

local rep = string.rep

local comments_fg = get_hex("Comment", "fg")
local errors_fg = get_hex("DiagnosticError", "fg")
local warnings_fg = get_hex("DiagnosticWarn", "fg")

local min_buffer_width = 23

local components = {
  separator = {
    text = " ",
    bg = get_hex("Normal", "bg"),
    truncation = { priority = 1 },
  },

  space = {
    text = " ",
    truncation = { priority = 1 },
  },

  left_half_circle = {
    text = "",
    fg = function(buffer)
      return buffer.is_focused and "#323234" or get_hex("ColorColumn", "bg")
    end,
    bg = get_hex("Normal", "bg"),
    truncation = { priority = 1 },
  },

  right_half_circle = {
    text = "",
    fg = function(buffer)
      return buffer.is_focused and "#323234" or get_hex("ColorColumn", "bg")
    end,
    bg = get_hex("Normal", "bg"),
    truncation = { priority = 1 },
  },

  devicon_or_pick_letter = {
    text = function(buffer)
      return (mappings.is_picking_focus() or mappings.is_picking_close())
          and buffer.pick_letter .. " "
        or buffer.devicon.icon
    end,
    fg = function(buffer)
      return (mappings.is_picking_focus() and palette.normal.yellow)
        or (mappings.is_picking_close() and palette.normal.red)
        or (buffer.is_focused and buffer.devicon.color or comments_fg)
    end,
    style = function(_)
      return (mappings.is_picking_focus() or mappings.is_picking_close())
          and "italic,bold"
        or nil
    end,
    truncation = { priority = 1 },
  },

  index = {
    text = function(buffer)
      return buffer.index .. ": "
    end,
    fg = function(buffer)
      return (buffer.diagnostics.errors ~= 0 and errors_fg)
        or (buffer.diagnostics.warnings ~= 0 and warnings_fg)
        or nil
    end,
    truncation = { priority = 1 },
  },

  unique_prefix = {
    text = function(buffer)
      return buffer.unique_prefix
    end,
    fg = comments_fg,
    style = "italic",
    truncation = {
      priority = 4,
      direction = "left",
    },
  },

  filename_root = {
    text = function(buffer)
      return vim.fn.fnamemodify(buffer.filename, ":r")
    end,
    fg = function(buffer)
      return (buffer.diagnostics.errors ~= 0 and errors_fg)
        or (buffer.diagnostics.warnings ~= 0 and warnings_fg)
        or nil
    end,
    style = function(buffer)
      return (
          (buffer.is_focused and buffer.diagnostics.errors ~= 0)
          and "bold,underline"
        )
        or (buffer.is_focused and "bold")
        or (buffer.diagnostics.errors ~= 0 and "underline")
        or nil
    end,
    truncation = {
      priority = 3,
      direction = "middle",
    },
  },

  filename_extension = {
    text = function(buffer)
      local ext = vim.fn.fnamemodify(buffer.filename, ":e")
      return ext ~= "" and "." .. ext or ""
    end,
    fg = function(buffer)
      return (buffer.diagnostics.errors ~= 0 and errors_fg)
        or (buffer.diagnostics.warnings ~= 0 and warnings_fg)
        or nil
    end,
    style = function(buffer)
      return (
          (buffer.is_focused and buffer.diagnostics.errors ~= 0)
          and "bold,underline"
        )
        or (buffer.is_focused and "bold")
        or (buffer.diagnostics.errors ~= 0 and "underline")
        or nil
    end,
    truncation = {
      priority = 2,
      direction = "left",
    },
  },

  -- diagnostics = {
  --   text = function(buffer)
  --     return
  --       (buffer.diagnostics.errors ~= 0 and '  ' .. buffer.diagnostics.errors)
  --       or (buffer.diagnostics.warnings ~= 0 and '  ' .. buffer.diagnostics.warnings)
  --       or ''
  --   end,
  --   hl = {
  --     fg = function(buffer)
  --       return
  --         (buffer.diagnostics.errors ~= 0 and errors_fg)
  --         or (buffer.diagnostics.warnings ~= 0 and warnings_fg)
  --         or nil
  --     end,
  --   },
  --   truncation = { priority = 1 },
  -- },

  close_or_unsaved = {
    text = function(buffer)
      return buffer.is_modified and "●" or ""
    end,
    fg = function(buffer)
      return buffer.is_modified and palette.normal.green or nil
    end,
    delete_buffer_on_left_click = true,
    truncation = { priority = 1 },
  },
}

local get_remaining_space = function(buffer)
  local used_space = 0
  for _, component in pairs(components) do
    used_space = used_space
      + vim.fn.strwidth(
        (type(component.text) == "string" and component.text)
          or (type(component.text) == "function" and component.text(buffer))
      )
  end
  return math.max(0, min_buffer_width - used_space)
end

local left_padding = {
  text = function(buffer)
    local remaining_space = get_remaining_space(buffer)
    return rep(" ", remaining_space / 2 + remaining_space % 2)
  end,
}

local right_padding = {
  text = function(buffer)
    local remaining_space = get_remaining_space(buffer)
    return rep(" ", remaining_space / 2)
  end,
}

require("cokeline").setup({
  show_if_buffers_are_at_least = 1,

  buffers = {
    -- filter_valid = function(buffer) return buffer.type ~= 'terminal' end,
    -- filter_visible = function(buffer) return buffer.type ~= 'terminal' end,
    focus_on_delete = "next",
    new_buffers_position = "next",
  },

  rendering = {
    max_buffer_width = 23,
  },

  default_hl = {
    fg = function(buffer)
      return buffer.is_focused and get_hex("Normal", "fg")
        or get_hex("Comment", "fg")
    end,
    bg = function(buffer)
      return buffer.is_focused and "#323234" or get_hex("ColorColumn", "bg")
    end,
  },

  sidebar = {
    filetype = "NvimTree",
    components = {
      {
        text = "",
        -- text = "  NvimTree",
        fg = palette.normal.yellow,
        bg = get_hex("NvimTreeNormal", "bg"),
        style = "bold",
      },
    },
  },

  components = {
    components.separator,
    components.left_half_circle,
    left_padding,
    components.devicon_or_pick_letter,
    components.index,
    components.unique_prefix,
    components.filename_root,
    components.filename_extension,
    -- components.diagnostics,
    components.space,
    right_padding,
    components.close_or_unsaved,
    components.right_half_circle,
  },
})

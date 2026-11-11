local fzf = require("fzf-lua")
local logos = require("utils.logos")

fzf.setup({
  winopts = {
    backdrop = 100,
    border = { "", "", "", "", "─", "─", "─", "" },
    col = 0.0,
    row = 0.0,
    height = 8,
    width = 1.0,
  },
  fzf_colors = {
    ["bg+"] = { "bg", "ColorColumn" },
    ["border"] = { "fg", "WinSeparator" },
  },
})

fzf.register_ui_select()

--- Returns a text with the logos that have a brand color in that color, as ANSI
--- escape codes.
---@param text string
---@return string
local color_logos = function(text)
  for _, logo in pairs(logos) do
    if logo.color then
      local rgb = assert(tonumber(logo.color:sub(2), 16))
      local escape = ("\27[38;2;%d;%d;%dm"):format(
        math.floor(rgb / 0x10000) % 0x100,
        math.floor(rgb / 0x100) % 0x100,
        rgb % 0x100
      )
      text = text:gsub(vim.pesc(logo.icon), escape .. logo.icon .. "\27[0m")
    end
  end
  return text
end

local select = vim.ui.select
---@diagnostic disable-next-line: duplicate-set-field
vim.ui.select = function(items, opts, on_choice)
  opts = opts or {}
  local format_item = opts.format_item or tostring
  select(
    items,
    vim.tbl_extend("force", opts, {
      format_item = function(item) return color_logos(format_item(item)) end,
    }),
    on_choice
  )
end

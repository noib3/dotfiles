local devicons = require("nvim-web-devicons")
local highlights = require("highlights")

local sep = "/"
local winbar_hl = "WinBar"
local winbar_bg = highlights.bg_of(winbar_hl)

--- Returns the full path of the project root for the given buffer.
--- @param bufnr number
--- @return string
local buf_project_root = function(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local project_root = vim.fs.root(filepath, { ".git", "Cargo.toml" })
  return project_root or vim.fs.dirname(filepath)
end

--- Returns whether the winbar should be displayed for the given buffer.
---
--- @param bufnr number
--- @return boolean
local buf_should_display_winbar = function(bufnr)
  return
      vim.bo[bufnr].buftype == ""
      and vim.api.nvim_buf_get_name(bufnr) ~= ""
      and not vim.api.nvim_win_get_config(0).zindex
end

--- Wraps the text in the given highlight group according to the statusline
--- highlight format.
---
--- @param text string
--- @param hl_group string
--- @return string
local highlight = function(text, hl_group)
  return ("%%#%s#%s"):format(hl_group, text)
end

local M = {}

--- A component that displays the devicon for the current buffer in the correct
--- highlight group.
---
--- @param bufnr number
--- @return string
M.devicon = function(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local extension = vim.fn.fnamemodify(filepath, ":e")
  local icon, hl = devicons.get_icon(filepath, extension, { default = true })
  -- Having to re-create a new hl group for each icon just to make the
  -- background color blend in is honestly kinda retarded.
  local hl_group = highlights.HlGroup:new({
    name = hl .. "Noib3",
    fg = highlights.fg_of(hl),
    bg = winbar_bg,
  })
  return highlight(("%s"):format(icon), hl_group.name)
end

--- @param bufnr number
--- @param modified_char string
--- @return string
M.saved_indicator = function(bufnr, modified_char)
  local is_modified = vim.api.nvim_buf_get_option(bufnr, "modified")

  local char =
      is_modified and modified_char
      or (" "):rep(vim.fn.strwidth(modified_char))

  local hl_group = highlights.HlGroup:new({
    name = "WinBarSavedIndicator",
    fg = highlights.fg_of("WarningMsg"),
    bg = winbar_bg,
  })

  return highlight(char, hl_group.name)
end

--- @param bufnr number
--- @return string
M.file_name = function(bufnr)
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
  local hl_group = highlights.HlGroup:new({
    name = "WinBarFileName",
    fg = highlights.fg_of("Label"),
    bg = winbar_bg,
  })
  return highlight(filename, hl_group.name)
end

--- @param bufnr number
--- @return string
M.file_path = function(bufnr)
  local root_path = buf_project_root(bufnr)

  local root_name =
      root_path == vim.env.HOME and "~"
      or root_path:match("([^/]+)$")

  -- The absolute path of the buffer relative to the project root.
  local buf_abs_path = vim.api.nvim_buf_get_name(bufnr):sub(#root_path + 1)

  local buf_parent_path = vim.fs.dirname(buf_abs_path)

  local intermediates =
      buf_parent_path == "/" and sep
      or vim.iter(vim.split(buf_parent_path, sep)):map(
        function(dirname)
          return dirname
        end
      ):join(sep) .. sep

  local hl_group = highlights.HlGroup:new({
    name = "WinBarPath",
    fg = highlights.fg_of("Title"),
    bg = winbar_bg,
  })

  return table.concat({
    highlight(root_name, hl_group.name),
    highlight(intermediates, hl_group.name),
  })
end

--- Renders the winbar.
M.render = function()
  local bufnr = vim.api.nvim_get_current_buf()

  return table.concat({
    M.saved_indicator(bufnr, "▏"), -- 
    M.devicon(bufnr),
    highlight("  ", winbar_hl),
    M.file_name(bufnr),
    highlight(" in ", winbar_hl),
    M.file_path(bufnr),
  })
end

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("noib3/winbar", { clear = true }),
  desc = "Render the winbar",
  callback = function(args)
    if buf_should_display_winbar(args.buf) then
      vim.wo.winbar = "%{%v:lua.require'winbar'.render()%}"
    end
  end,
})

return M

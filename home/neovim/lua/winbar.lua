local devicons = require("nvim-web-devicons")
local highlights = require("highlights")

local sep = "/"

--- Returns the file type icon for the given buffer.
--- @param bufnr number
--- @return string
local buf_icon = function(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local extension = vim.fn.fnamemodify(filepath, ":e")
  return devicons.get_icon(filepath, extension, { default = true })
end

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

--- @param bufnr number
--- @return string
M.saved_indicator = function(bufnr)
  local is_modified = vim.api.nvim_buf_get_option(bufnr, "modified")
  return
      is_modified and highlight("", highlights.WinBarSavedIndicator.name)
      or " "
end

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

  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")

  return table.concat({
    highlight(" ", highlights.WinBar.name),
    highlight(root_name, highlights.WinBarPath.name),
    highlight(intermediates, highlights.WinBarPath.name),
    highlight(filename, highlights.WinBarFileName.name),
    -- highlight(" ", "Normal"),
    -- highlight(buf_icon(bufnr), "Normal"),
  })
end

--- Renders the winbar.
M.render = function()
  local bufnr = vim.api.nvim_get_current_buf()

  return table.concat({
    M.saved_indicator(bufnr),
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

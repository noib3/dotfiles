vim.env.VSCODE_DIFF_NO_AUTO_INSTALL = "1"

local codediff = require("codediff")
local diff = require("codediff.core.diff")
local git = require("codediff.core.git")
local inline = require("codediff.ui.inline")

codediff.setup({
  diff = {
    gutter_signs = false,
  },
})

---@class ConfigCodeDiffState
---@field enabled boolean
---@field original_lines? string[]
---@field render_request integer
---@field request integer

---@type table<integer, ConfigCodeDiffState>
local states = {}

local diff_options = {
  compute_moves = false,
  extend_to_subwords = true,
  ignore_trim_whitespace = false,
  max_computation_time_ms = 5000,
}

---@param bufnr integer
local clear = function(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then inline.clear(bufnr) end
end

-- CodeDiff deliberately paints added lines through EOL and pads deleted
-- virtual lines to the window width. Keep its diff and syntax chunks, but
-- constrain their backgrounds to actual buffer text.
---@param bufnr integer
local trim_line_highlights = function(bufnr)
  local padding = string.rep(" ", 300)
  local marks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    inline.ns_inline,
    0,
    -1,
    { details = true, hl_name = true }
  )

  for _, mark in ipairs(marks) do
    local id, row, col, details = mark[1], mark[2], mark[3], mark[4]
    local details_virtual_lines = details and details.virt_lines
    if details and details_virtual_lines then
      local virtual_lines = vim.deepcopy(details_virtual_lines)
      for _, line in ipairs(virtual_lines) do
        local last = line[#line]
        if last and last[1] == padding then table.remove(line) end
      end

      vim.api.nvim_buf_set_extmark(bufnr, inline.ns_inline, row, col, {
        id = id,
        priority = details.priority,
        virt_lines = virtual_lines,
        virt_lines_above = details.virt_lines_above,
        virt_lines_overflow = rawget(details, "virt_lines_overflow"),
      })
    elseif details and details.hl_eol then
      vim.api.nvim_buf_set_extmark(bufnr, inline.ns_inline, row, col, {
        end_col = details.end_col,
        end_row = details.end_row,
        hl_eol = false,
        hl_group = details.hl_group,
        id = id,
        priority = details.priority,
      })
    end
  end
end

---@param bufnr integer
local render = function(bufnr)
  local state = states[bufnr]
  if
    not state
    or not state.enabled
    or not state.original_lines
    or not vim.api.nvim_buf_is_valid(bufnr)
  then
    return
  end

  local modified_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local ok, result =
    pcall(diff.compute_diff, state.original_lines, modified_lines, diff_options)
  if not ok or type(result) ~= "table" then
    clear(bufnr)
    vim.notify(
      "Could not compute inline diff: " .. tostring(result),
      vim.log.levels.ERROR
    )
    return
  end

  local rendered, render_error = pcall(
    inline.render_inline_diff,
    bufnr,
    result,
    state.original_lines,
    modified_lines,
    { filetype = vim.bo[bufnr].filetype }
  )
  if not rendered then
    clear(bufnr)
    vim.notify(
      "Could not render inline diff: " .. render_error,
      vim.log.levels.ERROR
    )
    return
  end

  trim_line_highlights(bufnr)
end

---@param error string
---@return boolean
local is_untracked = function(error)
  return error:match("not found in revision ':0'") ~= nil
end

---@param bufnr integer
---@param notify boolean?
local refresh_reference = function(bufnr, notify)
  local state = states[bufnr]
  if not state or not state.enabled or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if vim.bo[bufnr].buftype ~= "" or path == "" then
    state.enabled = false
    clear(bufnr)
    if notify then
      vim.notify("Inline diff requires a file buffer", vim.log.levels.INFO)
    end
    return
  end

  path = vim.uv.fs_realpath(path) or path
  state.request = state.request + 1
  local request = state.request

  local finish = function(original_lines, error)
    vim.schedule(function()
      state = states[bufnr]
      if
        not state
        or not state.enabled
        or state.request ~= request
        or not vim.api.nvim_buf_is_valid(bufnr)
      then
        return
      end

      if error then
        if not state.original_lines then
          state.enabled = false
          clear(bufnr)
        end
        if notify then vim.notify(error, vim.log.levels.WARN) end
        return
      end

      state.original_lines = original_lines
      render(bufnr)
    end)
  end

  git.get_git_root(path, function(root_error, root)
    if root_error or not root then
      finish(nil, root_error or "Could not find the Git repository")
      return
    end

    local relative_path = git.get_relative_path(path, root)
    git.get_file_content(":0", root, relative_path, function(error, lines)
      if error and is_untracked(error) then
        finish({})
      else
        finish(lines, error)
      end
    end)
  end)
end

---@param bufnr integer
local schedule_render = function(bufnr)
  local state = states[bufnr]
  if not state or not state.enabled or not state.original_lines then return end

  state.render_request = state.render_request + 1
  local request = state.render_request
  vim.defer_fn(function()
    state = states[bufnr]
    if state and state.enabled and state.render_request == request then
      render(bufnr)
    end
  end, 120)
end

vim.keymap.set("n", "th", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local state = states[bufnr]
  if not state then
    state = { enabled = false, render_request = 0, request = 0 }
    states[bufnr] = state
  end

  state.enabled = not state.enabled
  state.request = state.request + 1
  state.render_request = state.render_request + 1
  if state.enabled then
    refresh_reference(bufnr, true)
  else
    clear(bufnr)
  end
end, {
  desc = "Toggle the inline diff overlay",
})

local group = vim.api.nvim_create_augroup("noib3/codediff", { clear = true })

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
  group = group,
  callback = function(event) schedule_render(event.buf) end,
  desc = "Updates the inline diff after buffer changes",
})

vim.api.nvim_create_autocmd(
  { "BufEnter", "BufFilePost", "FileChangedShellPost" },
  {
    group = group,
    callback = function(event) refresh_reference(event.buf) end,
    desc = "Refreshes the inline diff reference",
  }
)

vim.api.nvim_create_autocmd("FocusGained", {
  group = group,
  callback = function() refresh_reference(vim.api.nvim_get_current_buf()) end,
  desc = "Refreshes the inline diff after returning to Neovim",
})

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "GitSignsUpdate",
  callback = function(event)
    local bufnr = event.data and event.data.buffer
    if bufnr then refresh_reference(bufnr) end
  end,
  desc = "Refreshes the inline diff after the Git index changes",
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = function()
    vim.schedule(function()
      for bufnr, state in pairs(states) do
        if state.enabled then render(bufnr) end
      end
    end)
  end,
  desc = "Updates inline diff highlights after a color scheme change",
})

vim.api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(event) states[event.buf] = nil end,
  desc = "Forgets inline diff state for deleted buffers",
})

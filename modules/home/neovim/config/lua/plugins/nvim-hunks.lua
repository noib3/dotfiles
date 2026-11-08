local hunks = require("nvim_hunks")

hunks.setup()

vim.keymap.set("n", "th", hunks.toggle, {
  desc = "Toggle the diffs against the parent jj change",
})

--- Sets the keys of a diffed buffer, or of a float of its deleted lines.
---@param buf integer
---@param is_float boolean
local set_keymaps = function(buf, is_float)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
  end

  for keys, direction in pairs({
    j = 1,
    k = -1,
    ["<Down>"] = 1,
    ["<Up>"] = -1,
  }) do
    local motion = keys:match("^<") and "g" .. keys or keys
    map(
      "n",
      keys,
      function() hunks.step(direction, motion) end,
      "Move by lines, stepping through deleted lines"
    )
  end

  -- Off a hunk, the keys keep their built-in meaning.
  local move_or_fallback = function(into, keys)
    if hunks.move(into) then return end
    local count = vim.v.count > 0 and tostring(vim.v.count) or ""
    vim.api.nvim_feedkeys(count .. keys, "n", false)
  end

  map(
    { "n", "x" },
    "-",
    function() move_or_fallback("@-", "-") end,
    "Move the hunk or the selected lines to the parent change"
  )
  map(
    { "n", "x" },
    "+",
    function() move_or_fallback("@+", "+") end,
    "Move the hunk or the selected lines to the child change"
  )

  if not is_float then
    map(
      "n",
      "]]",
      function() hunks.goto_hunk(vim.v.count1) end,
      "Go to the next hunk"
    )
    map(
      "n",
      "[[",
      function() hunks.goto_hunk(-vim.v.count1) end,
      "Go to the previous hunk"
    )
  end
end

local group = vim.api.nvim_create_augroup("noib3/nvim-hunks", { clear = true })

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "NvimHunksAttach",
  desc = "Sets the keymaps of diffed buffers",
  callback = function(ev) set_keymaps(ev.data.buf, ev.data.float) end,
})

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "NvimHunksDetach",
  desc = "Removes the keymaps of diffed buffers",
  callback = function(ev)
    local buf = ev.data.buf
    if not vim.api.nvim_buf_is_valid(buf) then return end
    for _, mode_keys in ipairs({
      { "n", { "j", "k", "<Down>", "<Up>", "]]", "[[", "-", "+" } },
      { "x", { "-", "+" } },
    }) do
      for _, keys in ipairs(mode_keys[2]) do
        pcall(vim.keymap.del, mode_keys[1], keys, { buffer = buf })
      end
    end
  end,
})

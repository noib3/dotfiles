local M = {}

--- Moves the cursor by lines, stepping through the floats of the threads'
--- virtual lines and of the deleted lines of hunks.
---@param direction 1|-1
---@param keys string The keys moving the cursor by one line, e.g. `j`.
M.step = function(direction, keys)
  if require("nvim_threads").step(direction, keys) then return end
  require("nvim_hunks").step(direction, keys)
end

--- Maps the keys moving the cursor by lines in a buffer to `step()`.
---@param buf integer
M.set_step_keymaps = function(buf)
  for keys, direction in pairs({
    j = 1,
    k = -1,
    ["<Down>"] = 1,
    ["<Up>"] = -1,
  }) do
    local motion = keys:match("^<") and "g" .. keys or keys
    vim.keymap.set("n", keys, function() M.step(direction, motion) end, {
      buffer = buf,
      desc = "Move by lines, stepping through threads and deleted lines",
    })
  end
end

return M

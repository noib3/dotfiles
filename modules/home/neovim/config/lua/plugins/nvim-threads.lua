local hunks = require("nvim_hunks")
local motion = require("utils.motion")
local threads = require("nvim_threads")

threads.setup()

vim.keymap.set(
  { "n", "x" },
  "<S-CR>",
  function() threads.create() end,
  { desc = "Open a new thread on the selected lines, or on the cursor's line" }
)

--- Runs the keys with their built-in meaning, before the keys typed after
--- them.
---@param keys string
local fallback = function(keys)
  local count = vim.v.count > 0 and tostring(vim.v.count) or ""
  vim.api.nvim_feedkeys(count .. vim.keycode(keys), "ni", false)
end

--- Sets the keys of a float displaying a thread.
---@param buf integer
local set_float_keymaps = function(buf)
  ---@param modes string|string[]
  ---@param lhs string
  ---@param rhs fun()
  ---@param desc string
  local map = function(modes, lhs, rhs, desc)
    vim.keymap.set(modes, lhs, rhs, { buffer = buf, desc = desc })
  end

  map(
    "n",
    "<CR>",
    function()
      if not threads.activate() then fallback("<CR>") end
    end,
    "Expand or collapse the thread, review its suggested edits, or send the comment"
  )
  -- Like in a terminal, the keys entering insert mode go back to the
  -- composer.
  for _, keys in ipairs({ "i", "a", "I", "A", "o", "O" }) do
    map("n", keys, function()
      if not threads.insert_in_composer() then fallback(keys) end
    end, "Insert in the composer")
  end
  map("n", "dd", function()
    if not threads.delete() then fallback("dd") end
  end, "Delete the thread")
  for keys, into in pairs({ ["-"] = "@-", ["+"] = "@+" }) do
    map("n", keys, function()
      if not threads.move_thread(into) then fallback(keys) end
    end, ("Move the thread into `%s`"):format(into))
  end
end

local group =
  vim.api.nvim_create_augroup("noib3/nvim-threads", { clear = true })

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "NvimThreadsAttach",
  desc = "Sets the keymaps of buffers with threads and of their floats",
  callback = function(ev)
    local buf = ev.data.buf
    motion.set_step_keymaps(buf)
    if ev.data.float then return set_float_keymaps(buf) end
    vim.keymap.set(
      "n",
      "]t",
      function() threads.goto_thread(vim.v.count1) end,
      { buffer = buf, desc = "Go to the next thread" }
    )
    vim.keymap.set(
      "n",
      "[t",
      function() threads.goto_thread(-vim.v.count1) end,
      { buffer = buf, desc = "Go to the previous thread" }
    )
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "NvimHunksMoved",
  desc = "Moves the threads of the moved lines with them",
  callback = function(ev)
    local data = ev.data
    threads.move(data.root, data.path, data.lines, data.into)
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "NvimThreadsSuggestion",
  desc = "Diffs the suggested edits against the file",
  callback = function(ev) hunks.attach_base(ev.data.buf, ev.data.base) end,
})

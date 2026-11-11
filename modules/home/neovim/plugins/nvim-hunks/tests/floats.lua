local h = require("nvim_hunks_tests")
local hunks = require("nvim_hunks")

h.setup(80, 24)

---@param lines string[]
---@return string
local text = function(lines) return table.concat(lines, "\n") .. "\n" end

local root = h.repo(
  { ["f.txt"] = text({ "1", "2", "3", "4", "5" }) },
  -- Line 3 is deleted.
  { ["f.txt"] = text({ "1", "2", "4", "5" }) }
)

--- Opens the file with its diff shown, and steps into the float of its
--- deleted line.
---@return integer buf The file's buffer.
local step_into_deleted = function()
  vim.cmd.edit(vim.fs.joinpath(root, "f.txt"))
  local buf = vim.api.nvim_get_current_buf()
  if not hunks.hunks(buf) then hunks.toggle() end
  h.wait(function() return #(hunks.hunks(buf) or {}) == 1 end, "the diff is shown")
  -- The deleted line is above the line after it.
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  hunks.step(-1, "k")
  h.eq(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "3" }, "the cursor is in the float")
  return buf
end

test("a float of deleted lines works in its file's window's directory", function()
  local buf = step_into_deleted()
  vim.cmd.wincmd("p")
  local elsewhere = assert(vim.uv.fs_mkdtemp(vim.fs.joinpath(assert(vim.uv.os_tmpdir()), "elsewhere-XXXXXX")))
  vim.cmd.cd(vim.fn.fnameescape(elsewhere))
  vim.api.nvim_buf_call(buf, function() vim.cmd.bcd(vim.fn.fnameescape(root)) end)
  step_into_deleted()
  h.eq(vim.fn.getcwd(), root)
end)

test("toggling the diff from a float of deleted lines hides its file's", function()
  local buf = step_into_deleted()
  local messages = {}
  local notify = vim.notify
  vim.notify = function(message) messages[#messages + 1] = message end
  hunks.toggle()
  vim.notify = notify
  h.eq(messages, {})
  h.eq(hunks.hunks(buf), nil, "the file's diff is hidden")
end)

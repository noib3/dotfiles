-- Runs the tests of the file in `$TEST_FILE` in this Neovim, then quits it
-- with a non-zero exit code if any of them failed. The file registers its
-- tests with the global `test()`, which runs them in order, and can require
-- the modules in the `lib` directory next to it.

---@class test.Test
---@field name string
---@field run fun()

---@type test.Test[]
local tests = {}

---@param name string
---@param run fun()
_G.test = function(name, run) tests[#tests + 1] = { name = name, run = run } end

local file = assert(vim.env.TEST_FILE, "$TEST_FILE is unset")
package.path = ("%s/lib/?.lua;%s"):format(vim.fs.dirname(file), package.path)

local ok, err = xpcall(dofile, debug.traceback, file)
if not ok then
  io.stderr:write(("error loading %s:\n%s\n"):format(file, err))
  vim.cmd.cquit({ count = 1 })
end

--- Returns a duration like `716ms`, or `2.3s` from a second on.
---@param ns integer
---@return string
local duration = function(ns)
  local ms = ns / 1e6
  if ms < 1000 then return ("%dms"):format(ms) end
  return ("%.1fs"):format(ms / 1000)
end

local failed = 0
for _, t in ipairs(tests) do
  local start = vim.uv.hrtime()
  local passed, test_err = xpcall(t.run, debug.traceback)
  local took = duration(vim.uv.hrtime() - start)
  if passed then
    io.stdout:write(("ok    %s (%s)\n"):format(t.name, took))
  else
    failed = failed + 1
    io.stdout:write(("FAIL  %s (%s)\n%s\n"):format(t.name, took, test_err))
  end
  -- Each result shows up as soon as its test is done.
  io.stdout:flush()
end

vim.cmd.cquit({ count = failed > 0 and 1 or 0 })

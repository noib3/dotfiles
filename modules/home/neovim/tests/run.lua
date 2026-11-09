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

local failed = 0
for _, t in ipairs(tests) do
  local passed, test_err = xpcall(t.run, debug.traceback)
  if passed then
    io.stdout:write(("ok    %s\n"):format(t.name))
  else
    failed = failed + 1
    io.stdout:write(("FAIL  %s\n%s\n"):format(t.name, test_err))
  end
  -- Each result shows up as soon as its test is done.
  io.stdout:flush()
end

vim.cmd.cquit({ count = failed > 0 and 1 or 0 })

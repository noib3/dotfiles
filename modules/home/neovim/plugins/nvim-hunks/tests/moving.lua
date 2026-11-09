local h = require("nvim_hunks_tests")
local hunks = require("nvim_hunks")

h.setup(80, 24)

---@param lines string[]
---@return string
local text = function(lines) return table.concat(lines, "\n") .. "\n" end

local root = h.repo({
  ["f.txt"] = text({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" }),
  ["ren.txt"] = text({ "one", "two", "three", "four", "five", "six" }),
  ["gone.txt"] = text({ "gone" }),
}, {
  -- Line 2 changes, line 5 is deleted, and two lines are added after line 8.
  ["f.txt"] = text({
    "1",
    "TWO",
    "3",
    "4",
    "6",
    "7",
    "8",
    "8a",
    "8b",
    "9",
    "10",
  }),
  ["src/ren.txt"] = text({ "one", "TWO", "three", "four", "five", "six" }),
  ["new.txt"] = text({ "new" }),
})

--- Returns a changed file of the working-copy commit.
---@param path string
---@param repo? string The repo's root, by default the one of the tests.
---@return nvim_hunks.File
local changed = function(path, repo)
  ---@type nvim_hunks.File?
  local found
  local done = false
  hunks.files({ repo or root }, function(files)
    for _, file in ipairs(files) do
      if file.path == path then found = file end
    end
    done = true
  end)
  h.wait(function() return done end, "the files are listed")
  return (assert(found, path .. " isn't changed"))
end

---@param path string
---@param repo? string
---@return string?
local in_parent = function(path, repo)
  return h.file_at(repo or root, "@-", path)
end

---@param path string
---@param expected string?
---@param repo? string
local wait_in_parent = function(path, expected, repo)
  h.wait(
    function() return in_parent(path, repo) == expected end,
    ("%s is %s in the parent"):format(path, vim.inspect(expected))
  )
end

test("moving a hunk takes only its lines", function()
  local file = changed("f.txt")
  hunks.move_hunk(file, assert(file.hunks[1]), "@-")
  wait_in_parent(
    "f.txt",
    text({ "1", "TWO", "3", "4", "5", "6", "7", "8", "9", "10" })
  )
end)

test("moving selected lines takes only those", function()
  vim.cmd.edit(vim.fs.joinpath(root, "f.txt"))
  local buf = vim.api.nvim_get_current_buf()
  hunks.toggle()
  -- The diff is against the parent the first hunk moved into.
  h.wait(
    function() return #(hunks.hunks(buf) or {}) == 2 end,
    "the diff shows the two other hunks"
  )

  vim.keymap.set("x", "<F1>", function() hunks.move("@-") end)
  vim.api.nvim_win_set_cursor(0, { 8, 0 })
  vim.api.nvim_feedkeys(vim.keycode("V<F1>"), "xt", false)
  wait_in_parent(
    "f.txt",
    text({ "1", "TWO", "3", "4", "5", "6", "7", "8", "8a", "9", "10" })
  )
  h.wait(function()
    local last = (hunks.hunks(buf) or {})[2]
    return last and last.new_count == 1
  end, "the diff only adds the other line")
end)

test("a deleted line moves from the float showing it", function()
  -- The deleted line is above the line after it.
  vim.api.nvim_win_set_cursor(0, { 5, 0 })
  hunks.step(-1, "k")
  h.eq(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "5" })
  hunks.move("@-")
  wait_in_parent(
    "f.txt",
    text({ "1", "TWO", "3", "4", "6", "7", "8", "8a", "9", "10" })
  )
end)

test("a renamed file's first move takes only the rename", function()
  hunks.move_file(changed("src/ren.txt"), "@-")
  wait_in_parent(
    "src/ren.txt",
    text({ "one", "two", "three", "four", "five", "six" })
  )
  h.eq(in_parent("ren.txt"), nil)

  local file = changed("src/ren.txt")
  h.eq(file.status, "modified")
  hunks.move_file(file, "@-")
  wait_in_parent(
    "src/ren.txt",
    text({ "one", "TWO", "three", "four", "five", "six" })
  )
end)

test("deleted and new files move whole", function()
  hunks.move_file(changed("gone.txt"), "@-")
  wait_in_parent("gone.txt", nil)
  hunks.move_file(changed("new.txt"), "@-")
  wait_in_parent("new.txt", text({ "new" }))
end)

test("moving from an outdated diff doesn't undo the moves before", function()
  local repo = h.repo(
    { ["g.txt"] = text({ "a", "b", "c", "d" }) },
    { ["g.txt"] = text({ "A", "b", "c", "D" }) }
  )
  local file = changed("g.txt", repo)
  hunks.move_hunk(file, assert(file.hunks[1]), "@-")
  wait_in_parent("g.txt", text({ "A", "b", "c", "d" }), repo)

  -- The file's hunks still have the base from before the first move.
  local messages = {}
  local notify = vim.notify
  vim.notify = function(message) messages[#messages + 1] = message end
  hunks.move_hunk(file, assert(file.hunks[2]), "@-")
  h.wait(function() return #messages > 0 end, "the move is refused")
  vim.notify = notify
  h.eq(messages, { "The diff was out of date, try again" })
  h.eq(in_parent("g.txt", repo), text({ "A", "b", "c", "d" }))
end)

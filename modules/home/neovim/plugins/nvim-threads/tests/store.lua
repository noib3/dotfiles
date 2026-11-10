local h = require("nvim_threads_tests")
local store = require("nvim_threads.store")

---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@return nvim_threads.Thread
local thread_at = function(start_row, start_col, end_row, end_col)
  return {
    id = ("%d:%d"):format(start_row, start_col),
    anchor = {
      start_row = start_row,
      start_col = start_col,
      end_row = end_row,
      end_col = end_col,
    },
    comments = {},
    participants = {},
  }
end

test("anchors below added lines move down with their columns", function()
  local thread = thread_at(2, 1, 2, 3)
  local entry = { snapshot = { "a", "b", "cdef" }, threads = { thread } }
  store.remap(entry, { "new", "a", "also new", "b", "cdef" })
  h.eq(
    thread.anchor,
    { start_row = 4, start_col = 1, end_row = 4, end_col = 3 }
  )
  h.eq(thread.outdated, nil)
end)

test("anchors above changed lines stay where they are", function()
  local thread = thread_at(0, 0, 1, 1)
  local entry = { snapshot = { "a", "b", "c", "d" }, threads = { thread } }
  store.remap(entry, { "a", "b", "C", "d", "e" })
  h.eq(
    thread.anchor,
    { start_row = 0, start_col = 0, end_row = 1, end_col = 1 }
  )
end)

test("an anchor whose last line changed grows to the replacement", function()
  local thread = thread_at(1, 0, 2, 1)
  local entry = { snapshot = { "a", "b", "c", "d" }, threads = { thread } }
  store.remap(entry, { "a", "b", "C1", "C2", "d" })
  h.eq(
    thread.anchor,
    { start_row = 1, start_col = 0, end_row = 3, end_col = 2 }
  )
  h.eq(thread.outdated, nil)
end)

test("an anchor whose lines were all replaced is outdated", function()
  local thread = thread_at(1, 0, 1, 1)
  local entry = { snapshot = { "a", "b", "c" }, threads = { thread } }
  store.remap(entry, { "a", "B1", "B2", "c" })
  h.eq(
    thread.anchor,
    { start_row = 1, start_col = 0, end_row = 2, end_col = 2 }
  )
  h.eq(thread.outdated, true)
end)

test("an anchor whose lines were deleted shrinks to the next line", function()
  local thread = thread_at(1, 0, 2, 1)
  local entry = { snapshot = { "a", "b", "c", "d" }, threads = { thread } }
  store.remap(entry, { "a", "d" })
  h.eq(
    thread.anchor,
    { start_row = 1, start_col = 0, end_row = 1, end_col = 0 }
  )
  h.eq(thread.outdated, true)
end)

test("the snapshot becomes the new lines", function()
  local entry = { snapshot = { "a" }, threads = { thread_at(0, 0, 0, 1) } }
  store.remap(entry, { "x", "a" })
  h.eq(entry.snapshot, { "x", "a" })
end)

test("changes are saved without the threads that have no comments", function()
  local dir = assert(
    vim.uv.fs_mkdtemp(
      vim.fs.joinpath(assert(vim.uv.os_tmpdir()), "repo-XXXXXX")
    )
  )
  local entry = store.entry(dir, "abc", "f.txt", { "a" })
  local commented = thread_at(0, 0, 0, 1)
  commented.comments = { { author = "me", body = "hi", time = 0 } }
  entry.threads = { commented, thread_at(0, 0, 0, 0) }
  store.save(dir, "abc")

  local saved = vim.json.decode(
    assert(h.read(vim.fs.joinpath(dir, "nvim-threads", "abc.json")))
  )
  h.eq(#saved.files["f.txt"].threads, 1)
  h.eq(saved.files["f.txt"].threads[1].comments[1].body, "hi")

  entry.threads = {}
  store.save(dir, "abc")
  h.eq(h.read(vim.fs.joinpath(dir, "nvim-threads", "abc.json")), nil)
end)

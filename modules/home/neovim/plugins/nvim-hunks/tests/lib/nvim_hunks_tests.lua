local M = {}

--- The diff's highlights, the distinct backgrounds the tests give them, and
--- the letters standing for them in the dumps of the screen. Every other cell
--- is a `.`.
local categories = {
  { "HunksAdd", 0x00a000, "a" },
  { "HunksAddText", 0x00a001, "A" },
  { "HunksAddNr", 0x00a002, "g" },
  { "HunksDelete", 0x00d000, "d" },
  { "HunksDeleteText", 0x00d001, "D" },
  { "HunksDeleteNr", 0x00d002, "h" },
  { "ColorColumn", 0x00c000, "c" },
}

---@param actual any
---@param expected any
---@param message? string
M.eq = function(actual, expected, message)
  if vim.deep_equal(actual, expected) then return end
  local show = function(value)
    return type(value) == "string" and value or vim.inspect(value)
  end
  error(
    ("%s\n--- expected\n%s\n--- actual\n%s"):format(
      message or "values differ",
      show(expected),
      show(actual)
    ),
    2
  )
end

--- Waits until the condition holds, failing if it doesn't within the time.
---@param condition fun(): boolean?
---@param message string
---@param timeout_ms? integer
M.wait = function(condition, message, timeout_ms)
  if not vim.wait(timeout_ms or 5000, condition, 10) then
    error("timed out waiting until " .. message, 2)
  end
end

--- Runs a command in a directory, failing if it does.
---@param dir string
---@param cmd string[]
---@return string stdout
M.run = function(dir, cmd)
  local result = vim.system(cmd, { cwd = dir, text = true }):wait()
  if result.code ~= 0 then
    error(("`%s` failed:\n%s"):format(table.concat(cmd, " "), result.stderr), 2)
  end
  return result.stdout or ""
end

---@param path string
---@param text string
local write = function(path, text)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local file = assert(io.open(path, "wb"))
  file:write(text)
  file:close()
end

--- Creates a jj repo whose working-copy commit turns the base files into the
--- new ones, and returns its root. A file missing from the new ones is
--- deleted, and one that's `false` there is left untouched.
---@param base table<string, string>
---@param new table<string, string|false>
---@return string
M.repo = function(base, new)
  local root = vim.fs.normalize(
    assert(
      vim.uv.fs_mkdtemp(
        vim.fs.joinpath(assert(vim.uv.os_tmpdir()), "nvim-hunks-XXXXXX")
      )
    )
  )
  root = assert(vim.uv.fs_realpath(root))
  M.run(root, { "jj", "git", "init", "--quiet" })
  for path, text in pairs(base) do
    write(vim.fs.joinpath(root, path), text)
  end
  M.run(root, { "jj", "commit", "--quiet", "--message", "base" })
  for path in pairs(base) do
    if new[path] == nil then os.remove(vim.fs.joinpath(root, path)) end
  end
  for path, text in pairs(new) do
    if text then write(vim.fs.joinpath(root, path), text) end
  end
  return root
end

--- Returns a file's contents at a revision of a repo, or nothing if it
--- doesn't exist there.
---@param root string
---@param rev string
---@param path string
---@return string?
M.file_at = function(root, rev, path)
  local cmd = {
    "jj",
    "file",
    "show",
    "--revision",
    rev,
    "--",
    ("root-file:%q"):format(path),
  }
  local result = vim.system(cmd, { cwd = root, text = true }):wait()
  return result.code == 0 and result.stdout or nil
end

--- Sets up nvim-hunks in a screen of the given size, with the diff's
--- highlights given the colors the dumps of the screen recognize.
---@param columns integer
---@param lines integer
M.setup = function(columns, lines)
  vim.o.termguicolors = true
  vim.o.columns = columns
  vim.o.lines = lines
  vim.o.swapfile = false
  vim.o.shada = ""
  require("nvim_hunks").setup({ library = vim.env.LIBVSCODE_DIFF })
  vim.api.nvim_set_hl(0, "Normal", { bg = 0x000000, fg = 0xffffff })
  for _, category in ipairs(categories) do
    vim.api.nvim_set_hl(0, category[1], { bg = category[2] })
  end
end

--- Returns the IDs of the screen's attributes standing for the categories'
--- letters. A category's highlight gives cells the same attributes whether
--- it's alone or under the `NonText` of 'listchars' and 'showbreak', which
--- only changes their foreground. The reference cells are drawn in another
--- tab page, since floats aren't part of the headless screen.
---@return table<integer, string>
local attr_letters = function()
  local chunks = {}
  for _, category in ipairs(categories) do
    chunks[#chunks + 1] = { "x", category[1] }
    chunks[#chunks + 1] = { "x", { "NonText", category[1] } }
  end

  local tab = vim.api.nvim_get_current_tabpage()
  vim.cmd("noautocmd tabnew")
  -- The new window copies the options of the one the tab page opened from.
  vim.cmd("setlocal nonumber norelativenumber nolist nocursorline")
  vim.cmd("setlocal signcolumn=no foldcolumn=0 colorcolumn= statuscolumn=")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { (" "):rep(#chunks) })
  local namespace = vim.api.nvim_create_namespace("nvim-hunks-tests")
  vim.api.nvim_buf_set_extmark(buf, namespace, 0, 0, {
    virt_text = chunks,
    virt_text_pos = "overlay",
  })
  vim.cmd.redraw()

  -- The tab line takes the first row.
  local letters = {}
  for idx, category in ipairs(categories) do
    letters[vim.fn.screenattr(2, 2 * idx - 1)] = category[3]
    letters[vim.fn.screenattr(2, 2 * idx)] = category[3]
  end
  vim.cmd("noautocmd tabclose!")
  vim.api.nvim_set_current_tabpage(tab)
  vim.cmd.redraw()
  return letters
end

--- Returns the given rows of the screen, each as its text followed by the
--- categories of its cells' highlights.
---@param first integer The 1-based first row.
---@param last integer The 1-based last row.
---@return string
M.screen = function(first, last)
  local letters = attr_letters()
  local rows = {}
  for row = first, last do
    local text, highlights = {}, {}
    for col = 1, vim.o.columns do
      text[#text + 1] = vim.fn.screenstring(row, col)
      highlights[#highlights + 1] = letters[vim.fn.screenattr(row, col)] or "."
    end
    -- The text's trailing spaces are left out, their highlights aren't.
    rows[#rows + 1] = (table.concat(text):gsub("%s+$", ""))
    rows[#rows + 1] = table.concat(highlights)
  end
  return table.concat(rows, "\n")
end

return M

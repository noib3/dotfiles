local M = {}

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

--- Returns a template's output for each revision of a revset, without
--- snapshotting the working copy.
---@param root string
---@param revset string
---@param template string
---@return string[]
M.query = function(root, revset, template)
  local stdout = M.run(root, {
    "jj",
    "--ignore-working-copy",
    "log",
    "--no-graph",
    "--revisions",
    revset,
    "--template",
    template .. ' ++ "\\n"',
  })
  return vim.split(vim.trim(stdout), "\n", { trimempty = true })
end

--- Creates a temporary directory and returns its path.
---@return string
local tempdir = function()
  local dir = assert(
    vim.uv.fs_mkdtemp(
      vim.fs.joinpath(assert(vim.uv.os_tmpdir()), "nvim-jj-XXXXXX")
    )
  )
  return (assert(vim.uv.fs_realpath(dir)))
end

--- Creates a jj repo with a bare git repo as its `origin` remote, and returns
--- its root. Each of the given descriptions becomes a change on top of the
--- previous one, the first one on top of the root, and the working-copy
--- commit is an empty change on top of the last one. The change with the
--- `pushed` index is pushed as the remote's `main` bookmark.
---@param descriptions string[]
---@param pushed? integer
---@return string
M.repo = function(descriptions, pushed)
  local dir = tempdir()
  M.run(dir, { "git", "init", "--quiet", "--bare", "remote.git" })
  M.run(dir, { "jj", "git", "init", "--quiet", "repo" })

  local root = vim.fs.joinpath(dir, "repo")
  M.run(root, { "jj", "git", "remote", "add", "origin", "../remote.git" })
  for i, description in ipairs(descriptions) do
    local file = assert(io.open(vim.fs.joinpath(root, "f" .. i), "w"))
    file:write(description .. "\n")
    file:close()
    M.run(root, { "jj", "commit", "--quiet", "--message", description })
  end

  if pushed then
    local rev = ("@%s"):format(("-"):rep(#descriptions - pushed + 1))
    M.run(root, { "jj", "bookmark", "create", "--quiet", "main", "-r", rev })
    M.run(root, { "jj", "git", "push", "--quiet", "--bookmark", "main" })
  end
  return root
end

--- The messages notified so far, as `level: message`.
---@type string[]
M.messages = {}

--- Captures the notified messages, and sets up nvim-jj.
---@param opts? table The options of nvim-jj's setup.
M.setup = function(opts)
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.notify = function(message, level)
    local name = ({
      [vim.log.levels.ERROR] = "error",
      [vim.log.levels.WARN] = "warn",
      [vim.log.levels.INFO] = "info",
    })[level] or "other"
    M.messages[#M.messages + 1] = ("%s: %s"):format(name, message)
  end
  require("nvim_jj").setup(opts)
end

--- Opens the log of a repo below the only window, and waits until it's
--- drawn.
---@param root string
---@return integer bufnr
M.open = function(root)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= vim.api.nvim_get_current_win() then
      vim.api.nvim_win_close(win, true)
    end
  end
  require("nvim_jj").toggle(root)
  local bufnr = vim.api.nvim_get_current_buf()
  local namespace = vim.api.nvim_create_namespace("nvim-jj")
  M.wait(
    function()
      return #vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {}) > 0
    end,
    "the log is drawn"
  )
  M.settle()
  return bufnr
end

--- Waits for the redraws triggered by jj operations to finish.
M.settle = function() vim.wait(400) end

--- Returns the line of a log buffer whose text is the given subject.
---@param bufnr integer
---@param subject string
---@return integer
M.row = function(bufnr, subject)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for row, line in ipairs(lines) do
    if vim.trim(line) == subject then return row end
  end
  error(("no line is %q"):format(subject), 2)
end

--- Returns the lines of a log buffer, each with the decorations before and
--- after its text, followed by the virtual lines below it. The change IDs
--- and timestamps vary between runs, so they're left out.
---@param bufnr integer
---@return string[]
M.screen = function(bufnr)
  local namespace = vim.api.nvim_create_namespace("nvim-jj")
  local texts = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local marks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    namespace,
    0,
    -1,
    { details = true }
  )

  ---@type table<integer, { before: string, after: string, below: string[] }>
  local decorations = {}
  for row = 1, #texts do
    decorations[row] = { before = "", after = "", below = {} }
  end
  for _, mark in ipairs(marks) do
    local decoration, details = decorations[mark[2] + 1], assert(mark[4])
    local text = ""
    for _, chunk in ipairs(details.virt_text or {}) do
      if chunk[2] == "JjChangeId" then
        text = text .. "<id>"
      elseif chunk[2] == "JjChangeIdRest" then
        text = text .. (chunk[1]:gsub("%S", ""))
      else
        text = text .. chunk[1]
      end
    end
    if details.virt_text_pos == "inline" then
      decoration.before = text
    elseif
      details.virt_text_pos == "eol" or details.virt_text_pos == "overlay"
    then
      decoration.after = text
    end
    for _, line in ipairs(details.virt_lines or {}) do
      local below = ""
      for _, chunk in ipairs(line) do
        below = below .. (chunk[2] == "JjTimestamp" and "<date>" or chunk[1])
      end
      table.insert(decoration.below, vim.trim(below))
    end
  end

  local lines = {}
  for row, text in ipairs(texts) do
    local decoration = decorations[row]
    local parts = vim.tbl_filter(
      function(part) return part ~= "" end,
      { vim.trim(decoration.before), vim.trim(text), vim.trim(decoration.after) }
    )
    lines[#lines + 1] = table.concat(parts, " ")
    vim.list_extend(lines, decoration.below)
  end
  return lines
end

--- Returns the status drawn after the change on a subject's line of a log
--- buffer, as `<kind>: <text>`, or nothing if there's none.
---@param bufnr integer
---@param subject string
---@return string?
M.status = function(bufnr, subject)
  local namespace = vim.api.nvim_create_namespace("nvim-jj")
  local line = M.row(bufnr, subject) - 1
  local marks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    namespace,
    { line, 0 },
    { line, -1 },
    { details = true }
  )
  for _, mark in ipairs(marks) do
    for _, chunk in ipairs(assert(mark[4]).virt_text or {}) do
      local kind = type(chunk[2]) == "string" and chunk[2]:match("^JjStatus(%a+)$")
      if kind then
        local text = vim.trim(chunk[1]):gsub("^%S+%s+", "")
        return ("%s: %s"):format(kind:lower(), text)
      end
    end
  end
end

--- Creates a jj repo whose working-copy commit is on top of a linear history
--- of empty commits, and returns its root.
---@param count integer The number of commits.
---@return string
M.long_repo = function(count)
  local root = tempdir()
  M.run(root, { "git", "init", "--quiet", "--initial-branch", "main" })

  local stream = {}
  for i = 1, count do
    local message = ("commit %d"):format(i)
    vim.list_extend(stream, {
      "commit refs/heads/main",
      ("mark :%d"):format(i),
      ("committer T <t@example.com> %d +0000"):format(1700000000 + i),
      ("data %d"):format(#message),
      message,
    })
    if i > 1 then stream[#stream + 1] = ("from :%d"):format(i - 1) end
    stream[#stream + 1] = ""
  end
  local result = vim
    .system({ "git", "fast-import", "--quiet" }, {
      cwd = root,
      stdin = table.concat(stream, "\n"),
    })
    :wait()
  assert(result.code == 0, result.stderr)

  M.run(root, { "jj", "git", "init", "--quiet", "--colocate" })
  return root
end

return M

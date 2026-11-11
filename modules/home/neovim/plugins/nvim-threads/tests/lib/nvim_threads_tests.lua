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

---@param path string
---@param text string
M.write = function(path, text)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local file = assert(io.open(path, "wb"))
  file:write(text)
  file:close()
end

---@param path string
---@return string?
M.read = function(path)
  local file = io.open(path, "rb")
  if not file then return end
  local text = file:read("*a")
  file:close()
  return text
end

---@param lines string[]
---@return string
M.text = function(lines) return table.concat(lines, "\n") .. "\n" end

--- Creates a jj repo whose working-copy commit turns the base files into the
--- new ones, and returns its root.
---@param base table<string, string>
---@param new table<string, string>
---@return string
M.repo = function(base, new)
  local root = vim.fs.normalize(
    assert(
      vim.uv.fs_mkdtemp(
        vim.fs.joinpath(assert(vim.uv.os_tmpdir()), "nvim-threads-XXXXXX")
      )
    )
  )
  root = assert(vim.uv.fs_realpath(root))
  M.run(root, { "jj", "git", "init", "--quiet" })
  for path, text in pairs(base) do
    M.write(vim.fs.joinpath(root, path), text)
  end
  M.run(root, { "jj", "commit", "--quiet", "--message", "base" })
  for path, text in pairs(new) do
    M.write(vim.fs.joinpath(root, path), text)
  end
  return root
end

--- Returns the change ID of a revision of a repo.
---@param root string
---@param rev string
---@return string
M.change_id = function(root, rev)
  return vim.trim(
    M.run(root, { "jj", "log", "--no-graph", "-r", rev, "-T", "change_id" })
  )
end

--- Returns the threads saved for a change, keyed by file.
---@param root string
---@param change_id string
---@return table<string, { snapshot: string[], threads: nvim_threads.Thread[] }?>
M.saved = function(root, change_id)
  local text = M.read(
    vim.fs.joinpath(root, ".jj", "repo", "nvim-threads", change_id .. ".json")
  )
  if not text then return {} end
  return vim.json.decode(text).files
end

--- Sets up nvim-threads in a screen of the given size.
---@param columns integer
---@param lines integer
---@param opts? table
M.setup = function(columns, lines, opts)
  vim.o.columns = columns
  vim.o.lines = lines
  vim.o.swapfile = false
  vim.o.shada = ""
  require("nvim_threads").setup(opts)
end

--- Opens a file of a repo in the current window, and waits until its
--- threads are loaded.
---@param root string
---@param path string
---@return integer
M.open = function(root, path)
  vim.cmd.edit(vim.fs.joinpath(root, path))
  local bufnr = vim.api.nvim_get_current_buf()
  M.wait(
    function() return require("nvim_threads").is_attached(bufnr) end,
    "the buffer is attached"
  )
  -- The working copy's change ID is resolved in the background, before the
  -- threads are listed.
  local resolved = false
  require("nvim_threads").list(root, function() resolved = true end)
  M.wait(function() return resolved end, "the working copy is resolved")
  return bufnr
end

--- Returns the text of the virtual lines of a buffer's threads, by the
--- 1-based line they follow, without their right borders.
---@param bufnr integer
---@return table<integer, string[]>
M.virt_lines = function(bufnr)
  local namespace = require("nvim_threads.render").namespace
  local result = {}
  for _, mark in
    ipairs(
      vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, { details = true })
    )
  do
    local details = mark[4] or {}
    if details.virt_lines then
      local lines = result[mark[2] + 1] or {}
      for _, chunks in ipairs(details.virt_lines) do
        local text = vim.trim(
          table.concat(vim.tbl_map(function(chunk) return chunk[1] end, chunks))
        )
        -- The right border of a message's rows follows their padding.
        lines[#lines + 1] = vim.trim((text:gsub("🮇$", "")))
      end
      result[mark[2] + 1] = lines
    end
  end
  return result
end

--- Types text into the current float's composer, as if it was typed in
--- insert mode, and fires the buffer's change.
---@param lines string[]
M.type = function(lines)
  local buf = vim.api.nvim_get_current_buf()
  local line_count = vim.api.nvim_buf_line_count(buf)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, line_count - 1, line_count, false, lines)
  -- The composer's change is handled on the next loop iteration.
  vim.wait(20)
end

--- Moves the cursor from the current thread's float back to the line its
--- virtual lines follow.
M.leave = function()
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  assert(require("nvim_threads").step(-1, "k"), "the cursor isn't in a float")
end

--- A participant replying to every comment with the given chunks, streamed
--- in on the next loop iterations, then with the given result.
---@param name string
---@param chunks string[]
---@param result? nvim_threads.Result
---@return nvim_threads.Participant participant
---@return nvim_threads.Request[] requests The requests it got.
M.participant = function(name, chunks, result)
  local requests = {}
  return {
    name = name,
    send = function(request, reply)
      requests[#requests + 1] = request
      local index = 0
      local timer = assert(vim.uv.new_timer())
      timer:start(10, 10, function()
        index = index + 1
        if index <= #chunks then
          reply.chunk(chunks[index])
          return
        end
        timer:close()
        reply.done(result)
      end)
      return function() pcall(timer.close, timer) end
    end,
  },
    requests
end

return M

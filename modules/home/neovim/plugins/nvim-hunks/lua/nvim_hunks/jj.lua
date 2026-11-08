local M = {}

--- Returns a fileset matching exactly the given path, relative to the repo's
--- root.
---@param path string
---@return string
local root_file = function(path)
  return ('root-file:"%s"'):format(path:gsub('[\\"]', "\\%0"))
end

---@param text string
---@return string
local toml_string = function(text)
  return ('"%s"'):format(text:gsub('[\\"]', "\\%0"))
end

---@param root string
---@param args string[]
---@param on_exit fun(result: vim.SystemCompleted)
local run = function(root, args, on_exit)
  local cmd = { "jj", "--color", "never", "--no-pager" }
  vim.list_extend(cmd, args)
  vim.system(cmd, { cwd = root, text = true }, on_exit)
end

--- Returns the root of the jj workspace containing the given path.
---@param path string
---@return string?
M.root = function(path)
  local root = vim.fs.root(path, ".jj")
  return root and vim.fs.normalize(root)
end

--- Returns the directory holding the op heads of the repo backing the given
--- workspace. A secondary workspace's `.jj/repo` is a file containing the
--- path of the main workspace's `.jj/repo` directory.
---@param root string
---@return string
M.op_heads_dir = function(root)
  local dot_jj = vim.fs.joinpath(root, ".jj")
  local repo = vim.fs.joinpath(dot_jj, "repo")

  local stat = vim.uv.fs_stat(repo)
  if stat and stat.type == "file" then
    local file = io.open(repo, "r")
    if file then
      local target = vim.trim(file:read("*a"))
      file:close()
      if not vim.startswith(target, "/") then
        target = vim.fs.joinpath(dot_jj, target)
      end
      repo = vim.fs.normalize(target)
    end
  end

  return vim.fs.joinpath(repo, "op_heads", "heads")
end

--- Reads a file's contents at a revision, without snapshotting the working
--- copy. The callback gets no text and no error when the file doesn't exist
--- at that revision.
---@param root string
---@param rev string
---@param path string The file's path relative to the root.
---@param on_done fun(err?: string, text?: string)
M.file_at = function(root, rev, path, on_done)
  local args = {
    "--ignore-working-copy",
    "file",
    "show",
    "--revision",
    rev,
    "--",
    root_file(path),
  }

  run(root, args, function(result)
    if result.code == 0 then
      on_done(nil, result.stdout or "")
    elseif (result.stderr or ""):find("No such path", 1, true) then
      on_done()
    else
      on_done(vim.trim(result.stderr or ""))
    end
  end)
end

--- Returns the change IDs of the revisions in a revset, without snapshotting
--- the working copy.
---@param root string
---@param revset string
---@param on_done fun(err?: string, change_ids?: string[])
M.resolve = function(root, revset, on_done)
  local args = {
    "--ignore-working-copy",
    "log",
    "--no-graph",
    "--revisions",
    revset,
    "--template",
    'change_id ++ "\\n"',
  }

  run(root, args, function(result)
    if result.code == 0 then
      local ids = vim.split(vim.trim(result.stdout or ""), "\n")
      on_done(nil, vim.tbl_filter(function(id) return id ~= "" end, ids))
    else
      on_done(vim.trim(result.stderr or ""))
    end
  end)
end

--- Moves part of the working-copy commit's changes to a file into another
--- revision. The part moved is what turns the file's contents in the
--- working-copy commit's parent into the given text.
---@param root string
---@param into string
---@param path string The file's path relative to the root.
---@param text string
---@param on_done fun(err?: string)
M.squash_file = function(root, into, path, text, on_done)
  local text_path = vim.fn.tempname()
  local file = assert(io.open(text_path, "wb"))
  file:write(text)
  file:close()

  local args = {
    "squash",
    "--from",
    "@",
    "--into",
    into,
    "--use-destination-message",
    "--tool",
    "nvim-hunks",
    "--config",
    'merge-tools.nvim-hunks.program="cp"',
    "--config",
    ("merge-tools.nvim-hunks.edit-args=[%s, %s]"):format(
      toml_string(text_path),
      toml_string("$right/" .. path)
    ),
    "--",
    root_file(path),
  }

  run(root, args, function(result)
    os.remove(text_path)
    if result.code == 0 then
      on_done()
    else
      on_done(vim.trim(result.stderr or ""))
    end
  end)
end

--- Returns whether a file is tracked in the working-copy commit, after
--- snapshotting the working copy.
---@param root string
---@param path string The file's path relative to the root.
---@param on_done fun(err?: string, tracked?: boolean)
M.is_tracked = function(root, path, on_done)
  local args = { "file", "list", "--revision", "@", "--", root_file(path) }

  run(root, args, function(result)
    if result.code == 0 then
      on_done(nil, vim.trim(result.stdout or "") ~= "")
    else
      on_done(vim.trim(result.stderr or ""))
    end
  end)
end

return M

local M = {}

---@param root string
---@param args string[]
---@param on_exit fun(result: vim.SystemCompleted)
local run = function(root, args, on_exit)
  local cmd = { "jj", "--color", "never", "--no-pager" }
  vim.list_extend(cmd, args)
  vim.system(cmd, { cwd = root, text = true }, on_exit)
end

---@param result vim.SystemCompleted
---@return string
local error_of = function(result)
  local stderr = vim.trim(result.stderr or "")
  return stderr ~= "" and stderr
    or ("jj exited with code %d"):format(result.code)
end

--- Returns the root of the jj workspace containing the given path.
---@param path string
---@return string?
M.root = function(path)
  local root = vim.fs.root(path, ".jj")
  return root and vim.fs.normalize(root)
end

--- Returns the `.jj/repo` directory of the repo backing the given workspace.
--- A secondary workspace's `.jj/repo` is a file containing the path of the
--- main workspace's `.jj/repo` directory.
---@param root string
---@return string
M.repo_dir = function(root)
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

  return repo
end

--- Returns the directory holding the op heads of the repo backing the given
--- workspace.
---@param root string
---@return string
M.op_heads_dir = function(root)
  return vim.fs.joinpath(M.repo_dir(root), "op_heads", "heads")
end

--- Calls back with the change IDs of the revisions a revset resolves to,
--- each with a one-line label.
---@param root string
---@param revset string
---@param on_done fun(err?: string, changes?: { change_id: string, label: string }[])
M.resolve = function(root, revset, on_done)
  local template =
    'change_id ++ "\\t" ++ change_id.shortest(8) ++ " " ++ description.first_line() ++ "\\n"'
  run(
    root,
    { "log", "--no-graph", "-r", revset, "-T", template },
    function(result)
      if result.code ~= 0 then return on_done(error_of(result)) end
      local changes = {}
      for line in vim.gsplit(result.stdout or "", "\n", { trimempty = true }) do
        local change_id, label = line:match("^(%S+)\t(.*)$")
        if change_id and label then
          changes[#changes + 1] =
            { change_id = change_id, label = vim.trim(label) }
        end
      end
      on_done(nil, changes)
    end
  )
end

--- Calls back with the change ID of the workspace's working-copy commit.
---@param root string
---@param on_done fun(err?: string, change_id?: string)
M.working_copy = function(root, on_done)
  M.resolve(root, "@", function(err, changes)
    if err then return on_done(err) end
    local change = changes and changes[1]
    if not change then return on_done("`@` doesn't resolve to a change") end
    on_done(nil, change.change_id)
  end)
end

--- Calls back with the git-style diff of a file in the working-copy commit,
--- against its parents.
---@param root string
---@param path string The file's path relative to the root.
---@param on_done fun(err?: string, diff?: string)
M.diff = function(root, path, on_done)
  local fileset = ('root-file:"%s"'):format(path:gsub('[\\"]', "\\%0"))
  run(root, { "diff", "--git", "-r", "@", "--", fileset }, function(result)
    if result.code ~= 0 then return on_done(error_of(result)) end
    on_done(nil, result.stdout or "")
  end)
end

return M

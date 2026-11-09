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

---@class nvim_hunks.Id
---@field prefix string The shortest prefix identifying the revision.
---@field rest string The rest of the first 8 characters.

---@class nvim_hunks.Revision
---@field change_id nvim_hunks.Id
---@field commit_id nvim_hunks.Id
---@field bookmarks string[]
---@field description string The first line of the description.

--- Describes a single revision, without snapshotting the working copy.
---@param root string
---@param rev string
---@param on_done fun(err?: string, revision?: nvim_hunks.Revision)
M.describe = function(root, rev, on_done)
  local args = {
    "--ignore-working-copy",
    "log",
    "--no-graph",
    "--revisions",
    rev,
    "--template",
    table.concat({
      "change_id.shortest(8).prefix()",
      "change_id.shortest(8).rest()",
      "commit_id.shortest(8).prefix()",
      "commit_id.shortest(8).rest()",
      'bookmarks.join(" ")',
      "description.first_line()",
    }, ' ++ "\\t" ++ '),
  }

  run(root, args, function(result)
    if result.code ~= 0 then return on_done(vim.trim(result.stderr or "")) end
    local fields = vim.split(result.stdout or "", "\t", { plain = true })
    on_done(nil, {
      change_id = { prefix = fields[1] or "", rest = fields[2] or "" },
      commit_id = { prefix = fields[3] or "", rest = fields[4] or "" },
      bookmarks = vim.split(fields[5] or "", " ", { trimempty = true }),
      description = vim.trim(fields[6] or ""),
    })
  end)
end

--- Returns the outcome of a command that only reports errors.
---@param on_done fun(err?: string)
---@return fun(result: vim.SystemCompleted)
local on_success = function(on_done)
  return function(result)
    if result.code == 0 then
      on_done()
    else
      on_done(vim.trim(result.stderr or ""))
    end
  end
end

--- Moves part of the working-copy commit's changes to a file into another
--- revision. The part moved is what turns the file's contents in the
--- working-copy commit's parent into the given text. The changes to the
--- other given paths are moved in full, e.g. the deletion of a renamed
--- file's old path.
---@param root string
---@param into string
---@param path string The file's path relative to the root.
---@param text string
---@param other_paths string[]
---@param on_done fun(err?: string)
M.squash_file = function(root, into, path, text, other_paths, on_done)
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
  for _, other_path in ipairs(other_paths) do
    args[#args + 1] = root_file(other_path)
  end

  run(root, args, function(result)
    os.remove(text_path)
    on_success(on_done)(result)
  end)
end

--- Moves all of the working-copy commit's changes to the given files into
--- another revision.
---@param root string
---@param into string
---@param paths string[] The files' paths relative to the root.
---@param on_done fun(err?: string)
M.squash_paths = function(root, into, paths, on_done)
  local args = {
    "squash",
    "--from",
    "@",
    "--into",
    into,
    "--use-destination-message",
    "--",
  }
  for _, path in ipairs(paths) do
    args[#args + 1] = root_file(path)
  end
  run(root, args, on_success(on_done))
end

---@alias nvim_hunks.Status "added"|"removed"|"modified"|"renamed"|"copied"

---@class nvim_hunks.ChangedFile
---@field status nvim_hunks.Status
---@field source string The file's path in the base revision, relative to the root.
---@field target string The file's path in the working-copy commit, relative to the root.

--- Returns the files changed between a revision and the working-copy commit,
--- after snapshotting the working copy.
---@param root string
---@param from string
---@param on_done fun(err?: string, files?: nvim_hunks.ChangedFile[])
M.changed_files = function(root, from, on_done)
  local args = {
    "diff",
    "--from",
    from,
    "--to",
    "@",
    "--template",
    'status ++ "\t" ++ source.path() ++ "\t" ++ target.path() ++ "\n"',
  }

  run(root, args, function(result)
    if result.code ~= 0 then return on_done(vim.trim(result.stderr or "")) end

    ---@type nvim_hunks.ChangedFile[]
    local files = {}
    for line in (result.stdout or ""):gmatch("[^\n]+") do
      local status, source, target = line:match("^([^\t]+)\t([^\t]+)\t(.+)$")
      if status and source and target then
        files[#files + 1] = {
          status = status --[[@as nvim_hunks.Status]],
          source = source,
          target = target,
        }
      end
    end
    on_done(nil, files)
  end)
end

return M

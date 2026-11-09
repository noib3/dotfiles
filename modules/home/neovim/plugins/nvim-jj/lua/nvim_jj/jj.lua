local M = {}

--- The separator between a log line's graph and its change's fields, and
--- its escape in a template's string literal.
local record_start, record_start_escape = "\30", "\\x1e"

--- The separator between a log line's graph and one of its change's details,
--- and its escape in a template's string literal.
local details_start, details_start_escape = "\29", "\\x1d"

--- The separator between the fields of a change in a log line, and its
--- escape in a template's string literal.
local field_separator, field_separator_escape = "\31", "\\x1f"

---@param root string
---@param args string[]
---@param on_exit fun(result: vim.SystemCompleted)
---@param stdin? string
local run = function(root, args, on_exit, stdin)
  local cmd = { "jj", "--color", "never", "--no-pager" }
  vim.list_extend(cmd, args)
  vim.system(
    cmd,
    { cwd = root, text = true, stdin = stdin },
    vim.schedule_wrap(on_exit)
  )
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

--- Returns a revset string literal.
---@param text string
---@return string
M.quote = function(text) return ('"%s"'):format(text:gsub('[\\"]', "\\%0")) end

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

---@class nvim_jj.Change
---@field id string The full change ID.
---@field prefix string The shortest prefix identifying the change.
---@field rest string The rest of the change ID's first 8 characters.
---@field bookmarks string[] The bookmarks, marked as jj marks them when they differ from their remotes.
---@field local_bookmarks string[] The names of the local bookmarks.
---@field subject string The first line of the description.
---@field conflict boolean
---@field divergent boolean
---@field empty boolean
---@field immutable boolean
---@field working_copy boolean Whether the change is the workspace's working-copy commit.
---@field commit_id string The full ID of the change's commit.

---@class nvim_jj.Detail
---@field kind "timestamp"|"authors"
---@field text string The committer's timestamp with its UTC offset, or the author and co-authors.

---@class nvim_jj.LogLine
---@field graph string The text drawn by jj's graph, including the node of a change.
---@field change? nvim_jj.Change The change whose node is on the line.
---@field detail? nvim_jj.Detail A detail of the closest change above the line.

--- The template of a change's fields, in the order `parse_change` reads them.
local change_template = table.concat({
  "change_id",
  "change_id.shortest(8).prefix()",
  "change_id.shortest(8).rest()",
  'bookmarks.join(" ")',
  'if(conflict, "1")',
  'if(divergent, "1")',
  'if(empty, "1")',
  'if(immutable, "1")',
  'if(current_working_copy, "1")',
  'local_bookmarks.map(|b| b.name()).join(" ")',
  "description.first_line()",
  "commit_id",
}, (' ++ "%s" ++ '):format(field_separator_escape))

---@param fields string
---@return nvim_jj.Change
local parse_change = function(fields)
  local f = vim.split(fields, field_separator, { plain = true })
  return {
    id = f[1] or "",
    prefix = f[2] or "",
    rest = f[3] or "",
    bookmarks = vim.split(f[4] or "", " ", { trimempty = true }),
    conflict = f[5] == "1",
    divergent = f[6] == "1",
    empty = f[7] == "1",
    immutable = f[8] == "1",
    working_copy = f[9] == "1",
    local_bookmarks = vim.split(f[10] or "", " ", { trimempty = true }),
    subject = f[11] or "",
    commit_id = f[12] or "",
  }
end

--- The template of the lines of a change's details, each starting with the
--- tag of its kind. The authors are the author followed by the co-authors of
--- the description's trailers. The root has none.
local details_template = ("if(!root, %s)"):format(table.concat({
  ('"%st"'):format(details_start_escape),
  'committer.timestamp().format("%Y-%m-%d %H:%M:%S %:z")',
  ('"\\n%sa"'):format(details_start_escape),
  'if(author.name(), author.name() ++ " <" ++ author.email() ++ ">", author.email())',
  [[trailers.filter(|t| t.key().lower() == "co-authored-by").map(|t| ", " ++ t.value()).join("")]],
  '"\\n"',
}, " ++ "))

---@type table<string, "timestamp"|"authors">
local detail_kinds = { t = "timestamp", a = "authors" }

--- Replaces the `+HH:MM` offset at the end of a timestamp with `UTC+H`, or
--- `UTC+H:MM` for an offset with minutes, and a zero offset with `UTC`.
---@param timestamp string
---@return string
local with_utc_offset = function(timestamp)
  local time, sign, hours, minutes =
    timestamp:match("^(.-) ([+-])(%d%d):(%d%d)$")
  if not time then return timestamp end
  if hours == "00" and minutes == "00" then return time .. " UTC" end
  local offset = tostring(tonumber(hours))
  if minutes ~= "00" then offset = offset .. ":" .. minutes end
  return ("%s UTC%s%s"):format(time, sign, offset)
end

---@param text string
---@return nvim_jj.LogLine
local parse_log_line = function(text)
  local start = text:find(record_start, 1, true)
  if start then
    return {
      graph = text:sub(1, start - 1),
      change = parse_change(text:sub(start + #record_start)),
    }
  end

  start = text:find(details_start, 1, true)
  local kind = start and detail_kinds[text:sub(start + 1, start + 1)]
  if not start or not kind then return { graph = text } end
  local detail = text:sub(start + 2)
  if kind == "timestamp" then detail = with_utc_offset(detail) end
  return {
    graph = text:sub(1, start - 1),
    detail = { kind = kind, text = detail },
  }
end

---@class nvim_jj.LogStream
---@field pause fun() Stops reading jj's output, which blocks jj once the pipe is full.
---@field resume fun()
---@field kill fun() Stops jj, after which no callback is called.

--- Streams the lines of jj's log of a revset: one per change, followed by
--- one per detail of it, and one per line of the graph between changes. The
--- working copy is only snapshotted when asked to.
---@param root string
---@param revset string
---@param snapshot boolean
---@param on_lines fun(lines: nvim_jj.LogLine[])
---@param on_exit fun(err?: string)
---@return nvim_jj.LogStream
M.log = function(root, revset, snapshot, on_lines, on_exit)
  local args = {
    "--color",
    "never",
    "--no-pager",
    "log",
    "--revisions",
    revset,
    "--template",
    ('"%s" ++ %s ++ "\\n" ++ %s'):format(
      record_start_escape,
      change_template,
      details_template
    ),
  }
  if not snapshot then table.insert(args, 1, "--ignore-working-copy") end

  local uv = vim.uv
  local stdout = assert(uv.new_pipe())
  local stderr = assert(uv.new_pipe())
  local killed, reading = false, true
  local partial, errors = "", {}
  ---@type integer?
  local code
  local stdout_done, stderr_done = false, false
  ---@type uv.uv_process_t?
  local handle

  local close = function()
    for _, pipe in ipairs({ stdout, stderr }) do
      if not pipe:is_closing() then pipe:close() end
    end
    if handle and not handle:is_closing() then handle:close() end
  end

  local finish = function()
    if not (code and stdout_done and stderr_done) then return end
    close()
    vim.schedule(function()
      if killed then return end
      if code == 0 then
        on_exit()
      else
        on_exit(vim.trim(table.concat(errors)))
      end
    end)
  end

  ---@param err? string
  ---@param data? string
  local on_stdout = function(err, data)
    assert(not err, err)
    if not data then
      stdout_done = true
      if partial ~= "" then
        local last = parse_log_line(partial)
        vim.schedule(function()
          if not killed then on_lines({ last }) end
        end)
      end
      return finish()
    end

    local texts = vim.split(partial .. data, "\n", { plain = true })
    partial = table.remove(texts)
    local lines = vim.tbl_map(parse_log_line, texts)
    if #lines == 0 then return end
    vim.schedule(function()
      if not killed then on_lines(lines) end
    end)
  end

  handle = uv.spawn("jj", {
    args = args,
    cwd = root,
    stdio = { nil, stdout, stderr },
  }, function(exit_code)
    code = exit_code
    finish()
  end)

  if not handle then
    close()
    vim.schedule(function() on_exit("Couldn't run jj") end)
  else
    stdout:read_start(on_stdout)
    stderr:read_start(function(_, data)
      if data then
        errors[#errors + 1] = data
      else
        stderr_done = true
        finish()
      end
    end)
  end

  return {
    pause = function()
      if reading and not stdout:is_closing() then
        stdout:read_stop()
        reading = false
      end
    end,
    resume = function()
      if not reading and not stdout:is_closing() then
        stdout:read_start(on_stdout)
        reading = true
      end
    end,
    kill = function()
      killed = true
      if handle and not handle:is_closing() then handle:kill("sigterm") end
      close()
    end,
  }
end

--- Returns the changes in a revset, without snapshotting the working copy.
---@param root string
---@param revset string
---@param on_done fun(err?: string, changes?: nvim_jj.Change[])
M.changes = function(root, revset, on_done)
  local args = {
    "--ignore-working-copy",
    "log",
    "--no-graph",
    "--revisions",
    revset,
    "--template",
    change_template .. ' ++ "\\n"',
  }

  run(root, args, function(result)
    if result.code ~= 0 then return on_done(vim.trim(result.stderr or "")) end
    local changes = {}
    for line in (result.stdout or ""):gmatch("[^\n]+") do
      changes[#changes + 1] = parse_change(line)
    end
    on_done(nil, changes)
  end)
end

--- Returns the change IDs of the parents of the changes in a revset, keyed by
--- the changes' IDs, without snapshotting the working copy.
---@param root string
---@param revset string
---@param on_done fun(err?: string, parents?: table<string, string[]>)
M.parents = function(root, revset, on_done)
  local args = {
    "--ignore-working-copy",
    "log",
    "--no-graph",
    "--revisions",
    revset,
    "--template",
    [[change_id ++ " " ++ parents.map(|p| p.change_id()).join(" ") ++ "\n"]],
  }

  run(root, args, function(result)
    if result.code ~= 0 then return on_done(vim.trim(result.stderr or "")) end
    ---@type table<string, string[]>
    local parents = {}
    for line in (result.stdout or ""):gmatch("[^\n]+") do
      local ids = vim.split(line, " ", { trimempty = true })
      parents[table.remove(ids, 1)] = ids
    end
    on_done(nil, parents)
  end)
end

---@class nvim_jj.RemoteBookmark
---@field name string
---@field tracked boolean

--- Returns the bookmarks of a remote that point to a revision, without
--- snapshotting the working copy.
---@param root string
---@param rev string
---@param remote string
---@param on_done fun(err?: string, bookmarks?: nvim_jj.RemoteBookmark[])
M.remote_bookmarks = function(root, rev, remote, on_done)
  local args = {
    "--ignore-working-copy",
    "log",
    "--no-graph",
    "--revisions",
    rev,
    "--template",
    ([[remote_bookmarks.filter(|b| b.remote() == %s).map(|b| b.name() ++ "%s" ++ if(b.tracked(), "1") ++ "\n").join("")]]):format(
      M.quote(remote),
      field_separator_escape
    ),
  }

  run(root, args, function(result)
    if result.code ~= 0 then return on_done(vim.trim(result.stderr or "")) end
    ---@type nvim_jj.RemoteBookmark[]
    local bookmarks = {}
    for line in (result.stdout or ""):gmatch("[^\n]+") do
      local fields = vim.split(line, field_separator, { plain = true })
      bookmarks[#bookmarks + 1] = {
        name = fields[1] or "",
        tracked = fields[2] == "1",
      }
    end
    on_done(nil, bookmarks)
  end)
end

--- Returns a revision's full description, without snapshotting the working
--- copy.
---@param root string
---@param rev string
---@param on_done fun(err?: string, description?: string)
M.description = function(root, rev, on_done)
  local args = {
    "--ignore-working-copy",
    "log",
    "--no-graph",
    "--revisions",
    rev,
    "--template",
    "description",
  }

  run(root, args, function(result)
    if result.code ~= 0 then return on_done(vim.trim(result.stderr or "")) end
    on_done(nil, result.stdout or "")
  end)
end

--- Sets a revision's description.
---@param root string
---@param rev string
---@param description string
---@param on_done fun(err?: string)
M.describe = function(root, rev, description, on_done)
  local args = { "describe", "--stdin", "--", rev }
  run(root, args, on_success(on_done), description)
end

---@class nvim_jj.Place
---@field onto? string The new parents, which keep their children.
---@field after? string The new parents, whose children become the placed revisions' children.
---@field before? string The new children, whose parents become the placed revisions' parents unless `after` is set.

--- Returns the arguments placing revisions where a place says.
---@param place nvim_jj.Place
---@return string[]
local place_args = function(place)
  local args = {}
  if place.onto then vim.list_extend(args, { "--onto", place.onto }) end
  if place.after then
    vim.list_extend(args, { "--insert-after", place.after })
  end
  if place.before then
    vim.list_extend(args, { "--insert-before", place.before })
  end
  return args
end

--- Returns the change ID prefixes that a pattern captures in a command's
--- messages.
---@param result vim.SystemCompleted
---@param pattern string
---@return string[]
local prefixes_in = function(result, pattern)
  local prefixes = {}
  for prefix in (result.stderr or ""):gmatch(pattern) do
    prefixes[#prefixes + 1] = prefix
  end
  return prefixes
end

--- Creates an empty change in a place.
---@param root string
---@param place nvim_jj.Place
---@param check_out boolean
---@param on_done fun(err?: string, prefix?: string) Called with a prefix of the new change's ID.
M.new = function(root, place, check_out, on_done)
  local args = { "new" }
  if not check_out then args[#args + 1] = "--no-edit" end
  if place.onto then args[#args + 1] = place.onto end
  vim.list_extend(
    args,
    place_args({ after = place.after, before = place.before })
  )
  run(root, args, function(result)
    if result.code ~= 0 then return on_done(vim.trim(result.stderr or "")) end
    on_done(nil, prefixes_in(result, "Created new commit (%S+)")[1])
  end)
end

--- Moves revisions to a place, keeping the edges between the moved ones. The
--- children of the moved revisions that aren't moved become children of their
--- parents.
---@param root string
---@param revs string[]
---@param place nvim_jj.Place
---@param on_done fun(err?: string)
M.rebase = function(root, revs, place, on_done)
  local args = { "rebase" }
  for _, rev in ipairs(revs) do
    vim.list_extend(args, { "--revision", rev })
  end
  vim.list_extend(args, place_args(place))
  run(root, args, on_success(on_done))
end

---@class nvim_jj.Copy
---@field source string A prefix of the copied commit's ID.
---@field change string A prefix of the copy's change ID.

--- Copies revisions to a place, keeping the edges between the copied ones.
---@param root string
---@param revs string[]
---@param place nvim_jj.Place
---@param on_done fun(err?: string, copies?: nvim_jj.Copy[])
M.duplicate = function(root, revs, place, on_done)
  local args = { "duplicate" }
  vim.list_extend(args, place_args(place))
  args[#args + 1] = "--"
  vim.list_extend(args, revs)
  run(root, args, function(result)
    if result.code ~= 0 then return on_done(vim.trim(result.stderr or "")) end
    ---@type nvim_jj.Copy[]
    local copies = {}
    for source, change in
      (result.stderr or ""):gmatch("Duplicated (%S+) as (%S+)")
    do
      copies[#copies + 1] = { source = source, change = change }
    end
    on_done(nil, copies)
  end)
end

--- Checks out a revision.
---@param root string
---@param rev string
---@param on_done fun(err?: string)
M.edit = function(root, rev, on_done)
  run(root, { "edit", rev }, on_success(on_done))
end

--- Fetches the bookmarks of a remote.
---@param root string
---@param remote string
---@param on_done fun(err?: string)
M.fetch = function(root, remote, on_done)
  run(root, { "git", "fetch", "--remote", remote }, on_success(on_done))
end

--- Returns the URL of a git remote, without snapshotting the working copy.
---@param root string
---@param remote string
---@param on_done fun(err?: string, url?: string)
M.remote_url = function(root, remote, on_done)
  local args = { "--ignore-working-copy", "git", "remote", "list" }
  run(root, args, function(result)
    if result.code ~= 0 then return on_done(vim.trim(result.stderr or "")) end
    for line in (result.stdout or ""):gmatch("[^\n]+") do
      local name, url = line:match("^(%S+)%s+(%S+)")
      if name == remote then return on_done(nil, url) end
    end
    on_done(("There's no remote named %s"):format(remote))
  end)
end

--- Abandons revisions. Their children become children of their parents, and
--- so do their bookmarks.
---@param root string
---@param revs string[]
---@param on_done fun(err?: string)
M.abandon = function(root, revs, on_done)
  local args = { "abandon", "--retain-bookmarks", "--" }
  vim.list_extend(args, revs)
  run(root, args, on_success(on_done))
end

--- Starts tracking a remote bookmark.
---@param root string
---@param name string
---@param remote string
---@param on_done fun(err?: string)
M.track = function(root, name, remote, on_done)
  local args = { "bookmark", "track", ("%s@%s"):format(name, remote) }
  run(root, args, on_success(on_done))
end

--- Creates a local bookmark pointing to a revision.
---@param root string
---@param name string
---@param rev string
---@param on_done fun(err?: string)
M.create_bookmark = function(root, name, rev, on_done)
  local args = { "bookmark", "create", name, "--revision", rev }
  run(root, args, on_success(on_done))
end

--- Renames a local bookmark.
---@param root string
---@param old string
---@param new string
---@param on_done fun(err?: string)
M.rename_bookmark = function(root, old, new, on_done)
  local args = { "bookmark", "rename", old, new }
  run(root, args, on_success(on_done))
end

--- Deletes a local bookmark, which deletes it from its tracked remotes on
--- their next push.
---@param root string
---@param name string
---@param on_done fun(err?: string)
M.delete_bookmark = function(root, name, on_done)
  local args = { "bookmark", "delete", ("exact:%s"):format(M.quote(name)) }
  run(root, args, on_success(on_done))
end

--- Points a local bookmark to a revision.
---@param root string
---@param name string
---@param rev string
---@param backwards boolean Whether the revision can be off the bookmark's descendants.
---@param on_done fun(err?: string)
M.set_bookmark = function(root, name, rev, backwards, on_done)
  local args = { "bookmark", "set", name, "--revision", rev }
  if backwards then args[#args + 1] = "--allow-backwards" end
  run(root, args, on_success(on_done))
end

--- Pushes a bookmark to a git remote.
---@param root string
---@param name string
---@param remote string
---@param on_done fun(err?: string)
M.push = function(root, name, remote, on_done)
  local args = { "git", "push", "--remote", remote, "--bookmark", name }
  run(root, args, on_success(on_done))
end

return M

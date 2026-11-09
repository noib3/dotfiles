local M = {}

---@class nvim_jj.PullRequest
---@field number integer
---@field url string

--- Returns the `owner/name` of the GitHub repo at a git remote's URL, or
--- nothing if it isn't on GitHub.
---@param url string
---@return string?
M.repo_of = function(url)
  local repo = url:match("github%.com[:/]([^/]+/[^/]+)$")
  return repo and (repo:gsub("%.git$", ""))
end

--- Runs the GitHub CLI.
---@param root string
---@param gh string The GitHub CLI's executable.
---@param args string[]
---@param on_done fun(err?: string, stdout?: string)
local run = function(root, gh, args, on_done)
  local cmd = { gh }
  vim.list_extend(cmd, args)
  local ok, err = pcall(
    vim.system,
    cmd,
    { cwd = root, text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then return on_done(vim.trim(result.stderr or "")) end
      on_done(nil, result.stdout or "")
    end)
  )
  if not ok then on_done(tostring(err)) end
end

--- Returns the open pull requests of a repo from branches of the repo
--- itself, keyed by branch.
---@param root string
---@param gh string The GitHub CLI's executable.
---@param repo string The repo's `owner/name`.
---@param on_done fun(err?: string, pull_requests?: table<string, nvim_jj.PullRequest>)
M.pull_requests = function(root, gh, repo, on_done)
  local args = {
    "pr",
    "list",
    "--repo",
    repo,
    "--state",
    "open",
    "--limit",
    "200",
    "--json",
    "number,headRefName,url,isCrossRepository",
  }
  run(root, gh, args, function(err, stdout)
    if err or not stdout then return on_done(err) end
    local ok, list = pcall(vim.json.decode, stdout)
    if not ok or type(list) ~= "table" then
      return on_done("gh didn't list the pull requests as JSON")
    end
    ---@type table<string, nvim_jj.PullRequest>
    local pull_requests = {}
    for _, item in ipairs(list) do
      if not item.isCrossRepository and item.headRefName then
        pull_requests[item.headRefName] = { number = item.number, url = item.url }
      end
    end
    on_done(nil, pull_requests)
  end)
end

--- Opens a pull request, and calls back with it.
---@param root string
---@param gh string The GitHub CLI's executable.
---@param repo string The repo's `owner/name`.
---@param head string The bookmark whose changes are pulled.
---@param base string The bookmark the changes are pulled into.
---@param title string
---@param body string
---@param on_done fun(err?: string, pull_request?: nvim_jj.PullRequest)
M.create_pull_request = function(root, gh, repo, head, base, title, body, on_done)
  local args = {
    "pr",
    "create",
    "--repo",
    repo,
    "--head",
    head,
    "--base",
    base,
    "--title",
    title,
    "--body",
    body,
  }
  run(root, gh, args, function(err, stdout)
    if err or not stdout then return on_done(err) end
    local url = stdout:match("https://%S+") or vim.trim(stdout)
    local number = tonumber(url:match("/pull/(%d+)"))
    if not number then return on_done(("gh didn't print the pull request's URL: %s"):format(url)) end
    on_done(nil, { number = number --[[@as integer]], url = url })
  end)
end

return M

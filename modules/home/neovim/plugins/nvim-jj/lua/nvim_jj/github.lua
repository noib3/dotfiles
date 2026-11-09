local M = {}

--- Returns the `owner/name` of the GitHub repo at a git remote's URL, or
--- nothing if it isn't on GitHub.
---@param url string
---@return string?
M.repo_of = function(url)
  local repo = url:match("github%.com[:/]([^/]+/[^/]+)$")
  return repo and (repo:gsub("%.git$", ""))
end

--- Opens a pull request with an empty description, and calls back with its
--- URL.
---@param root string
---@param gh string The GitHub CLI's executable.
---@param repo string The repo's `owner/name`.
---@param head string The bookmark whose changes are pulled.
---@param base string The bookmark the changes are pulled into.
---@param title string
---@param on_done fun(err?: string, url?: string)
M.create_pull_request = function(root, gh, repo, head, base, title, on_done)
  local cmd = {
    gh,
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
    "",
  }
  local ok, err = pcall(
    vim.system,
    cmd,
    { cwd = root, text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then return on_done(vim.trim(result.stderr or "")) end
      local stdout = vim.trim(result.stdout or "")
      on_done(nil, stdout:match("https://%S+") or stdout)
    end)
  )
  if not ok then on_done(tostring(err)) end
end

return M

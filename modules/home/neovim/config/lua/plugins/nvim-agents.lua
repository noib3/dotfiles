local agents = require("nvim_agents")
local jj = require("nvim_jj")
local threads = require("nvim_threads")

agents.setup({
  agents = {
    claude = { cmd = { "claude-agent-acp" } },
  },
})

local claude_icon = require("utils.logos").claude.icon .. " "

--- The size past which a change's diff is cut in a prompt.
local max_diff_bytes = 100 * 1024

--- The number of Claude sessions threads can mention by name.
local max_mentioned_sessions = 10

--- Returns the Claude sessions matching paths best, with the labels telling
--- them apart in mentions like `@claude.<label>`: their titles, or else
--- their directories, in lowercase with dashes, and the start of their IDs
--- when they're the same.
---@param paths string[] Absolute paths.
---@return { session: nvim_agents.Session, label: string }[]
local labeled_sessions = function(paths)
  local matches = agents.sessions({ paths = paths, agent = "claude" })
  local labeled, counts = {}, {}
  for index = 1, math.min(#matches, max_mentioned_sessions) do
    local session = assert(matches[index]).session
    local name = session.title
      or (session.cwd and vim.fs.basename(session.cwd))
      or session.id
    local label = name:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
    labeled[#labeled + 1] = { session = session, label = label }
    counts[label] = (counts[label] or 0) + 1
  end
  for _, entry in ipairs(labeled) do
    if counts[entry.label] > 1 or entry.label == "" then
      entry.label = (entry.label == "" and "" or entry.label .. "-")
        .. entry.session.id:sub(1, 8)
    end
  end
  return labeled
end

--- Returns how long ago a Unix time was, like `5m` or `2d`.
---@param time integer
---@return string
local ago = function(time)
  local seconds = os.time() - time
  if seconds < 3600 then return ("%dm"):format(math.floor(seconds / 60)) end
  if seconds < 86400 then return ("%dh"):format(math.floor(seconds / 3600)) end
  return ("%dd"):format(math.floor(seconds / 86400))
end

--- Returns a conversation in a fork of the Claude session matching the
--- paths best, or of the one a label names, and that session, or a
--- conversation in a new session if none matches them.
---@param paths string[] Absolute paths.
---@param root string The root of the paths' jj workspace.
---@param label? string
---@return nvim_agents.Conversation
---@return nvim_agents.Session?
local conversation_for = function(paths, root, label)
  local labeled = labeled_sessions(paths)
  local match = labeled[1]
  for _, entry in ipairs(labeled) do
    if entry.label == label then match = entry end
  end
  if not match then return agents.start("claude", root) end
  local session = match.session
  local conversation = agents.fork({
    agent = session.agent,
    id = session.id,
    cwd = session.cwd or root,
  })
  return conversation, session
end

local thread_preamble = [[
This is a review thread on code, in a fork of your session: your reply goes
into the thread, and the main session doesn't see it. Your edits aren't
applied: the reviewer sees them as suggestions, and applies the ones they
want. Keep the reply short.

]]

---@class Fork
---@field conversation nvim_agents.Conversation
---@field session? nvim_agents.Session The session forked, unless the conversation's is new.

--- The conversations answering the threads, by thread ID.
---@type table<string, Fork?>
local forks = {}

threads.register({
  name = "claude",
  color = require("utils.logos").claude.color,
  -- With a single session, `@claude` already names it.
  mentions = function(bufnr)
    local labeled = labeled_sessions({ vim.api.nvim_buf_get_name(bufnr) })
    if #labeled < 2 then return {} end
    return vim.tbl_map(function(entry)
      local session = entry.session
      local where = session.cwd and vim.fn.fnamemodify(session.cwd, ":~") or ""
      return {
        name = "claude." .. entry.label,
        detail = ("%s  %s  %s"):format(
          session.title or "",
          where,
          ago(session.time)
        ),
      }
    end, labeled)
  end,
  send = function(request, reply)
    local id = request.thread.id
    local fork = forks[id]
    local text
    if fork then
      -- The fork already has the earlier comments.
      local comments = request.thread.comments
      text = request.context .. "\n\n" .. comments[#comments].body
    else
      local conversation, session = conversation_for(
        { vim.fs.joinpath(request.root, request.path) },
        request.root,
        request.mention and request.mention:match("^claude%.(.+)$")
      )
      fork = { conversation = conversation, session = session }
      forks[id] = fork
      text = thread_preamble .. request.prompt
    end

    return fork.conversation:prompt(text, {
      chunk = reply.chunk,
      done = function(result)
        local edits = {}
        for _, edit in ipairs(result.edits) do
          local path = vim.fs.relpath(request.root, edit.path)
          if path then
            edits[#edits + 1] = {
              path = path,
              old_text = edit.old_text,
              new_text = edit.new_text,
            }
          end
        end
        reply.done({ body = result.text, edits = edits })
      end,
      error = reply.error,
    })
  end,
})

local summary_prompt = [[
The reviewer is sending this thread to the main session you were forked
from, which hasn't seen it. Write what the main session needs to know: what
the reviewer asked, what you found, and what was decided, including the
changes to make that aren't made yet. Address the main session's agent, and
reply with the summary alone.]]

--- The text queued for the main session, with the thread's file and the
--- fork's summary.
local promoted = [[
The user sent you a review thread on `%s`, from a fork of this session that
answered it. The fork's summary:

%s]]

threads.register_action({
  title = claude_icon .. " Promote to the main session",
  available = function(ctx)
    local fork = forks[ctx.thread.id]
    return fork ~= nil and fork.session ~= nil
  end,
  run = function(ctx)
    local fork = assert(forks[ctx.thread.id])
    local session = assert(fork.session)
    vim.notify("Summarizing the thread for the main session")
    fork.conversation:prompt(summary_prompt, {
      done = function(result)
        local text = promoted:format(
          vim.fs.joinpath(ctx.root, ctx.path),
          vim.trim(result.text)
        )
        local err = agents.queue(session, text)
        if err then return vim.notify(err, vim.log.levels.ERROR) end
        vim.notify("Promoted: it's added to the main session's next prompt")
      end,
      error = function(message) vim.notify(message, vim.log.levels.ERROR) end,
    })
  end,
})

--- Returns the paths of the files in a git diff, relative to its root.
---@param diff string
---@return string[]
local paths_of_diff = function(diff)
  local paths, seen = {}, {}
  for old, new in diff:gmatch("\ndiff %-%-git a/(%S+) b/(%S+)") do
    for _, path in ipairs({ old, new }) do
      if not seen[path] then
        seen[path] = true
        paths[#paths + 1] = path
      end
    end
  end
  return paths
end

--- Returns a reply's text without the code fence around it, if any.
---@param text string
---@return string
local unfenced = function(text)
  text = vim.trim(text)
  local inner = text:match("^```[%w-]*\n(.-)\n```$")
  return vim.trim(inner or text)
end

---@param root string
---@param args string[]
---@param on_done fun(err?: string, stdout?: string)
local run_jj = function(root, args, on_done)
  vim.system(
    vim.list_extend({ "jj", "--color", "never" }, args),
    { cwd = root, text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        return on_done(vim.trim(result.stderr or "jj failed"))
      end
      on_done(nil, result.stdout or "")
    end)
  )
end

--- The instructions of the prompts writing each kind of text.
---@type table<nvim_jj.ActionTarget, string>
local message_instructions = {
  subject = [[
Write the subject of the jj change below: a single line in the style of the
repo's recent subjects, listed below. Reply with the subject alone, without
quotes or anything else.]],
  description = [[
Write the description of the jj change below, the body that follows its
subject after a blank line: what the subject can't say that matters. Reply
with the body alone, without its subject, a code fence or anything else.]],
  pr_title = [[
Write the title of the pull request of the jj changes below: a single line in
the style of the repo's recent subjects, listed below. Reply with the title
alone, without quotes or anything else.]],
  pr_description = [[
Write the description of the pull request of the jj changes below, for its
reviewers: what the changes do and why, briefly. Reply with the description
alone, in Markdown, without its title or a code fence.]],
}

--- The names of the texts in the actions' progress.
---@type table<nvim_jj.ActionTarget, string>
local message_names = {
  subject = "subject",
  description = "description",
  pr_title = "title",
  pr_description = "description",
}

local message_prompt = [[
%s

Recent subjects:
%s

The text as it is:
%s

Diff:
```diff
%s
```]]

--- Asks the Claude session matching the changed files best to write the
--- text of an action's context, and replaces the text with the reply.
---@param ctx nvim_jj.ActionContext
local write_message = function(ctx)
  local root = ctx.root
  ctx.set_status("busy", "Writing the " .. message_names[ctx.target])
  local fail = function(message) ctx.set_status("failed", message) end

  run_jj(root, vim.list_extend({ "diff", "--git" }, ctx.diff), function(diff_err, diff)
    if diff_err or not diff then return fail(diff_err or "no diff") end
    run_jj(root, {
      "log",
      "--no-graph",
      "-r",
      ctx.before,
      "-n",
      "15",
      "-T",
      'description.first_line() ++ "\n"',
    }, function(log_err, subjects)
      if log_err then return fail(log_err) end
      if #diff > max_diff_bytes then
        diff = diff:sub(1, max_diff_bytes) .. "\n[the rest of the diff is cut]"
      end
      local paths = vim.tbl_map(
        function(path) return vim.fs.joinpath(root, path) end,
        paths_of_diff("\n" .. diff)
      )
      local prompt = message_prompt:format(
        message_instructions[ctx.target],
        vim.trim(subjects or ""),
        vim.trim(ctx.text) ~= "" and vim.trim(ctx.text) or "(none)",
        diff
      )
      conversation_for(paths, root):prompt(prompt, {
        done = function(result)
          local message = unfenced(result.text)
          if message == "" then return fail("the reply is empty") end
          ctx.set_status("done", "Written")
          ctx.replace(message)
        end,
        error = fail,
      })
    end)
  end)
end

--- Returns whether an action's context is on one of some texts, of changes
--- that can be described.
---@param targets nvim_jj.ActionTarget[]
---@return fun(ctx: nvim_jj.ActionContext): boolean
local on = function(targets)
  return function(ctx)
    return vim.list_contains(targets, ctx.target)
      and not ctx.immutable
      and not ctx.empty
  end
end

jj.register_action({
  title = claude_icon .. " Let Claude write the subject",
  available = on({ "subject" }),
  run = write_message,
})

jj.register_action({
  title = claude_icon .. " Let Claude write the description",
  available = on({ "description", "pr_description" }),
  run = write_message,
})

jj.register_action({
  title = claude_icon .. " Let Claude write the title",
  available = on({ "pr_title" }),
  run = write_message,
})

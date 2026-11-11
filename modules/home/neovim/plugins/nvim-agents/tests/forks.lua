local agents = require("nvim_agents")
local h = require("nvim_agents_tests")

local log = vim.fs.joinpath(h.tmpdir(), "agent.jsonl")

agents.setup({
  agents = { fake = { cmd = h.fake_agent(log) } },
  state_dir = h.tmpdir(),
})

local session = { agent = "fake", id = "main", cwd = "/repo" }

--- Prompts a conversation and waits for the reply.
---@param conversation nvim_agents.Conversation
---@param text string
---@return { chunks: string[], result?: nvim_agents.Result, error?: string }
local prompt = function(conversation, text)
  ---@type { chunks: string[], result?: nvim_agents.Result, error?: string }
  local reply = { chunks = {} }
  conversation:prompt(text, {
    chunk = function(chunk) table.insert(reply.chunks, chunk) end,
    done = function(result) reply.result = result end,
    error = function(message) reply.error = message end,
  })
  h.wait(
    function() return reply.result ~= nil or reply.error ~= nil end,
    "the reply is done"
  )
  return reply
end

test("a fork streams its reply, with a paragraph after a tool call", function()
  local conversation = agents.fork(session)
  local reply = prompt(conversation, "hi")
  h.eq(reply.error, nil)
  h.eq(reply.chunks, { "Hello", " world.", "\n\nBye." })
  h.eq(assert(reply.result).text, "Hello world.\n\nBye.")
  h.eq(assert(reply.result).edits, {})
  h.eq(conversation.id, "fork-1")

  local fork = assert(
    vim
      .iter(h.agent_log(log))
      :find(function(message) return message.method == "session/fork" end)
  )
  h.eq(fork.params, { sessionId = "main", cwd = "/repo", mcpServers = {} })
end)

test(
  "a fork's session is closed after a reply, and resumed for the next",
  function()
    local conversation = agents.fork(session)
    prompt(conversation, "hi")
    local id = conversation.id
    prompt(conversation, "again")
    h.eq(conversation.id, id)

    ---@type string[]
    local methods
    h.wait(function()
      methods = vim.tbl_filter(
        function(method) return method ~= "initialize" end,
        h.agent_methods(log)
      )
      return methods[#methods] == "session/close"
    end, "the session is closed again")
    h.eq(vim.list_slice(methods, #methods - 6), {
      "session/fork",
      "session/resume",
      "session/prompt",
      "session/close",
      "session/resume",
      "session/prompt",
      "session/close",
    })
  end
)

test("edits are rejected, and returned as suggestions", function()
  local reply = prompt(agents.fork(session), "edit")
  h.eq(assert(reply.result).text, "rejected")
  h.eq(
    assert(reply.result).edits,
    { { path = "/repo/a.txt", old_text = "old", new_text = "new" } }
  )
end)

test("reads are allowed", function()
  local reply = prompt(agents.fork(session), "read")
  h.eq(assert(reply.result).text, "allowed")
  h.eq(assert(reply.result).edits, {})
end)

test("prompts sent during a turn wait for it", function()
  local conversation = agents.fork(session)
  local first, second = {}, {}
  conversation:prompt("one", {
    done = function(result) first.text = result.text end,
    error = error,
  })
  conversation:prompt("two", {
    done = function(result) second.text = result.text end,
    error = error,
  })
  h.wait(function() return second.text ~= nil end, "both replies are done")
  h.eq(first.text, "Hello world.\n\nBye.")
  h.eq(second.text, "Hello world.\n\nBye.")
end)

test("a cancelled turn calls nothing back", function()
  local conversation = agents.fork(session)
  local called = false
  local cancel = conversation:prompt("slow", {
    chunk = function() end,
    done = function() called = true end,
    error = function() called = true end,
  })
  h.wait(function()
    return vim
      .iter(h.agent_methods(log))
      :any(function(method) return method == "session/prompt" end)
  end, "the prompt is sent")
  vim.wait(100)
  cancel()
  h.wait(function()
    local methods = h.agent_methods(log)
    return methods[#methods] == "session/close"
  end, "the session is closed")
  h.eq(called, false)

  -- The conversation goes on after a cancellation.
  local reply = prompt(conversation, "hi")
  h.eq(assert(reply.result).text, "Hello world.\n\nBye.")
end)

test(
  "an agent's exit fails its turns, and the next prompt restarts it",
  function()
    local reply = prompt(agents.fork(session), "crash")
    h.eq(reply.result, nil)
    h.eq(
      reply.error ~= nil
        and reply.error:find("crashed on purpose", 1, true) ~= nil,
      true
    )

    local again = prompt(agents.fork(session), "hi")
    h.eq(assert(again.result).text, "Hello world.\n\nBye.")
  end
)

test("a new session starts in its directory", function()
  local conversation = agents.start("fake", "/elsewhere")
  local reply = prompt(conversation, "hi")
  h.eq(reply.error, nil)
  h.eq(vim.startswith(assert(conversation.id), "new-"), true)
  local new = assert(
    vim
      .iter(h.agent_log(log))
      :find(function(message) return message.method == "session/new" end)
  )
  h.eq(new.params, { cwd = "/elsewhere", mcpServers = {} })
end)

test("an unknown agent fails the prompt", function()
  local reply = prompt(agents.start("nope", "/repo"), "hi")
  h.eq(reply.error, "No agent named nope")
end)

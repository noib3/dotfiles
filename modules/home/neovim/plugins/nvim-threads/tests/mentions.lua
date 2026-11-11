local h = require("nvim_threads_tests")
local threads = require("nvim_threads")

local bot, requests = h.participant("bot", { "Hi." })
bot.mentions = function(bufnr)
  h.eq(vim.bo[bufnr].filetype ~= "nvim-threads", true, "the mentions are the source buffer's")
  return {
    { name = "bot.docs", detail = "the docs session" },
    { name = "bot.api", detail = "the API session" },
  }
end
threads.register(bot)

h.setup(80, 30)
local root = h.repo({ ["f.txt"] = h.text({ "one", "two" }) }, {})
vim.keymap.set({ "n", "x" }, "<F2>", function() threads.create() end)

test("a participant's own mentions are completed, and tell its requests apart", function()
  h.open(root, "f.txt")
  vim.api.nvim_feedkeys(vim.keycode("1G<F2>"), "x", false)
  vim.cmd.stopinsert()
  local float_buf = vim.api.nvim_get_current_buf()
  h.type({ "@bot" })
  local client =
    assert(vim.lsp.get_clients({ bufnr = float_buf, name = "nvim-threads" })[1])
  local line = vim.api.nvim_buf_line_count(float_buf)
  local response = client:request_sync("textDocument/completion", {
    textDocument = { uri = vim.uri.from_buf(float_buf) },
    position = { line = line - 1, character = 4 },
  }, 2000, float_buf)
  local items = assert(response and response.result).items
  h.eq(
    vim.tbl_map(function(item) return { item.label, item.detail } end, items),
    {
      { "bot", "Participant" },
      { "bot.docs", "the docs session" },
      { "bot.api", "the API session" },
    }
  )

  h.type({ "@bot.api what about this?" })
  h.eq(threads.submit(), true)
  h.wait(function() return #requests == 1 end, "the participant is asked")
  h.eq(assert(requests[1]).mention, "bot.api")
  h.eq(assert(requests[1]).thread.participants, { "bot" })
end)

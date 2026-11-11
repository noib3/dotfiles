local h = require("nvim_threads_tests")
local threads = require("nvim_threads")

threads.register(h.participant("bot", {
  "Use `foo` and **bold** here.\n```lua\nlocal x = 1\n```",
}))

h.setup(80, 30)

local root = h.repo({ ["f.txt"] = h.text({ "one", "two", "three" }) }, {})

vim.keymap.set({ "n", "x" }, "<F2>", function() threads.create() end)

--- Returns the text the float's buffer hides, by 1-based line.
---@param buf integer
---@return table<integer, string[]>
local hidden = function(buf)
  local namespace = vim.api.nvim_create_namespace("nvim-threads-conceal")
  local result = {}
  for _, mark in
    ipairs(
      vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, { details = true })
    )
  do
    local line = mark[2] + 1
    local text = vim.api.nvim_buf_get_lines(buf, mark[2], mark[2] + 1, false)[1]
      or ""
    result[line] = result[line] or {}
    table.insert(result[line], text:sub(mark[3] + 1, assert(mark[4]).end_col))
  end
  return result
end

test(
  "a reply's Markdown is hidden, except the element under the cursor",
  function()
    local bufnr = h.open(root, "f.txt")
    vim.api.nvim_feedkeys(vim.keycode("2G<F2>"), "x", false)
    vim.cmd.stopinsert()
    h.type({ "@bot how?" })
    h.eq(threads.submit(), true)
    local float_buf = vim.api.nvim_get_current_buf()
    local lines = function()
      return vim.api.nvim_buf_get_lines(float_buf, 0, -1, false)
    end
    h.wait(
      function()
        return vim.tbl_contains(lines(), "Use `foo` and **bold** here.")
      end,
      "the participant replies"
    )
    local reply =
      assert(
        vim.iter(ipairs(lines())):find(
          function(_, line) return line == "Use `foo` and **bold** here." end
        )
      )
    h.eq(hidden(float_buf)[reply], { "`", "`", "*", "*", "*", "*" })
    h.eq(hidden(float_buf)[reply + 1], { "```", "lua" })
    h.eq(hidden(float_buf)[reply + 3], { "```" })

    -- In `foo`, its backticks are revealed.
    vim.api.nvim_win_set_cursor(0, { reply, 6 })
    vim.api.nvim_exec_autocmds("CursorMoved", { buffer = float_buf })
    h.eq(hidden(float_buf)[reply], { "*", "*", "*", "*" })
    -- In the code block, its fences are.
    vim.api.nvim_win_set_cursor(0, { reply + 2, 2 })
    vim.api.nvim_exec_autocmds("CursorMoved", { buffer = float_buf })
    h.eq(hidden(float_buf)[reply], { "`", "`", "*", "*", "*", "*" })
    h.eq(hidden(float_buf)[reply + 1], nil)
    h.eq(hidden(float_buf)[reply + 3], nil)

    -- The virtual lines under the float always hide it.
    h.wait(function()
      local virt = h.virt_lines(bufnr)[2]
      return virt ~= nil and (virt[1] or ""):find("2 messages", 1, true) ~= nil
    end, "the reply is done")
    local virt = h.virt_lines(bufnr)[2]
    h.eq(
      vim.tbl_contains(virt, "▎ Use foo and bold here."),
      true,
      vim.inspect(virt)
    )
    h.eq(vim.tbl_contains(virt, "▎ local x = 1"), true, vim.inspect(virt))
    h.leave()
  end
)

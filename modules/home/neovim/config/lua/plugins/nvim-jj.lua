local jj = require("nvim_jj")

jj.setup()

--- Sets the options of a window showing a jj log. The backticks of code
--- stay hidden on the cursor's line in normal and insert mode.
---@param win integer
local set_window_options = function(win)
  local wo = vim.wo[win][0]
  wo.number = false
  wo.relativenumber = false
  wo.wrap = false
  wo.conceallevel = 2
  wo.concealcursor = "ni"
  vim.api.nvim_win_call(
    win,
    function() vim.opt_local.listchars:remove("eol") end
  )
end

vim.keymap.set("n", "jj", function()
  local win = jj.toggle()
  if not win then return end
  set_window_options(win)
  -- The window opened without autocommands, so the statusline hasn't drawn
  -- the separator above it yet.
  vim.api.nvim_exec_autocmds("WinNew", {
    group = "noib3/lualine-statusline",
    modeline = false,
  })
end, { desc = "Toggle the jj log of the current workspace" })

--- Returns the lines of the visual selection, or the cursor's line outside
--- of visual mode, and leaves visual mode.
---@return integer first
---@return integer last
local selected_lines = function()
  local cursor = vim.fn.line(".")
  if not vim.fn.mode():match("^[vV\22]") then return cursor, cursor end
  local start = vim.fn.line("v")
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  return start, cursor
end

local group = vim.api.nvim_create_augroup("noib3/nvim-jj", { clear = true })

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = group,
  pattern = "jj://*",
  desc = "Sets the options of the jj log's window",
  callback = function() set_window_options(vim.api.nvim_get_current_win()) end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "jjlog",
  desc = "Sets the keymaps of the jj log",
  callback = function(ev)
    local bufnr = ev.buf
    vim.bo[bufnr].textwidth = 0
    ---@param modes string|string[]
    ---@param lhs string
    ---@param rhs fun()
    ---@param desc string
    local map = function(modes, lhs, rhs, desc)
      vim.keymap.set(modes, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    -- Moving down doesn't wait for the `jj` that toggles the log, which would
    -- close it while scrolling, so `q` closes it instead.
    vim.keymap.set("n", "j", "j", { buffer = bufnr, nowait = true })
    map("n", "q", function() jj.toggle() end, "Close the jj log")

    -- Children are drawn above their parents, so a change opened above the
    -- line is a child, and one opened below it is a parent. With `g`, it
    -- takes no children.
    for keys, position in pairs({ O = "above", o = "below" }) do
      for _, branch in ipairs({ false, true }) do
        map(
          { "n", "x" },
          (branch and "g" or "") .. keys,
          function()
            local first, last = selected_lines()
            jj.insert_change(bufnr, position, branch, first, last)
          end,
          ("Insert an empty change %s the selected ones%s"):format(
            position,
            branch and ", on a new branch" or ""
          )
        )
      end
    end

    -- Whole lines cut or copy their changes, while the operators with other
    -- motions edit the subjects.
    for operator, hold in pairs({ d = jj.cut, y = jj.copy }) do
      local what = operator == "d" and "Cut" or "Copy"
      map("n", operator .. operator, function()
        local line = vim.fn.line(".")
        hold(bufnr, line, line + vim.v.count1 - 1)
      end, ("%s the change"):format(what))
      map("x", operator, function()
        if vim.fn.mode() == "V" then
          hold(bufnr, selected_lines())
        else
          vim.api.nvim_feedkeys(operator, "n", false)
        end
      end, ("%s the selected changes"):format(what))
    end

    -- `ad` is a change with its descendants, and `od` only its descendants.
    for keys, with_change in pairs({ ad = true, od = false }) do
      vim.keymap.set("o", keys, function()
        local hold = ({ d = jj.cut_descendants, y = jj.copy_descendants })[vim.v.operator]
        local line = vim.fn.line(".")
        if hold then
          vim.schedule(function() hold(bufnr, line, with_change) end)
        end
        return "<Esc>"
      end, {
        buffer = bufnr,
        expr = true,
        desc = with_change and "The change and its descendants"
          or "The change's descendants",
      })
    end

    -- Without cut or copied changes, `p` and `P` paste text into the
    -- subjects.
    for keys, position in pairs({ p = "below", P = "above" }) do
      map("n", keys, function()
        if jj.has_held(bufnr) then
          jj.paste(bufnr, vim.fn.line("."), position, false)
        else
          local count = vim.v.count > 0 and tostring(vim.v.count) or ""
          local register = '"' .. vim.v.register
          vim.api.nvim_feedkeys(register .. count .. keys, "n", false)
        end
      end, ("Paste the cut or copied changes %s the change"):format(
        position
      ))
      map(
        "n",
        "g" .. keys,
        function() jj.paste(bufnr, vim.fn.line("."), position, true) end,
        ("Paste the cut or copied changes %s the change, on a new branch"):format(
          position
        )
      )
    end

    map(
      "n",
      "u",
      function() jj.undo(bufnr) end,
      "Undo the last graph operation"
    )
    map(
      "n",
      "<C-r>",
      function() jj.redo(bufnr) end,
      "Redo the last undone graph operation"
    )
    map(
      "n",
      "<CR>",
      function() jj.check_out(bufnr, vim.fn.line(".")) end,
      "Check out the change"
    )
    map(
      "n",
      "F",
      function() jj.fetch(bufnr) end,
      "Fetch the remote's bookmarks"
    )
    map(
      "n",
      "B",
      function() jj.edit_bookmark(bufnr, vim.fn.line(".")) end,
      "Create, rename or delete the change's bookmark"
    )
    for _, branch in ipairs({ false, true }) do
      map(
        { "n", "x" },
        (branch and "g" or "") .. "U",
        function()
          local first, last = selected_lines()
          jj.push(bufnr, first, last, branch)
        end,
        ("Push the selected changes%s"):format(
          branch and " on a new branch" or ""
        )
      )
    end
  end,
})

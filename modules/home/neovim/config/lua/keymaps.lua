local fzf_lua = require("fzf-lua")
local terminal = require("terminal")
local trouble = require("trouble")
local utils = require("utils")

local keymap = vim.keymap

--- @param key string
local fallback = function(key)
  local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end

-- Either quit Neovim, close a window or delete a buffer based on the current
-- context.
local close = function()
  if not vim.bo.buflisted then
    vim.cmd("q")
    return
  end

  local splits = vim
    .iter(vim.api.nvim_tabpage_list_wins(0))
    :filter(function(win) return vim.fn.win_gettype(win) == "" end)
    :totable()

  local current_buf = vim.api.nvim_get_current_buf()

  local other_listed_bufs = vim
    .iter(vim.api.nvim_list_bufs())
    :filter(
      function(buf)
        return buf ~= current_buf
          and vim.api.nvim_buf_is_valid(buf)
          and vim.bo[buf].buflisted
      end
    )
    :totable()

  local base_terminal = terminal.get_base()

  if current_buf == base_terminal and #other_listed_bufs > 0 then
    local switch_buf = vim
      .iter(other_listed_bufs)
      :fold(nil, function(most_recent, buf)
        if not most_recent then return buf end
        local lastused = vim.fn.getbufinfo(buf)[1].lastused
        local most_recent_lastused = vim.fn.getbufinfo(most_recent)[1].lastused
        return lastused > most_recent_lastused and buf or most_recent
      end)

    vim.bo[current_buf].buflisted = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == current_buf then
        vim.api.nvim_win_set_buf(win, switch_buf)
      end
    end
    return
  end

  local all_splits_are_showing_this_buffer = vim.iter(splits):all(
    function(win) return vim.api.nvim_win_get_buf(win) == current_buf end
  )

  if #splits > 1 and all_splits_are_showing_this_buffer then
    vim.cmd("q")
    return
  end

  local has_other_listed_file_buffer = #other_listed_bufs > 0
  local can_return_to_base_terminal = base_terminal
    and base_terminal ~= current_buf

  if
    #splits == 1
    and not has_other_listed_file_buffer
    and not can_return_to_base_terminal
  then
    vim.cmd("q")
    return
  end

  if not has_other_listed_file_buffer and can_return_to_base_terminal then
    vim.bo[base_terminal].buflisted = true
  end

  local force_delete = vim.bo.buftype == "terminal"

  -- Use `Bdelete` from `https://github.com/famiu/bufdelete.nvim` if available
  -- to avoid messing w/ the window layout.
  local has_bufdelete, bufdelete = pcall(require, "bufdelete")

  if not has_bufdelete then
    vim.cmd(force_delete and "bdelete!" or "bdelete")
  else
    local switchable_bufs = not has_other_listed_file_buffer
        and can_return_to_base_terminal
        and { base_terminal }
      or nil

    bufdelete.bufdelete(0, force_delete, switchable_bufs)
  end

  if vim.api.nvim_get_current_buf() == base_terminal then
    vim.cmd.startinsert()
  end
end

---@enum Direction
local direction = {
  Up = "k",
  Down = "j",
  Left = "h",
  Right = "l",
}

-- Open a new split window in a given direction and run a command in it.
--
---@param dir Direction
---@param cmd string?
local open_split = function(dir, cmd)
  local is_vertical = dir == direction.Up or dir == direction.Down

  local split = is_vertical and "split" or "vsplit"

  -- Splitting will move the cursor to the new window, so we move it
  -- back to the previous one before moving in the desired direction. This
  -- way it doesn't matter what the values of `splitbelow` and `splitright`
  -- are.
  local split_cmd = split .. " | wincmd p | wincmd " .. dir

  if cmd then split_cmd = split_cmd .. " | " .. cmd end

  return function() vim.cmd(split_cmd) end
end

-- Disable `s`.
keymap.set({ "n", "v" }, "s", "")

-- Save the file.
keymap.set({ "n", "v" }, "<D-s>", utils.buffer.save)

-- Close the current buffer/window.
keymap.set("n", "<D-w>", close)

-- Close or hide the current terminal buffer.
keymap.set("t", "<D-w>", function()
  if vim.b.terminal_shell_prompt_active then
    close()
  else
    fallback("<D-w>")
  end
end)

-- Scroll up/down by half a page.
keymap.set({ "n", "v" }, "<D-Up>", "<C-u>")
keymap.set({ "n", "v" }, "<D-Down>", "<C-d>")

-- Jump to the first non-whitepspace character in the displayed line.
keymap.set({ "n", "v" }, "<D-Left>", "g^")
keymap.set("i", "<D-Left>", "<C-o>g^")

-- Jump to the end of the displayed line.
keymap.set({ "n", "v" }, "<D-Right>", "g$")
keymap.set("i", "<D-Right>", "<C-o>g$")

-- Move between displayed lines instead of physical ones (i.e. take count of
-- soft-wrapping).
keymap.set({ "n", "v" }, "<Up>", "g<Up>", { noremap = true })
keymap.set({ "n", "v" }, "<Down>", "g<Down>", { noremap = true })
keymap.set("i", "<Up>", "<C-o>g<Up>", { noremap = true })
keymap.set("i", "<Down>", "<C-o>g<Down>", { noremap = true })

-- Open a new split window in the given direction.
keymap.set("n", "s<Up>", open_split(direction.Up))
keymap.set("n", "s<Down>", open_split(direction.Down))
keymap.set("n", "s<Left>", open_split(direction.Left))
keymap.set("n", "s<Right>", open_split(direction.Right))

-- Navigate window splits.
keymap.set({ "n", "v" }, "<S-Up>", "<C-w>k", { noremap = true })
keymap.set({ "n", "v" }, "<S-Down>", "<C-w>j", { noremap = true })
keymap.set({ "n", "v" }, "<S-Left>", "<C-w>h", { noremap = true })
keymap.set({ "n", "v" }, "<S-Right>", "<C-w>l", { noremap = true })

-- Jump to the beginning/end of the line in command mode.
keymap.set("c", "<D-Left>", "<C-b>")
keymap.set("c", "<D-Right>", "<C-e>")

-- Navigate to the next/previous diagnostic.
keymap.set(
  "n",
  "dn",
  function() vim.diagnostic.jump({ count = 1, float = true }) end
)
keymap.set(
  "n",
  "dN",
  function() vim.diagnostic.jump({ count = -1, float = true }) end
)

--·Clear·the current search·result¬.
keymap.set("n", "<Esc>", "<Cmd>noh<Cr>")

-- Delete the previous word in insert mode.
keymap.set("i", "<M-BS>", "<C-w>", { noremap = true })

-- Indent while remaining in visual mode.
keymap.set("v", ">", ">gv")
keymap.set("v", "<", "<gv")

-- Substitute globally and in the visually selected region.
keymap.set("n", "ss", ":%s///g<Left><Left><Left>")
keymap.set("v", "ss", ":s///g<Left><Left><Left>")

-- Display diagnostics in a floating window.
keymap.set("n", "?", vim.diagnostic.open_float)

-- Escape terminal mode.
keymap.set("t", "<D-Esc>", "<C-\\><C-n>", { noremap = true })

-- Escape terminal mode if the terminal is displaying the shell's prompt, or
-- re-emit the same key event for the child TUI to consume otherwise.
keymap.set(
  "t",
  "<Esc>",
  function()
    return vim.b.terminal_shell_prompt_active and "<C-\\><C-n>" or "<C-\\><Esc>"
  end,
  { expr = true, noremap = true }
)

-- Open a terminal in the current window.
keymap.set("n", "tt", function() vim.cmd("terminal") end)

-- Open a terminal in a new split window.
local open_terminal = function(dir) return open_split(dir, "terminal") end

keymap.set("n", "t<Up>", open_terminal(direction.Up))
keymap.set("n", "t<Down>", open_terminal(direction.Down))
keymap.set("n", "t<Left>", open_terminal(direction.Left))
keymap.set("n", "t<Right>", open_terminal(direction.Right))

-- Open the punchclock.
keymap.set("n", "<D-p>", function() vim.fn.jobstart("pc") end)

-- Open today's todo.
keymap.set("n", "td", function() vim.fn.jobstart("td") end)

-- Open tomorrow's todo.
keymap.set("n", "tm", function() vim.fn.jobstart("tm") end)

-- Open this week's todo.
keymap.set("n", "tw", function() vim.fn.jobstart("tw") end)

vim.api.nvim_set_keymap("n", "q", "", {
  desc = "Close the quickfix window with 'q'",
  callback = function()
    if vim.bo.buftype == "quickfix" then
      vim.cmd("cclose")
    else
      fallback("q")
    end
  end,
})

local fzf_opts = {
  ["--multi"] = true,
  ["--reverse"] = true,
  ["--no-bold"] = true,
  ["--info"] = "inline",
  ["--hscroll-off"] = 50,
  ["--preview-window"] = table.concat({
    "sharp",
    "border-left",
  }, ","),
  ["--color"] = table.concat({
    "hl:-1:underline",
    "fg+:-1:regular:italic",
    "hl+:-1:underline:italic",
    "prompt:4:regular",
    "pointer:1",
  }, ","),
}

--- Opens a trouble.nvim with w/ the given entries in quickfix formats
--- (`:h setqflist).
---
---@param qf_entries string[]
local open_trouble_qf = function(qf_entries)
  if #qf_entries == 0 then return end

  local win = vim.api.nvim_get_current_win()
  vim.fn.setqflist(qf_entries, "r")
  trouble.open({
    mode = "quickfix",
    new = false,
    refresh = true,
  })
  vim.api.nvim_set_current_win(win)
end

--- Fuzzy searches files in the given directory, and opens the selected ones.
local fzf_files = function(search_root)
  local opts = vim.tbl_extend("force", fzf_opts, {
    ["--preview"] = ("preview %s/{}"):format(search_root),
    ["--prompt"] = "Open> ",
  })

  fzf_lua.fzf_exec(("lf-recursive %s"):format(search_root), {
    actions = {
      default = function(selected_paths)
        if #selected_paths == 0 then return end

        local qf_entries = {}

        for _, path in ipairs(selected_paths) do
          table.insert(qf_entries, {
            filename = vim.fs.joinpath(search_root, path),
          })
        end

        local first = table.remove(qf_entries, 1)
        vim.cmd(("edit %s"):format(first.filename))

        open_trouble_qf(qf_entries)
      end,
    },
    fzf_opts = opts,
  })
end

vim.api.nvim_set_keymap("n", "<D-e>", "", {
  desc = "Fuzzy find files in the current git repo",
  callback = function()
    local git_root =
      vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
    fzf_files(git_root or vim.env.HOME)
  end,
})

vim.api.nvim_set_keymap("n", "<D-h>", "", {
  desc = "Fuzzy find files in the home directory",
  callback = function() fzf_files(vim.env.HOME) end,
})

local fzf_live_ripgrep = function(search_root)
  local opts = vim.tbl_extend("force", fzf_opts, {
    ["--bind"] = "change:reload:rg-pattern {q}",
    ["--delimiter"] = ":",
    ["--disabled"] = true,
    ["--preview"] = ("rg-preview %s/{1}:{2}"):format(search_root),
    ["--preview-window"] = "+{2}-/2",
    ["--prompt"] = "Rg> ",
    ["--with-nth"] = "1,2,4..",
  })

  local query = function(query)
    -- I couldn't find any docs on what query's type is, but AFAICT it's always
    -- a table with a single element.
    local query = query[1]
    return ("rg-pattern %s %s"):format(
      vim.fn.shellescape(query),
      vim.fn.shellescape(search_root)
    )
  end

  fzf_lua.fzf_live(query, {
    actions = {
      default = function(selected_paths)
        if #selected_paths == 0 then return end

        local regex = "^([^:]*):([^:]*):([^:]*):.*$"
        local qf_entries = {}

        for _, item in ipairs(selected_paths) do
          local path, line, col = item:match(regex)
          table.insert(qf_entries, {
            filename = vim.fs.joinpath(search_root, path),
            lnum = tonumber(line),
            col = tonumber(col),
          })
        end

        local first = table.remove(qf_entries, 1)
        vim.cmd(("edit %s"):format(first.filename))
        vim.fn.cursor(first.lnum, first.col)

        open_trouble_qf(qf_entries)
      end,
    },
    exec_empty_query = true,
    fzf_opts = opts,
  })
end

vim.api.nvim_set_keymap("n", "<D-r>", "", {
  desc = "Execute a live ripgrep search in the current git repo",
  callback = function()
    local git_root =
      vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
    fzf_live_ripgrep(git_root or vim.env.HOME)
  end,
})

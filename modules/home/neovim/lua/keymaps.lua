local fzf_lua = require("fzf-lua")
local neotest = require("neotest")
local trouble = require("trouble")
local utils = require("utils")

local keymap = vim.keymap

-- Either quit Neovim, close a window or delete a buffer based on the current
-- context.
local close = function()
  -- Returns `true` if there's only one buffer left.
  local is_last_buffer = function()
    return #vim.fn.getbufinfo({ buflisted = 1 }) == 1
  end

  -- The current buffer filetype and buffer type.
  local filetype, buftype = vim.bo.filetype, vim.bo.buftype

  -- Use `Bdelete` from `https://github.com/famiu/bufdelete.nvim` if available
  -- to avoid messing w/ the window layout.
  local has_bufdelete, _ = pcall(require, "bufdelete")
  local bd = has_bufdelete and "Bdelete" or "bdelete"

  local cmd =
      (
        (filetype == "help" or buftype == "nofile" or is_last_buffer())
        and "q"
      )
      or (buftype == "terminal" and "bdelete!")
      or bd

  vim.cmd(cmd)
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

  if cmd then
    split_cmd = split_cmd .. " | " .. cmd
  end

  return function()
    vim.cmd(split_cmd)
  end
end

-- Disable `s`.
keymap.set({ "n", "v" }, "s", "")

-- Disable `<C-w>d`.
keymap.del("n", "<C-w>d")

-- Disable `<C-w><C-d>`.
keymap.del("n", "<C-w><C-d>")

-- Save the file.
keymap.set("n", "<C-s>", utils.buffer.save)

-- Close the current buffer/window.
keymap.set("n", "<C-w>", close)

-- Jump to the first non-whitepspace character in the displayed line.
keymap.set({ "n", "v" }, "<C-a>", "g^")
keymap.set("i", "<C-a>", "<C-o>g^")

-- Jump to the end of the displayed line.
keymap.set({ "n", "v" }, "<C-e>", "g$")
keymap.set("i", "<C-e>", "<C-o>g$")

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
keymap.set("n", "<S-Up>", "<C-w>k", { noremap = true })
keymap.set("n", "<S-Down>", "<C-w>j", { noremap = true })
keymap.set("n", "<S-Left>", "<C-w>h", { noremap = true })
keymap.set("n", "<S-Right>", "<C-w>l", { noremap = true })

-- Jump to the beginning of the line in command mode.
keymap.set("c", "<C-a>", "<C-b>")

-- Navigate to the next/previous diagnostic.
keymap.set("n", "dn", vim.diagnostic.goto_next)
keymap.set("n", "dN", vim.diagnostic.goto_prev)

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
-- TODO: this should be bound to Super + Esc
keymap.set("t", "<Esc>", "<C-\\><C-n>", { noremap = true })

-- Open a terminal in the current window.
keymap.set("n", "tt", function() vim.cmd("terminal") end)

-- Open a terminal in a new split window.
local open_terminal = function(dir)
  return open_split(dir, "terminal")
end

keymap.set("n", "t<Up>", open_terminal(direction.Up))
keymap.set("n", "t<Down>", open_terminal(direction.Down))
keymap.set("n", "t<Left>", open_terminal(direction.Left))
keymap.set("n", "t<Right>", open_terminal(direction.Right))

--- @param key string
local fallback = function(key)
  local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end

vim.api.nvim_set_keymap("n", "<D-t>", "", {
  desc = "Open a terminal window with the output of the current test",
  callback = function()
    neotest.output.open({ enter = true })

    -- Scroll to the bottom of the terminal window, which is usually where the
    -- error message is.
    --
    -- TODO: this is hacky, do it w/o a timer.
    vim.defer_fn(function() vim.cmd("normal! G") end, 20)
  end,
})

vim.api.nvim_set_keymap("n", "ll", "", {
  desc = "Open lf in a new floating terminal window",
  callback = function()
    require("lf").start()
  end,
})

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

vim.api.nvim_set_keymap("n", "<S-d>", "", {
  desc = "Open a trouble.nvim window with diagnostics for the current project",
  callback = function()
    local diagostics = trouble.get_items("diagnostics")

    if not diagostics or not next(diagostics) then
      vim.notify(
        "No diagnostic to jump to",
        vim.log.levels.WARN,
        { title = "trouble.nvim" }
      )
      return
    end

    trouble.open({
      mode = "diagnostics",
      new = true,
    })
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
  if #qf_entries == 0 then
    return
  end

  local win = vim.api.nvim_get_current_win()
  vim.fn.setqflist(qf_entries, "r")
  trouble.open({
    mode = "quickfix",
    new = false,
    refresh = true,
  });
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
        if #selected_paths == 0 then
          return
        end

        local qf_entries = {}

        for _, path in ipairs(selected_paths) do
          table.insert(qf_entries, {
            filename = vim.fs.joinpath(search_root, path)
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

vim.api.nvim_set_keymap("n", "<C-x><C-e>", "", {
  desc = "Fuzzy find files in the current git repo",
  callback = function()
    local git_root = vim.fn.systemlist(
      "git rev-parse --show-toplevel 2>/dev/null")[1]
    fzf_files(git_root or vim.env.HOME)
  end,
})

vim.api.nvim_set_keymap("n", "<C-x><C-f>", "", {
  desc = "Fuzzy find files in the home directory",
  callback = function()
    fzf_files(vim.env.HOME)
  end,
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
    return ("rg-pattern '%s' %s"):format(query or "", search_root)
  end

  fzf_lua.fzf_live(query, {
    actions = {
      default = function(selected_paths)
        if #selected_paths == 0 then
          return
        end

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

vim.api.nvim_set_keymap("n", "<C-x><C-r>", "", {
  desc = "Execute a live ripgrep search in the current git repo",
  callback = function()
    local git_root = vim.fn.systemlist(
      "git rev-parse --show-toplevel 2>/dev/null")[1]
    fzf_live_ripgrep(git_root or vim.env.HOME)
  end,
})

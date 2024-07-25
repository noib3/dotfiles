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
keymap.set("n", "<C-s>", "<Cmd>w<CR>")

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
keymap.set("n", "dn", vim.diagnostic.goto_prev)
keymap.set("n", "dN", vim.diagnostic.goto_next)

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

local cmp = require("cmp")
local fzf_lua = require("fzf-lua")
local luasnip = require("luasnip")
local neotab = require("neotab")
local neotest = require("neotest")

--- @param key string
local fallback = function(key)
  local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end

vim.api.nvim_set_keymap("i", "<Tab>", "", {
  desc = "Select next completion or jump to next snippet or fallback",
  callback = function()
    if cmp.visible() then
      cmp.select_next_item()
    elseif luasnip.jumpable(1) then
      luasnip.jump(1)
    else
      neotab.tabout()
    end
  end,
})

vim.api.nvim_set_keymap("i", "<S-Tab>", "", {
  desc = "Select previous completion or jump to previous snippet or fallback",
  callback = function()
    if cmp.visible() then
      cmp.select_prev_item()
    elseif luasnip.jumpable(-1) then
      luasnip.jump(-1)
    else
      fallback("<S-Tab>")
    end
  end,
})

vim.api.nvim_set_keymap("i", "<CR>", "", {
  desc = "Accept current completion or fallback",
  callback = function()
    if cmp.visible() and cmp.get_active_entry() then
      cmp.confirm({
        behavior = cmp.ConfirmBehavior.Replace,
        select = false,
      })
    else
      fallback("<CR>")
    end
  end,
})

vim.api.nvim_set_keymap("i", "<Esc>", "", {
  desc = "Close the completion menu, restoring the original text",
  callback = function()
    if cmp.visible() then
      cmp.abort()
    end
    fallback("<Esc>")
  end,
})

vim.api.nvim_set_keymap("i", "<D-Tab>", "", {
  desc = "Request completions at the current cursor position",
  callback = function()
    cmp.complete()
  end,
})

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

local fzf_opts = {
  ["--multi"] = true,
  ["--preview"] = "preview ~/{}",
  ["--prompt"] = "Edit> ",
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

--- Populates the quickfix list with the given file paths, and opens it.
---
---@param file_paths string[]
local open_qf_list = function(file_paths)
  if #file_paths == 0 then
    return
  end

  local fun = function(path) return { filename = path } end
  local qf_entries = vim.tbl_map(fun, file_paths)
  vim.fn.setqflist(qf_entries, "r")

  local win = vim.api.nvim_get_current_win()
  vim.cmd("copen")
  vim.api.nvim_set_current_win(win)
end

--- Fuzzy searches files in the given directory, and opens the selected ones.
local fzf_files = function(search_root)
  fzf_lua.fzf_exec(("lf-recursive %s"):format(search_root), {
    actions = {
      default = function(selected_paths)
        local full_paths = vim.tbl_map(function(path)
          return vim.fs.joinpath(search_root, path)
        end, selected_paths)

        local first = table.remove(full_paths, 1)

        if not first then
          return
        end

        vim.cmd(("edit %s"):format(first))

        open_qf_list(full_paths)
      end,
    },
    fzf_opts = fzf_opts,
  })
end

vim.api.nvim_set_keymap("n", "<C-x><C-e>", "", {
  desc = "Fuzzy find files in the current git repo",
  callback = function()
    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
    fzf_files(git_root or vim.env.HOME)
  end,
})

vim.api.nvim_set_keymap("n", "<C-x><C-f>", "", {
  desc = "Fuzzy find file in the home directory",
  callback = function()
    fzf_files(vim.env.HOME)
  end,
})

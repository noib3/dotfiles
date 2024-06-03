local has_bufdelete, _ = pcall(require, "bufdelete")

local diagnostic = vim.diagnostic

local keymap = vim.keymap

local direction = {
  Up = 1,
  Down = 2,
  Left = 3,
  Right = 4,
}

-- Open a new split window in a given direction and run a command in it.
local open_split = function(dir, cmd)
  local is_vertical = dir == direction.Up or dir == direction.Down

  local split = is_vertical and "split" or "vsplit"

  local hjkl =
      (dir == direction.Up and "k")
      or (dir == direction.Down and "j")
      or (dir == direction.Left and "h")
      or "l"

  -- Splitting will move the cursor to the new window, so we move it
  -- back to the previous one before moving in the desired direction. This
  -- way it doesn't matter what the values of `splitbelow` and `splitright`
  -- are.
  local split_cmd = split .. " | wincmd p | wincmd " .. hjkl

  if cmd then
    split_cmd = split_cmd .. " | " .. cmd
  end

  return function()
    vim.cmd(split_cmd)
  end
end


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



-- Disable `s`.
keymap.set({ "n", "v" }, "s", "")

-- Disable `<C-w>d`.
keymap.del("n", "<C-w>d")

-- Disable `<C-w><C-d>`.
keymap.del("n", "<C-w><C-d>")

-- Save the file
keymap.set("n", "<C-s>", "<Cmd>w<CR>")

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

-- Open a new split window.
keymap.set("n", "s<Up>", open_split(direction.Up))
keymap.set("n", "s<Down>", open_split(direction.Down))
keymap.set("n", "s<Left>", open_split(direction.Left))
keymap.set("n", "s<Right>", open_split(direction.Right))

-- Navigate window splits.
keymap.set("n", "<S-Up>", "<C-w>k", { noremap = true })
keymap.set("n", "<S-Down>", "<C-w>j", { noremap = true })
keymap.set("n", "<S-Left>", "<C-w>h", { noremap = true })
keymap.set("n", "<S-Right>", "<C-w>l", { noremap = true })

-- Delete the previou word in insert mode.
keymap.set("i", "<M-BS>", "<C-w>", { noremap = true })

-- Jump to the beginning of the line in command mode.
keymap.set("c", "<C-a>", "<C-b>")

-- Substitute globally and in the visually selected region.
keymap.set("n", "ss", ":%s///g<Left><Left><Left>")
keymap.set("v", "ss", ":s///g<Left><Left><Left>")

-- Display diagnostics in a floating window.
keymap.set("n", "?", diagnostic.open_float)

-- Navigate to the previous/next diagnostic.
keymap.set("n", "dp", diagnostic.goto_prev)
keymap.set("n", "dn", diagnostic.goto_next)

-- Escape terminal mode.
keymap.set("t", "<Esc>", "<C-\\><C-n>", { noremap = true })

keymap.set("n", "tt", function() vim.cmd("terminal") end)

-- Open a terminal in a new split window.
local open_terminal = function(dir)
  return open_split(dir, "terminal")
end

keymap.set("n", "t<Up>", open_terminal(direction.Up))
keymap.set("n", "t<Down>", open_terminal(direction.Down))
keymap.set("n", "t<Left>", open_terminal(direction.Left))
keymap.set("n", "t<Right>", open_terminal(direction.Right))

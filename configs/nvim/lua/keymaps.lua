local has_telescope, telescope = pcall("telescope")

vim.g.mapleader = ","

--- Closes a window or deletes a buffer or closes Neovim, in that order.
local close_ctx = function()
  vim.cmd("q")
end

local keymaps = {
  -- Disable "s".
  {
    mode = { "n", "v" },
    lhs = "s",
    rhs = "",
  },

  -- Save the file.
  {
    mode = "n",
    lhs = "<C-s>",
    rhs = "<Cmd>w<CR>",
  },

  -- Close the current context.
  {
    mode = "n",
    lhs = "<C-w>",
    rhs = close_ctx,
  },

  -- Jump to the first non-whitespace character in the displayed line.
  {
    mode = { "n", "v" },
    lhs = "<C-a>",
    rhs = "g^",
  },
  {
    mode = "i",
    lhs = "<C-a>",
    rhs = "<C-o>g^",
  },

  -- Move between displayed lines instead of logical ones, taking count of
  -- soft wrapping.
  {
    mode = { "n", "v" },
    lhs = "<Up>",
    rhs = "g<Up>",
    opts = {
      noremap = true,
    },
  },
  {
    mode = { "n", "v" },
    lhs = "<Down>",
    rhs = "g<Down>",
    opts = {
      noremap = true,
    },
  },
  {
    mode = "i",
    lhs = "<Up>",
    rhs = "<C-o>g<Up>",
    opts = {
      noremap = true,
    },
  },
  {
    mode = "i",
    lhs = "<Down>",
    rhs = "<C-o>g<Down>",
    opts = {
      noremap = true,
    },
  },

  -- Jump to end of the displayed line.
  {
    mode = { "n", "v" },
    lhs = "<C-e>",
    rhs = "g$",
  },
  {
    mode = "i",
    lhs = "<C-e>",
    rhs = "<C-o>g$",
  },

  -- Navigate window splits.
  {
    mode = "n",
    lhs = "<S-Up>",
    rhs = "<C-w>k",
    opts = {
      noremap = true,
    },
  },
  {
    mode = "n",
    lhs = "<S-Down>",
    rhs = "<C-w>j",
    opts = {
      noremap = true,
    },
  },
  {
    mode = "n",
    lhs = "<S-Left>",
    rhs = "<C-w>h",
    opts = {
      noremap = true,
    },
  },
  {
    mode = "n",
    lhs = "<S-Right>",
    rhs = "<C-w>l",
    opts = {
      noremap = true,
    },
  },

  -- Delete the previous word in insert mode.
  {
    mode = "n",
    lhs = "<M-BS>",
    rhs = "<C-w>",
    opts = {
      noremap = true,
    },
  },

  -- Escape terminal mode.
  {
    mode = "t",
    lhs = "<M-Esc>",
    rhs = "<C-\\><C-n>",
    opts = { noremap = true },
  },

  -- Substitute globally and in the visually selected region.
  {
    mode = "n",
    lhs = "ss",
    rhs = ":%s///g<Left><Left><Left>",
  },
  {
    mode = "v",
    lhs = "ss",
    rhs = ":s///g<Left><Left><Left>",
  },

  -- Display the diagnostics in a floating window.
  {
    mode = "n",
    lhs = "?",
    rhs = vim.diagnostic.open_float,
  },

  -- Navigate to the next/previous diagnostic
  {
    mode = "n",
    lhs = "dn",
    rhs = vim.diagnostic.goto_next,
  },
  {
    mode = "n",
    lhs = "dp",
    rhs = vim.diagnostic.goto_prev,
  },

  -- Display infos.
  {
    mode = "n",
    lhs = "K",
    rhs = vim.lsp.buf.hover,
  },

  -- Rename symbol.
  {
    mode = "n",
    lhs = "<leader>rn",
    rhs = vim.lsp.buf.rename,
  },

  -- Show code actions.
  {
    mode = "n",
    lhs = "<leader>ca",
    rhs = vim.lsp.buf.code_action,
  },

  -- Jump to variable definition.
  {
    mode = "n",
    lhs = "<leader>gd",
    rhs = vim.lsp.buf.definition,
  },

  -- Jump to type definition.
  {
    mode = "n",
    lhs = "<leader>gtd",
    rhs = vim.lsp.buf.type_definition,
  },
}

if has_telescope then
  local project_dir = function()
    local is_under_git = vim.fn.system("git status"):find("fatal") ~= nil
    if is_under_git then
      return vim.fn.systemlist("git rev-parse --show-toplevel")[0]
    else
      return vim.fn.expand("%:p:h")
    end
  end

  table.insert(keymaps, {})
end

return keymaps

return {
  {
    "voldikss/vim-floaterm",
    config = function()
      vim.g.floaterm_autoclose = 2
      vim.g.floaterm_height = 0.8
      vim.g.floaterm_opener = 'edit'
      vim.g.floaterm_title = ''
      vim.g.floaterm_width = 0.8
      vim.keymap.set("n", "lg", "<Cmd>FloatermNew lazygit<CR>", { silent = true })
    end,
  },
}

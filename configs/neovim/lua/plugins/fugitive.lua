return {
  {
    "tpope/vim-fugitive",
    config = function()
      vim.api.nvim_set_keymap("n", "<leader>gc", "<Cmd>Git commit<CR>", {
        desc = "Commit with fugitive",
      })
    end
  }
}

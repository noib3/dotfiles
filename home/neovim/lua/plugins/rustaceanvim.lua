return {
  {
    "mrcjkb/rustaceanvim",
    config = function()
      vim.g.rustaceanvim = {
        tools = {
          hover_actions = {
            replace_builtin_hover = false,
          }
        },
      }
    end
  }
}

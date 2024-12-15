return {
  {
    "saghen/blink.cmp",
    version = "v0.7.6",
    opts = {
      keymap = {
        preset = "enter",
      },
      sources = {
        default = { "lsp", "path" },
      },
      completion = {
        list = {
          selection = "manual",
        },
        menu = {
          auto_show = true,
          max_height = 7,
        },
        documentation = {
          auto_show = true,
        },
      },
    }
  }
}

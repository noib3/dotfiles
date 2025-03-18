return {
  {
    "rcarriga/nvim-notify",
    config = function()
      local notify = require("notify")
      notify.setup({
        fps = 60,
        max_width = 32,
        render = "wrapped-compact",
        stages = "slide",
        timeout = 2500,
      })
      vim.notify = notify
    end,
  }
}

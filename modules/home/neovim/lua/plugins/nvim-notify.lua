return {
  {
    "rcarriga/nvim-notify",
    config = function()
      local notify = require("notify")
      notify.setup({
        fps = 60,
        render = "default",
        stages = "static",
        timeout = 2500,
      })
      vim.notify = notify
    end,
  }
}

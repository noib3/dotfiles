local notify = require("notify")

-- nvim-notify annotates setup() with its resolved config, where every field is
-- required.
---@diagnostic disable-next-line: missing-fields, param-type-mismatch
notify.setup({
  fps = 60,
  render = "default",
  stages = "static",
  timeout = 2500,
})

-- `notify` is a callable table, which EmmyLua doesn't match against
-- `vim.notify`'s function type.
---@diagnostic disable-next-line: assign-type-mismatch
vim.notify = notify

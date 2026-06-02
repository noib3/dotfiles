local term = vim.env.TERM

if not term or term == "" then return end

local ex_cmd = require("vim._core.ex_cmd")
local ex_terminal = ex_cmd.ex_terminal

---Forward the outer TUI's terminal identity to jobs spawned by `:terminal`.
---@diagnostic disable-next-line: duplicate-set-field
ex_cmd.ex_terminal = function(...)
  local orig_jobstart = vim.fn.jobstart

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.fn.jobstart = function(cmd, opts)
    if type(opts) == "table" and opts.term then
      opts = vim.tbl_extend("force", opts, {
        env = vim.tbl_extend("force", opts.env or {}, { TERM = term }),
      })
    end
    return orig_jobstart(cmd, opts)
  end

  local ok, err = pcall(ex_terminal, ...)
  vim.fn.jobstart = orig_jobstart
  if not ok then error(err, 0) end
end

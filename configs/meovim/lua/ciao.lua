local api = vim.api

---@param name string
---@param opts table
---@return nil
local augroup = function(name, opts)
  local id = api.nvim_create_augroup(name, {})
  api.nvim_create_autocmd(
    opts.events,
    {
      group = id,
      pattern = opts.pattern,
      desc = opts.desc,
      command = opts.cmd,
      callback = opts.callback,
    }
  )
end

-- Rebalance splits automatically after resizing the terminal.
augroup(
  "RebalanceSplits",
  {
    events = "VimResized",
    pattern = "*",
    cmd = "wincmd =",
    desc = "Rebalances window splits after resizing the terminal",
  }
)

-- Reset the cursor on exit.
augroup(
  "ResetCursor",
  {
    events = { "VimLeave", "VimSuspend" },
    pattern = "*",
    cmd = "set guicursor=a:ver25",
    desc = "Resets the cursor to a vertical bar when exiting Neovim",
  }
)

-- Sets up the embedded terminal.
augroup(
  "SetupTerm",
  {
    events = "TermOpen",
    pattern = "*",
    desc = "Disables lines numbers and automatically enters insert mode",
    callback = function()
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.cmd("startinsert")
    end,
  }
)

local setup = function()
  -- Rebalance splits automatically after a terminal resize.
  _G.augroup({
    name = 'vim_resized',
    autocmds = {
      {
        event = 'VimResized',
        pattern = '*',
        cmd = 'wincmd =',
      },
    }
  })

  _G.augroup({
    name = 'termopen',
    autocmds = {
      -- Disable line numbers.
      {
        event = 'TermOpen',
        pattern = '*',
        cmd = 'setlocal nonumber norelativenumber',
      },
      -- Enter insert mode.
      {
        event = 'TermOpen',
        pattern = '*',
        cmd = 'startinsert',
      },
    }
  })
end

return {
  setup = setup,
}

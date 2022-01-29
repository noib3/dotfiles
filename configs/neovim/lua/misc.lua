local setup = function()
  -- Reset the cursor on exit
  _G.augroup({
    name = 'reset_cursor',
    autocmds = {
      {
        event = 'VimLeave,VimSuspend',
        pattern = '*',
        cmd = 'set guicursor=a:ver25',
      },
    }
  })

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

  -- Enable bash syntax for direnv's files.
  _G.augroup({
    name = 'direnv_bash',
    autocmds = {
      {
        event = 'BufRead,BufNewFile',
        pattern = '.envrc,.direnvrc,direnvrc',
        cmd = 'setfiletype=bash',
      },
    }
  })
end

return {
  setup = setup,
}

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

  -- Disable line numbers in terminal buffers.
  _G.augroup({
    name = 'termopen',
    autocmds = {
      {
        event = 'TermOpen',
        pattern = '*',
        cmd = 'setlocal nonumber norelativenumber',
      },
    }
  })
end

return {
  setup = setup,
}

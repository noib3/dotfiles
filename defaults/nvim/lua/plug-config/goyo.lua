local cmd = vim.cmd

vim.g.goyo_linenr = 1

function goyo_enter()
  cmd('hi! NonText guifg=#3b4048 guibg=NONE gui=NONE')
end

cmd('autocmd! User GoyoEnter nested lua goyo_enter()')

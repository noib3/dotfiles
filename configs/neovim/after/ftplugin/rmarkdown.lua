local b = vim.b
local fn = vim.fn
local cmd = vim.cmd
local opt = vim.opt_local
local bufmap = vim.api.nvim_buf_set_keymap

local format = string.format

opt.commentstring = '<!-- %s -->'
opt.foldcolumn = '0'
opt.foldenable = false
opt.spell = false
opt.spelllang = 'en_us,it'
opt.textwidth = 79

b.delimitMate_quotes = "\" ' ` *"

RMarkdown_preview = function()
  local html_filename = format('%s.html', fn.expand('%:p:r'))
  cmd(format([[call html#open('%s')]], html_filename))
end

local bookdown = {
  ip_address = 'localhost',
  port = '4321',
}

Bookdown = {}

Bookdown.serve = function()
  -- how the fuck do you make this shit work I'm losing my fucking mind

  -- cmd(format(
  --   [[silent execute '!Rscript -e "bookdown::serve_book()"']],
  --   format('daemon = TRUE, port = %s', port)
  -- ))

  -- cmd([[execute '!Rscript -e "bookdown::serve_book()"']])

  vim.api.nvim_echo(
    {{
      format(
        '[bookdown]: Started serving on %s:%s',
        bookdown.ip_address, bookdown.port
      ),
      'Normal',
    }}, true, {}
  )
end

Bookdown.preview = function()
  local book_root = format('http://%s:%s', bookdown.ip_address, bookdown.port)
  cmd(format([[call html#open('%s')]], book_root))
end

Bookdown.compile = function()
  cmd([[execute '!Rscript -e "bookdown::render_book(\"index.Rmd\", \"bookdown::pdf_book\")"']])
  vim.api.nvim_echo(
    {{
      '[bookdown]: Finished compiling',
      'Normal',
    }}, true, {}
  )
end

bufmap(0, 'n', '<C-t>', '<Cmd>RMarkdown<CR>', {})
bufmap(0, 'n', '<LocalLeader>rp', '<Cmd>lua RMarkdown_preview()<CR>', {silent = true})

bufmap(0, 'n', '<LocalLeader>p', '<Cmd>MarkdownPreview<CR>', {silent = true})
bufmap(0, 'n', '<LocalLeader>k', '<Cmd>MarkdownPreviewStop<CR>', {silent = true})

bufmap(0, 'n', '<LocalLeader>bs', '<Cmd>lua Bookdown.serve()<CR>', {})
bufmap(0, 'n', '<LocalLeader>bp', '<Cmd>lua Bookdown.preview()<CR>', {})
bufmap(0, 'n', '<LocalLeader>bc', '<Cmd>lua Bookdown.compile()<CR>', {})

cmd('call vimtex#init()')

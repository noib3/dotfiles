local vim_fn = vim.fn

-- _G.open_edits = function(...)
--   print(...)
-- end

-- _G.open_ripgreps = function(...)
--   print(...)
-- end

-- local open_edits = function(basedir, lines)
--   -- print(...)
-- end

-- local open_ripgreps = function(basedir, lines)
-- end

local fuzzy_edit = function()
end

local fuzzy_ripgrep = function()
  -- Piping ripgrep's output into sed to filter empty lines
  local query_format =
    'rg --column --color=always -- %s'
    .. " | sed '/.*:\\x1b\\[0m[0-9]*\\x1b\\[0m:$/d'"
    .. " || true"

  local initial_query = query_format:format(vim_fn.shellescape(''))
  local reload_query = query_format:format('{q}')

  -- let s:dir =
  --   \ system('git status') =~ '^fatal'
  --   \ ? expand('%:p:h')
  --   \ : systemlist('git rev-parse --show-toplevel')[0]

  local spec = {
    source = initial_query,
    options = {
      '--multi',
      '--prompt=Rg> ',
      '--disabled',
      '--delimiter=:',
      '--with-nth=1,2,4..',
      '--bind=change:reload:' .. reload_query,
      '--preview=rg-previewer {1,2}',
      '--preview-window=+{2}-/2',
    },
    -- dir = dir,
    sinklist = function(...) print(...) end,
    -- 'sinklist': function('<SID>open_ripgreps', [s:dir]),
  }

  vim_fn['fzf#run'](vim_fn['fzf#wrap'](spec))
end

return {
  fuzzy_edit = fuzzy_edit,
  fuzzy_ripgrep = fuzzy_ripgrep,
}

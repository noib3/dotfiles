local map = vim.api.nvim_set_keymap

-- map('i', '<Tab>', '<Cmd>lua return require"snippets".expand_or_advance(1)<CR>', {noremap=true})
-- map('i', '<S-Tab>', '<Cmd>lua return require"snippets".advance_snippet(-1)<CR>', {noremap=true})

require('snippets').snippets = {
  _global = {
    she = "#!/usr/bin/env bash\n";
  };

  python = {
    she = "#!/usr/bin/env python3\n";
  };
}

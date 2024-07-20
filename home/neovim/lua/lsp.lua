local keymap = vim.keymap

local lsp_group = vim.api.nvim_create_augroup("noib3/format-buffer", {})

local on_attach = function(_ --[[ client ]], bufnr)
  local opts = { buffer = bufnr }

  -- Display infos about the symbol under the cursor in a floating window.
  keymap.set("n", "K", vim.lsp.buf.hover, opts)

  -- Rename the symbol under the cursor.
  keymap.set("n", "grn", vim.lsp.buf.rename, opts)

  -- Selects a code action available at the current cursor position.
  keymap.set("n", "gca", vim.lsp.buf.code_action, opts)

  -- Jumps to the definition of the symbol under the cursor.
  keymap.set("n", "gd", vim.lsp.buf.definition, opts)

  -- Jumps to the definition of the type of the symbol under the cursor.
  keymap.set("n", "gtd", vim.lsp.buf.type_definition, opts)

  -- Format buffer on save w/ a 1s timeout.
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = lsp_group,
    buffer = bufnr,
    desc = "Formats the buffer before saving it to disk",
    callback = function() vim.lsp.buf.format({}, 1000) end,
  })
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_group,
  desc = "Set up LSP environment on a buffer",
  callback = function(args)
    local client
    vim.lsp.get_client_by_id(args.data.client_id)
    on_attach(client, args.buffer)
  end,
})

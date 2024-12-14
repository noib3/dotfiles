local keymap = vim.keymap
local methods = vim.lsp.protocol.Methods

local lsp_group = vim.api.nvim_create_augroup("noib3/lsp", {})

local on_attach = function(client, bufnr)
  local opts = { buffer = bufnr }

  -- Format buffer on save.
  if client.supports_method(methods.textDocument_formatting) then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = lsp_group,
      buffer = bufnr,
      desc = "Formats the buffer before saving it to disk",
      callback = function() vim.lsp.buf.format({ async = true }) end,
    })
  end

  -- Display infos about the symbol under the cursor in a floating window.
  if client.supports_method(methods.textDocument_hover) then
    keymap.set("n", "K", vim.lsp.buf.hover, opts)
  end

  -- Rename the symbol under the cursor.
  if client.supports_method(methods.textDocument_rename) then
    local inc_rename = function()
      return ":IncRename " .. vim.fn.expand("<cword>")
    end
    keymap.set("n", "R", inc_rename, { expr = true, buffer = bufnr })
  end

  -- Selects a code action available at the current cursor position.
  if client.supports_method(methods.textDocument_codeAction) then
    keymap.set("n", "A", vim.lsp.buf.code_action, opts)
  end

  -- Jumps to the definition of the symbol under the cursor.
  if client.supports_method(methods.textDocument_definition) then
    keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  end

  -- Jumps to the definition of the type of the symbol under the cursor.
  if client.supports_method(methods.textDocument_typeDefinition) then
    keymap.set("n", "gtd", vim.lsp.buf.type_definition, opts)
  end
end

local on_detach = function(client, bufnr)
  -- Remove the autocommand that formats the buffer on save.
  if client.supports_method(methods.textDocument_formatting) then
    vim.api.nvim_clear_autocmds({
      event = "BufWritePre",
      group = lsp_group,
      buffer = bufnr,
    })
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_group,
  desc = "Set up LSP environment on a buffer",
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    on_attach(client, args.buf)
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  group = lsp_group,
  desc = "Remove LSP autocommands/keymaps on a buffer",
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    on_detach(client, args.buf)
  end,
})

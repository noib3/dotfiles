local rust = require("diagnostic.rust")
local utils = require("utils")

local default_underline_show = assert(vim.diagnostic.handlers.underline.show)
local default_underline_hide = assert(vim.diagnostic.handlers.underline.hide)
local default_virtual_text_show =
  assert(vim.diagnostic.handlers.virtual_text.show)
local default_virtual_text_hide =
  assert(vim.diagnostic.handlers.virtual_text.hide)

vim.diagnostic.handlers.underline = {
  show = function(namespace, bufnr, diagnostics, opts)
    local from_rust, rest = utils.lua.split_table(diagnostics, rust.is_about)
    rust.handlers.underline.show(namespace, bufnr, from_rust, opts)
    default_underline_show(namespace, bufnr, rest, opts)
  end,
  hide = function(namespace, bufnr)
    rust.handlers.underline.hide(namespace, bufnr)
    default_underline_hide(namespace, bufnr)
  end,
}

vim.diagnostic.handlers.virtual_text = {
  show = function(namespace, bufnr, diagnostics, opts)
    local from_rust, rest = utils.lua.split_table(diagnostics, rust.is_about)
    rust.handlers.virtual_text.show(namespace, bufnr, from_rust, opts)
    default_virtual_text_show(namespace, bufnr, rest, opts)
  end,
  hide = function(namespace, bufnr)
    rust.handlers.virtual_text.hide(namespace, bufnr)
    default_virtual_text_hide(namespace, bufnr)
  end,
}

vim.diagnostic.config({
  severity_sort = true,
  signs = false,
})

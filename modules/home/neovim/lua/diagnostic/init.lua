local utils = require("utils")
local rust = require("diagnostic.rust")

local default_underline_handler = vim.diagnostic.handlers.underline

vim.diagnostic.handlers.underline = {
  show = function(namespace, bufnr, diagnostics, opts)
    local from_rust, rest = utils.split_table(diagnostics, rust.is_about)
    rust.handlers.underline.show(namespace, bufnr, from_rust, opts)
    default_underline_handler.show(namespace, bufnr, rest, opts)
  end,
  hide = function(namespace, bufnr)
    rust.handlers.underline.hide(namespace, bufnr)
    default_underline_handler.hide(namespace, bufnr)
  end,
}

vim.diagnostic.config({
  severity_sort = true,
  signs = false,
})

local utils = require("utils")

local default_underline_handler = vim.diagnostic.handlers.underline
local default_virtual_text_handler = vim.diagnostic.handlers.virtual_text

--- Returns whether the diagnostic is about inactive code.
---@param diagnostic vim.Diagnostic
---@return boolean
local is_inactive_code = function(diagnostic)
  return diagnostic.code == "inactive-code"
end

--- Opposite of `is_inactive_code`.
---@param diagnostic vim.Diagnostic
---@return boolean
local is_active_code = function(diagnostic)
  return not is_inactive_code(diagnostic)
end

--- Fades out a range of text by blending the fg color with 25% of the bg
--- color.
local fade_out = function(namespace, bufnr, lnum, col, end_lnum, end_col)
  -- There's currently no sane way to get the rendered fg color in a range of
  -- text. You have to get all the syntax groups, treesitter nodes, semantic
  -- tokens and extmarks in a range, sort them by priority, and get the
  -- highlight group with the highest priority (following links).
  -- That's retarded.

  local ns = vim.diagnostic.get_namespace(namespace)
  if not ns.user_data.underline_ns then
    ns.user_data.underline_ns =
        vim.api.nvim_create_namespace(string.format("%s/diagnostic/underline", ns.name))
  end

  vim.hl.range(
    bufnr,
    ns.user_data.underline_ns,
    "DiagnosticUnnecessary",
    { lnum, col },
    { end_lnum, end_col },
    { priority = 150 }
  )
end

local M = {}

--- Check if a diagnostic is about rust.
---@param diagnostic vim.Diagnostic
---@return boolean
M.is_about = function(diagnostic)
  local rust_sources = { "clippy", "rustc", "rust-analyzer" }
  return vim.tbl_contains(rust_sources, diagnostic.source)
end

M.handlers = {}

M.handlers.underline = {
  show = function(namespace, bufnr, diagnostics, opts)
    local inactives, rest = utils.lua.split_table(diagnostics, is_inactive_code)

    -- rust-analyzer marks unused code as unnecessary, which causes Neovim to
    -- highlight it as `DiagnosticUnnecessary`.
    --
    -- I want unused code to be highlighted as a regular warning, so let's
    -- remove the corresponding tag.
    for _, diagnostic in ipairs(rest) do
      if diagnostic._tags then
        diagnostic._tags.unnecessary = nil
      end
    end

    default_underline_handler.show(namespace, bufnr, rest, opts)

    for _, d in ipairs(inactives) do
      fade_out(namespace, bufnr, d.lnum, d.col, d.end_lnum, d.end_col)
    end
  end,
  hide = function(namespace, bufnr)
    default_underline_handler.hide(namespace, bufnr)
  end,
}

M.handlers.virtual_text = {
  show = function(namespace, bufnr, diagnostics, opts)
    -- Don't display virtual text for inactive code.
    local active_diagnostics = vim.tbl_filter(is_active_code, diagnostics)

    -- Save the original messages. We'll restore them after displaying the
    -- virtual text to let the other handlers operate on the original messages.
    local orig_messages = {}

    -- Only display the first line of the diagnostic message in the virtual
    -- text to reduce clutter. The rest can be read by opening the float.
    for idx, diagnostic in ipairs(active_diagnostics) do
      orig_messages[idx] = diagnostic.message
      diagnostic.message = diagnostic.message:match("^[^\n]*")
    end
    default_virtual_text_handler.show(namespace, bufnr, active_diagnostics, opts)

    for idx, diagnostic in ipairs(active_diagnostics) do
      diagnostic.message = orig_messages[idx]
    end
  end,
  hide = function(namespace, bufnr)
    default_virtual_text_handler.hide(namespace, bufnr)
  end,
}

return M

local lsp_progress = require("lsp-progress")
local lualine = require("lualine")
local utils = require("utils")

--- Returns diagnostic counts across all the LSP clients attached to the current
--- buffer.
---@return { error: integer, warn: integer, info: integer, hint: integer }
local current_workspace_diagnostics = function()
  local workspace_namespaces = vim
    .iter(vim.lsp.get_clients({ bufnr = 0 }))
    :fold({}, function(acc, client)
      acc[vim.lsp.diagnostic.get_namespace(client.id)] = true
      client:_provider_foreach("textDocument/diagnostic", function(cap)
        local identifier = type(cap) == "table" and cap.identifier or "nil"
        acc[vim.lsp.diagnostic.get_namespace(client.id, true, identifier)] =
          true
      end)
      return acc
    end)

  if vim.tbl_isempty(workspace_namespaces) then
    return { error = 0, warn = 0, info = 0, hint = 0 }
  end

  local counts = { 0, 0, 0, 0 }

  for _, diagnostic in ipairs(vim.diagnostic.get()) do
    if workspace_namespaces[diagnostic.namespace] then
      local severity = diagnostic.severity
      counts[severity] = counts[severity] + 1
    end
  end

  return {
    error = counts[vim.diagnostic.severity.ERROR],
    warn = counts[vim.diagnostic.severity.WARN],
    info = counts[vim.diagnostic.severity.INFO],
    hint = counts[vim.diagnostic.severity.HINT],
  }
end

lualine.setup({
  options = {
    component_separators = "",
    globalstatus = true,
    ignore_focus = function(win)
      local buf = vim.api.nvim_win_get_buf(win)
      return vim.bo[buf].buftype ~= ""
    end,
    section_separators = "",
    -- Returns the theme table with colors sourced from the current
    -- highlights. This is a function so lualine re-evaluates it on
    -- ColorScheme/OptionSet.
    theme = function()
      local colors = {
        bg = utils.highlights.bg_of("StatusLine"),
        fg = utils.highlights.fg_of("StatusLine"),
      }
      local modes = { a = colors, b = colors, c = colors }
      return {
        normal = modes,
        insert = modes,
        visual = modes,
        replace = modes,
        command = modes,
        inactive = modes,
      }
    end,
  },
  sections = {
    lualine_a = {
      lsp_progress.progress,
    },
    lualine_b = {
      {
        "diagnostics",
        diagnostics_color = {
          error = "DiagnosticError",
          warn = "DiagnosticWarn",
        },
        sections = { "error", "warn" },
        sources = { current_workspace_diagnostics },
        symbols = { error = " ", warn = " " },
      },
    },
    lualine_c = {},
    lualine_x = {},
    lualine_y = {
      "selectioncount",
      "searchcount",
    },
    lualine_z = {
      {
        "branch",
        color = {
          ---@diagnostic disable-next-line: undefined-field
          fg = vim.opt.background:get() == "dark" and "#928374" or "#7c6f64",
        },
      },
    },
  },
})

-- Refresh lualine when the LSP progress status is updated.
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("noib3/lualine", { clear = true }),
  pattern = "LspProgressStatusUpdated",
  callback = lualine.refresh --[[@as fun()]],
})

vim.api.nvim_create_autocmd(
  { "BufEnter", "DiagnosticChanged", "LspAttach", "LspDetach" },
  {
    group = vim.api.nvim_create_augroup(
      "noib3/lualine-diagnostics",
      { clear = true }
    ),
    callback = lualine.refresh --[[@as fun()]],
  }
)

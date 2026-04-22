local luacheck = require("lint").linters.luacheck

local methods = vim.lsp.protocol.Methods

--- Converts a list of `vim.Diagnostic`s into LSP-formatted diagnostics.
---@param diagnostics vim.Diagnostic[]
---@return lsp.Diagnostic[]
local to_lsp_diagnostics = function(diagnostics)
  return vim
    .iter(diagnostics)
    :map(
      function(d)
        return {
          range = {
            start = { line = d.lnum, character = d.col },
            ["end"] = {
              line = d.end_lnum or d.lnum,
              character = d.end_col or d.col,
            },
          },
          severity = d.severity,
          code = d.code,
          source = d.source,
          message = d.message,
        }
      end
    )
    :totable()
end

--- Runs luacheck on a buffer's contents and returns diagnostics via callback.
--- luacheck searches for .luacheckrc starting from the current working
--- directory, so we run it from the project root.
---@param bufnr integer
---@param cwd string
---@param callback fun(diagnostics: lsp.Diagnostic[])
local run_luacheck = function(bufnr, cwd, callback)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    callback({})
    return
  end

  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then
    callback({})
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local contents = table.concat(lines, "\n") .. "\n"

  vim.system(
    {
      luacheck.cmd,
      "--formatter",
      "plain",
      "--codes",
      "--ranges",
      "--filename",
      filepath,
      "-",
    },
    { stdin = contents, text = true, cwd = cwd },
    vim.schedule_wrap(function(result)
      -- Exit code 0 = no warnings, 1 = warnings, 2 = errors.
      -- Any other exit code means luacheck itself failed.
      if result.code ~= 0 and result.code ~= 1 and result.code ~= 2 then
        callback({})
        return
      end

      local diagnostics = luacheck.parser(result.stdout or "", bufnr, "")
      callback(to_lsp_diagnostics(diagnostics))
    end)
  )
end

local handlers = {}

handlers[methods.initialize] = function(_, callback)
  callback(nil, {
    capabilities = {
      diagnosticProvider = {
        interFileDependencies = false,
        workspaceDiagnostics = false,
      },
      -- Needed so the client sends textDocument/didChange notifications, which
      -- trigger the LspNotify autocmd that drives diagnostic refresh.
      textDocumentSync = {
        openClose = true,
        change = 1, -- Full
      },
    },
  })
end

handlers[methods.shutdown] = function(_, callback) callback(nil, nil) end

---@type vim.lsp.Config
return {
  filetypes = { "lua" },
  -- Only activate if luacheck is in $PATH and a .luacheckrc exists in an
  -- ancestor directory.
  root_dir = function(bufnr, on_dir)
    if vim.fn.executable(luacheck.cmd) ~= 1 then return end
    local root = vim.fs.root(bufnr, ".luacheckrc")
    if root then on_dir(root) end
  end,
  --- @param _ vim.lsp.rpc.Dispatchers
  --- @param config vim.lsp.ClientConfig
  cmd = function(_, config)
    local root_dir = assert(config.root_dir)

    local handlers = vim.tbl_extend("force", handlers, {
      [methods.textDocument_diagnostic] = function(params, callback)
        local uri = params and params.textDocument and params.textDocument.uri

        if not uri then
          callback(nil, { kind = "full", items = {} })
          return
        end

        run_luacheck(
          vim.uri_to_bufnr(uri),
          root_dir,
          function(diagnostics)
            callback(nil, { kind = "full", items = diagnostics })
          end
        )
      end,
    })

    local next_request_id = 0

    return {
      request = function(method, params, callback, notify_reply_callback)
        local request_id = next_request_id
        next_request_id = next_request_id + 1
        if handlers[method] then handlers[method](params, callback) end
        if notify_reply_callback then notify_reply_callback(request_id) end
        return true, request_id
      end,
      notify = function() return true end,
      is_closing = function() return false end,
      terminate = function() end,
    }
  end,
}

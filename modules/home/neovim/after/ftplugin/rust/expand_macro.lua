local cursor_is_on_macro_invocation = function()
  local node = vim.treesitter.get_node()
  if not node or node:type() ~= "identifier" then return false end

  local parent = node:parent()
  if not parent then return false end

  -- Function-like macro, e.g. `println!(..)`, `vec![..]`, etc.
  -- Tree path: macro_invocation > identifier
  if parent:type() == "macro_invocation" then return true end

  -- Derive macro, e.g. `Clone` in `#[derive(Clone)]`.
  -- Tree path: attribute > token_tree > identifier
  if parent:type() == "token_tree" then
    local attr = parent:parent()
    if attr and attr:type() == "attribute" then
      local attr_name = attr:named_child(0)
      return attr_name
          and attr_name:type() == "identifier"
          and vim.treesitter.get_node_text(attr_name, 0) == "derive"
    end
  end

  -- Attribute macro, e.g. `#[async_trait]`, `#[tokio::main]`, etc.
  -- Tree path: attribute > identifier
  -- Tree path: attribute > scoped_identifier > identifier
  --
  -- Scoped attributes (e.g. `tokio::main`) are almost always proc macros, so
  -- we only filter non-scoped ones against a list of known non-macro attributes
  -- and macros that R-A can't expand (e.g. `test`).
  if parent:type() == "attribute" then
    local non_macro_attrs = {
      "allow", "cfg", "cfg_attr", "cold", "deny", "deprecated", "derive", "doc",
      "expect", "forbid", "ignore", "inline", "link", "must_use", "no_mangle",
      "non_exhaustive", "repr", "serde", "target_feature", "test", "warn",
    }
    local attr_name = vim.treesitter.get_node_text(node, 0)
    return not vim.tbl_contains(non_macro_attrs, attr_name)
  end
  if parent:type() == "scoped_identifier" then
    local grandparent = parent:parent()
    if grandparent and grandparent:type() == "attribute" then return true end
  end

  return false
end

---@param bufnr integer
---@param client vim.lsp.Client
local do_expand = function(bufnr, client)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = cursor[1] - 1, character = cursor[2] },
  }

  ---@diagnostic disable-next-line: param-type-mismatch
  client:request("rust-analyzer/expandMacro", params, function(err, result)
    if err or not result or not result.expansion or result.expansion == "" then
      vim.notify("No macro expansion available", vim.log.levels.INFO)
      return
    end

    local title = "Recursive expansion of the `" .. result.name .. "` macro."
    local lines = {
      "// " .. title,
      "// " .. string.rep("=", #title),
      "",
    }
    vim.list_extend(lines,
      vim.split(result.expansion, "\n", { trimempty = true }))

    local scratch = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(scratch, 0, -1, false, lines)
    vim.bo[scratch].filetype = "rust"
    vim.bo[scratch].buftype = "nofile"
    vim.bo[scratch].bufhidden = "wipe"
    vim.bo[scratch].modifiable = false

    local max_width = 0
    for _, line in ipairs(lines) do
      max_width = math.max(max_width, #line)
    end

    vim.api.nvim_open_win(scratch, true, {
      relative = "cursor",
      row = 1,
      col = 0,
      width = math.min(max_width + 1, math.floor(vim.o.columns * 0.8)),
      height = math.min(#lines, math.floor(vim.o.lines * 0.6)),
      style = "minimal",
      border = "rounded",
    })
  end, bufnr)
end

local COMMAND_NAME = "expand-macro-recursively"

-- Client-side command handler called by the standard code action application
-- logic when the user selects our injected action.
vim.lsp.commands[COMMAND_NAME] = function(_, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if client then do_expand(ctx.bufnr, client) end
end

-- A fake code action that gets injected into the textDocument/codeAction
-- response when the cursor is on a macro invocation. The empty edit prevents
-- the client from sending a codeAction/resolve request for it, and the command
-- triggers our handler above.
local expand_action = {
  title = "Expand macro recursively",
  edit = { changes = {} },
  command = {
    title = "Expand macro recursively",
    command = COMMAND_NAME,
  },
}

-- When rust_analyzer attaches, wrap client:request so that
-- textDocument/codeAction responses include our fake action whenever the cursor
-- is on a macro invocation.
vim.api.nvim_create_autocmd("LspAttach", {
  buffer = 0,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "rust_analyzer" then return end

    -- Prevent wrapping the same client multiple times if it attaches to
    -- multiple buffers.
    if client._expand_macro_wrapped then return end
    ---@diagnostic disable-next-line: inject-field
    client._expand_macro_wrapped = true

    local orig_request = client.request

    client.request = function(self, method, params, handler, bufnr_arg)
      if method == "textDocument/codeAction" and handler then
        if cursor_is_on_macro_invocation() then
          local orig_handler = handler
          handler = function(err, result, ...)
            result = result or {}
            table.insert(result, 1, expand_action)
            return orig_handler(err, result, ...)
          end
        end
      end

      return orig_request(self, method, params, handler, bufnr_arg)
    end
  end,
})

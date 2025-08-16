local utils = require("utils")

local hl_embed = function(text, hl_name)
  return "%#" .. hl_name .. "#" .. text .. "%*"
end

local lsp_separator_hl_name = "StatuslineLspSeparator"

vim.api.nvim_set_hl(0, lsp_separator_hl_name, { fg = "#928374" })

-- local lsp_separator = hl_embed(" ︳", lsp_separator_hl_name)
local lsp_separator = " ︳"

return {
  {
    "linrongbin16/lsp-progress.nvim",
    config = function()
      require("lsp-progress").setup({
        series_format = function(title, message, percentage, _)
          local components = {}
          local has_title = false

          if title and #title > 0 then
            -- Don't show notifications that are just a call to `cargo ..`.
            if not utils.lua.starts_with(title, "cargo ") then
              table.insert(components, title)
              has_title = true
            end
          end

          if has_title and message and #message > 0 then
            -- For rust-analyzer's "Root Scanned" notifications, strip the
            -- path that comes after "<num_scanned>/<num_total>".
            if title == "Roots Scanned" then
              message = message:match("^(%d+/%d+)")
            end
            table.insert(components, message)
          end

          if has_title and percentage then
            -- The formatting string will round the percentage to the nearest
            -- integer.
            table.insert(components, string.format("(%.0f%%)", percentage))
          end

          return #components > 0 and table.concat(components, " ") or ""
        end,

        client_format = function(client_name, spinner, series_messages)
          if #series_messages == 0 then return nil end

          local non_empty_messages = vim.tbl_filter(function(msg)
            return msg and #msg > 0
          end, series_messages)

          local message

          if #non_empty_messages == 0 then
            message = ""
          elseif #non_empty_messages == 1 then
            message = non_empty_messages[1]
          else
            local first = non_empty_messages[1]
            message = ("%s + %s more"):format(first, #non_empty_messages - 1)
          end

          return {
            name = client_name,
            body = spinner .. (#message > 0 and (" " .. message) or "")
          }
        end,

        format = function(client_messages)
          local lsp_clients = vim.lsp.get_clients({ bufnr = 0 })
          if #lsp_clients == 0 then return "" end
          table.sort(lsp_clients, function(lhs, rhs)
            return lhs.name < rhs.name
          end)

          local progress_map = {}
          for _, client_message in ipairs(client_messages) do
            progress_map[client_message.name] = client_message.body
          end

          local components = vim.tbl_map(function(lsp_client)
              if not lsp_client.name or lsp_client.name == "" then
                return nil
              end

              local client_progress = progress_map[lsp_client.name]

              return
                  lsp_client.name
                  ..
                  (client_progress and (" " .. client_progress) or "")
            end,
            lsp_clients
          )

          return #components > 0
              and table.concat(components, lsp_separator)
              or ""
        end
      })
    end
  }
}

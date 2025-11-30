---@param secret_name string
---@return string
local retrieve_keychain_secret_command_linux = function(secret_name)
  error("Linux keychain secret retrieval not implemented yet")
end

---@param secret_name string
---@return string
local retrieve_keychain_secret_command_macos = function(secret_name)
  -- To store the secret in the macOS keychain, use:
  -- security add-generic-password -a "$USER" -s <secret-name> -w <secret-value>
  return ("security find-generic-password -a $USER -s %s -w"):format(
    secret_name
  )
end

--- Returns the CLI command used to retrieve the secret with the given name
--- from the system keychain.
---@param secret_name string
---@return string
local retrieve_keychain_secret_command = function(secret_name)
  local os_name = vim.loop.os_uname().sysname
  if os_name == "Darwin" then
    return retrieve_keychain_secret_command_macos(secret_name)
  elseif os_name == "Linux" then
    return retrieve_keychain_secret_command_linux(secret_name)
  else
    error(("Unsupported OS for keychain secret retrieval: %s"):format(os_name))
  end
end

return {
  {
    "olimorris/codecompanion.nvim",
    branch = "v18",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      adapters = {
        acp = {
          claude_code = function()
            return require("codecompanion.adapters").extend("claude_code", {
              env = {
                -- Run `claude setup-token` to generate an OAuth token.
                CLAUDE_CODE_OAUTH_TOKEN = ("cmd:%s"):format(
                  retrieve_keychain_secret_command("claude-code-oauth-token")
                ),
              },
            })
          end
        },
      },
      display = {
        chat = {
          start_in_insert_mode = true,
        },
      },
      strategies = {
        chat = {
          adapter = "claude_code",
          roles = {
            llm = function(adapter) return adapter.formatted_name end,
            user = "Me",
          },
        },
      },
    },
    config = function(_, opts)
      require("codecompanion").setup(opts)

      -- Disable 'showbreak' in CodeCompanion buffers. Unfortunately it's a
      -- global option, so we have to save and restore it manually.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "codecompanion",
        callback = function(args)
          local bufnr = args.buf
          local showbreak = vim.opt.showbreak

          -- Disable it immediately (for initial entry).
          vim.opt.showbreak = ""

          -- Restore it when leaving.
          vim.api.nvim_create_autocmd("BufLeave", {
            buffer = bufnr,
            callback = function() vim.opt.showbreak = showbreak end,
          })

          -- Disable it again on subsequent entries.
          vim.api.nvim_create_autocmd("BufEnter", {
            buffer = bufnr,
            callback = function() vim.opt.showbreak = "" end,
          })
        end,
      })
    end,
  }
}

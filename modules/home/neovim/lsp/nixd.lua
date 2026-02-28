-- This config dynamically resolves the formatter command based on the
-- project's flake `formatter` output, if available.

---@alias KnownFormatter "alejandra" | "nixfmt" | "treefmt"

--- Maps known formatters to their stdin invocation pattern.
---@type table<KnownFormatter, fun(bin_path: string): string[]>
local formatter_to_stdin_command = {
  alejandra = function(bin_path) return { bin_path } end,
  nixfmt = function(bin_path) return { bin_path } end,
  treefmt = function(bin_path) return { bin_path, "--stdin", "dummy.nix" } end,
}

--- Returns the current system in Nix format (e.g., "aarch64-darwin").
---@return string
local get_current_system = function()
  local arch = ({
    arm64 = "aarch64",
    x64 = "x86_64",
  })[jit.arch]

  assert(arch, ("Unsupported architecture: %s"):format(jit.arch))

  local os = ({
    linux = "linux",
    osx = "darwin",
  })[jit.os:lower()]

  assert(os, ("Unsupported OS: %s"):format(jit.os))

  return ("%s-%s"):format(arch, os)
end

--- Asynchronously checks if a file exists.
---@param path string
---@param callback fun(exists: boolean)
local file_exists_async = function(path, callback)
  vim.uv.fs_stat(path, function(err, stat)
    callback(err == nil and stat ~= nil)
  end)
end

---@alias DetectFormatterResult
---| { variant: "found", command: string[] }
---| { variant: "no_flake" }
---| { variant: "no_formatter" }
---| { variant: "unknown_formatter", bin_path: string }

--- Asynchronously detects the flake formatter for a given root directory.
---@param root_dir string
---@param callback fun(result: DetectFormatterResult)
local detect_flake_formatter = function(root_dir, callback)
  file_exists_async(root_dir .. "/flake.nix", function(exists)
    if not exists then
      callback({ variant = "no_flake" })
      return
    end

    vim.system(
      {
        "nix",
        "eval",
        "--raw",
        (".#formatter.%s"):format(get_current_system()),
        "--apply",
        'pkg: "${pkg}/bin/${pkg.meta.mainProgram}"',
      },
      { cwd = root_dir, text = true },
      vim.schedule_wrap(function(result)
        if result.code ~= 0 or not result.stdout or result.stdout == "" then
          callback({ variant = "no_formatter" })
          return
        end

        local bin_path = result.stdout
        local bin_name = bin_path:match("/bin/([^/]+)$")
        local command_fn = bin_name and formatter_to_stdin_command[bin_name]

        if command_fn then
          callback({ variant = "found", command = command_fn(bin_path) })
        else
          callback({ variant = "unknown_formatter", bin_path = bin_path })
        end
      end)
    )
  end)
end

---@type vim.lsp.Config
return {
  on_attach = function(client)
    if not client.root_dir then
      return
    end

    detect_flake_formatter(client.root_dir, function(result)
      if result.variant == "found" then
        client:notify("workspace/didChangeConfiguration", {
          settings = {
            nixd = {
              formatting = { command = result.command },
            },
          },
        })
        vim.notify(
          ("[nixd] Set formatting command to %s")
          :format(vim.inspect(result.command)),
          vim.log.levels.DEBUG
        )
      elseif result.variant == "unknown_formatter" then
        vim.notify(
          ("[nixd] Unknown formatter at %s, not configuring formatting")
          :format(result.bin_path),
          vim.log.levels.WARN
        )
      end
    end)
  end,
}

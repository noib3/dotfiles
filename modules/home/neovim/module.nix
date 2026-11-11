{ inputs, mkPkgs }:

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.neovim;
  pkgsForNeovim = mkPkgs { inherit (pkgs.stdenv.hostPlatform) system; };
  claudeCode = config.programs.claude-code;
  nvim-agents-lua = ./plugins/nvim-agents/lua;

  refresh-nvim-hunks = pkgs.writeShellApplication {
    name = "refresh-nvim-hunks";
    runtimeInputs = [ cfg.package ];
    text = ''
      if [ -n "''${NVIM:-}" ]; then
        nvim --server "$NVIM" --remote-expr "v:lua.require'nvim_hunks'.refresh()" \
          >/dev/null 2>&1 || true
      fi
    '';
  };

  nvim-agents-hook = pkgs.writeShellApplication {
    name = "nvim-agents-hook";
    runtimeInputs = [
      pkgs.jq
      cfg.package
    ];
    text =
      builtins.replaceStrings
        [ "@state@" ]
        [ "${lib.getExe cfg.package} --clean -l ${nvim-agents-lua}/nvim_agents/mcp/state.lua" ]
        (builtins.readFile ./claude-code/nvim-agents-hook.sh);
  };

  nvim-agents-mcp = pkgs.writeShellApplication {
    name = "nvim-agents-mcp";
    text = ''
      exec ${lib.getExe cfg.package} --clean -l \
        ${nvim-agents-lua}/nvim_agents/mcp/stdio.lua
    '';
  };

  nvim-agents-hooks = [
    {
      type = "command";
      command = lib.getExe nvim-agents-hook;
    }
  ];

  editTools = "Edit|MultiEdit|Write|NotebookEdit";
in
{
  options.neovim = {
    package = mkOption {
      type = types.package;
      description = "The fully configured Neovim package";
      readOnly = true;
      default = pkgsForNeovim.callPackage ./package {
        inherit inputs;
        inherit (cfg) includeConfig;
        paletteData = cfg.palette;
      };
    };

    includeConfig = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to bundle the Neovim configuration into the package's runtime
        path. Set to false when providing the configuration externally (e.g. via
        a symlink to ~/.config/nvim).
      '';
    };

    palette = mkOption {
      type = types.attrs;
      default = import ./palettes/gruvbox.nix;
      description = "The colorscheme palette to generate into Lua";
    };

    enableClaudeCodeIntegration = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to configure {option}`programs.claude-code` for this Neovim:
        the MCP server of the Neovim whose terminal runs a session, the hooks
        of nvim-agents and nvim-hunks, and the ACP adapter nvim-agents forks
        sessions with.
      '';
    };
  };

  config = mkIf cfg.enableClaudeCodeIntegration {
    home.packages = lib.optional (claudeCode.package != null) (
      # The adapter runs the same CLI as the TUI.
      pkgs.claude-agent-acp.override { claude-code = claudeCode.package; }
    );

    programs.claude-code = {
      # Its tools are `mcp__plugin_hm_nvim__*`, from the plugin Home Manager
      # generates for the MCP servers.
      mcpServers.nvim.command = lib.getExe nvim-agents-mcp;

      settings = {
        hooks = {
          SessionStart = [ { hooks = nvim-agents-hooks; } ];
          SessionEnd = [ { hooks = nvim-agents-hooks; } ];
          Stop = [ { hooks = nvim-agents-hooks; } ];
          UserPromptSubmit = [ { hooks = nvim-agents-hooks; } ];
          PreToolUse = [
            {
              matcher = "Read|${editTools}|mcp__.*nvim.*__edit";
              hooks = nvim-agents-hooks;
            }
          ];
          PostToolUse = [
            {
              matcher = "${editTools}|mcp__.*nvim.*__edit";
              hooks = [
                {
                  type = "command";
                  command = lib.getExe refresh-nvim-hunks;
                }
              ];
            }
            {
              matcher = "Read|${editTools}|mcp__.*nvim.*__(read|edit)";
              hooks = nvim-agents-hooks;
            }
          ];
        };
        permissions = {
          allow = [ "mcp__plugin_hm_nvim" ];
          # In-place edits through the shell, which bypass Neovim's buffers.
          deny = [
            "Bash(sed -i*)"
            "Bash(sed -E -i*)"
            "Bash(perl -i*)"
            "Bash(perl -pi*)"
          ];
        };
      };
    };
  };
}

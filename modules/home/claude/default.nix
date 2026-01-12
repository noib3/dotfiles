{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.claude;
in
{
  options.modules.claude = {
    enable = mkEnableOption "Claude Code";
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        (inputs.claude-code-nix.packages.${pkgs.stdenv.system}.claude-code-bun.override
          {
            bunBinName = "claude";
          }
        )
        (import ./claude-code-acp.nix { inherit pkgs; })
      ];

      sessionVariables = {
        CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude";
      };
    };

    xdg.configFile."claude/settings.json" = {
      text = builtins.toJSON {
        enabledPlugins = {
          "rust-analyzer-lsp@claude-plugins-official" = true;
        };
      };
    };

    xdg.configFile."claude/commands" = {
      source = ./commands;
      recursive = true;
    };
  };
}

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
        inputs.claude-code-nix.packages.${pkgs.stdenv.system}.default
        (import ./claude-code-acp.nix { inherit pkgs; })
      ];

      sessionVariables = {
        CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude";
      };
    };

    xdg.configFile."claude/settings.json" = {
      text = builtins.toJSON {
        editor.mode = "vim";
        enabledPlugins = {
          "rust-analyzer-lsp@claude-plugins-official" = true;
        };
        permissions = {
          allow = [
            "Bash"
            "WebFetch"
            "WebSearch"
          ];
          ask = [
            "Edit"
            "NotebookEdit"
            "Write"
          ];
        };
      };
    };

    xdg.configFile."claude/commands" = {
      source = ./commands;
      recursive = true;
    };
  };
}

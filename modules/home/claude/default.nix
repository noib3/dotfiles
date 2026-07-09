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
        enabledPlugins = {
          "rust-analyzer-lsp@claude-plugins-official" = true;
        };
        env = lib.optionalAttrs config.modules.cli-proxy-api.enable {
          ANTHROPIC_BASE_URL = config.modules.cli-proxy-api.endpoint;
          ANTHROPIC_AUTH_TOKEN = config.modules.cli-proxy-api.apiKey;
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

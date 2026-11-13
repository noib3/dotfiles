{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.claude-code;
in
{
  options.modules.claude-code = {
    enable = mkEnableOption "Claude Code";
  };

  config = mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = inputs.claude-code-nix.packages.${pkgs.stdenv.system}.default;
      configDir = "${config.xdg.configHome}/claude";
      commandsDir = ./commands;
      settings = {
        modelSettings."claude-opus-5-5".effortLevel = "high";
        tui = "default";
        extraKnownMarketplaces.cloudflare.source = {
          source = "github";
          repo = "cloudflare/skills";
        };
        enabledPlugins."cloudflare@cloudflare" = true;
        env = {
          CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
        };
        permissions = {
          defaultMode = "acceptEdits";
          allow = [
            "Bash"
            "Edit"
            "Edit(//**)"
            "Read"
            "Read(//**)"
            "WebFetch"
            "WebSearch"
          ];
          deny = [ "SendFeedback" ];
        };
      };
    };
  };
}

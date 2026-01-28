{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.codex;
in
{
  options.modules.codex = {
    enable = mkEnableOption "Codex";
  };

  config = mkIf cfg.enable {
    home =
      let
        codexHome = "${config.xdg.configHome}/codex";
      in
      {
        packages = [ inputs.codex-cli-nix.packages.${pkgs.stdenv.system}.default ];

        sessionVariables.CODEX_HOME = codexHome;

        # When setting a custom CODEX_HOME, Codex will refuse to start if the
        # directory doesn't exist instead of creating it automatically, so let's
        # make sure it exists.
        activation.createCodexHome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "${codexHome}"
        '';
      };
  };
}

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.ags;
in
{
  options.modules.ags = {
    enable = mkEnableOption "Ags";
  };

  config = mkIf cfg.enable (
    let
      packageName = "ags";

      package = inputs.ags.lib.bundle {
        inherit pkgs;
        src = ./.;
        name = packageName;
        entry = "app.ts";
        extraPackages =
          [
          ];
      };
    in
    {
      systemd.user.services.ags = {
        Unit = {
          Description = "AGS";
          Documentation = "https://github.com/Aylur/ags";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session-pre.target" ];
        };

        Service = {
          ExecStart = "${package}/bin/${packageName}";
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    }
  );
}

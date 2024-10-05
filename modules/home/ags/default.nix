{
  config,
  lib,
  pkgs,
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
      package = (
        pkgs.hiPrio (
          pkgs.writeShellApplication {
            name = "ags";
            runtimeInputs = [ pkgs.bun ];
            text = "${pkgs.ags}/bin/ags";
          }
        )
      );
    in
    {
      # TODO: remove after https://github.com/Aylur/ags/issues/541 is fixed.
      home.packages = [
        package
      ];

      programs.ags = {
        enable = true;
        configDir = ./.;
        # TODO: enable after https://github.com/Aylur/ags/issues/541 is fixed.
        systemd.enable = false;
      };

      # TODO: remove after https://github.com/Aylur/ags/issues/541 is fixed.
      systemd.user.services.ags = {
        Unit = {
          Description = "AGS";
          Documentation = "https://github.com/Aylur/ags";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session-pre.target" ];
        };

        Service = {
          ExecStart = "${package}/bin/ags -b hypr";
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

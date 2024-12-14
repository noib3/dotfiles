{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.astal;
in
{
  options.modules.astal = {
    enable = mkEnableOption "Astal";
  };

  config = mkIf cfg.enable (
    let
      packageName = "astal";

      package = inputs.ags.lib.bundle {
        inherit pkgs;
        src = ./.;
        name = packageName;
        entry = "app.ts";
        extraPackages = [
          inputs.ags.packages.${pkgs.system}.battery
          inputs.ags.packages.${pkgs.system}.bluetooth
          inputs.ags.packages.${pkgs.system}.hyprland
          inputs.ags.packages.${pkgs.system}.network
        ];
      };
    in
    {
      home.packages = with pkgs; [
        adwaita-icon-theme
      ];

      systemd.user.services.astal = {
        Unit = {
          Description = "Astal";
          Documentation = "https://github.com/Aylur/astal";
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

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.hardware.logitech.mx-master-3s-for-mac;
in
{
  options.hardware.logitech.mx-master-3s-for-mac = {
    enable = mkEnableOption ''
      Configures the Logitech MX Master 3S for Mac mouse
    '';
  };

  config = mkIf cfg.enable (
    let
      service_name = "logiops";
    in
    {
      hardware.logitech.wireless.enable = true;

      environment.etc."logid.cfg".text = ''
        devices = (
          {
            name = "MX Master 3S For Mac";
            hiresscroll = {
              hires = true;
              invert = true;
              target = false;
            };
          }
        );
      '';

      systemd.services.${service_name} = {
        after = [ "bluetooth.target" ];
        bindsTo = [ "bluetooth.target" ];
        serviceConfig = {
          Type = "simple";
          # The latest version of LogiOps is shite, so use older one.
          # See https://github.com/NixOS/nixpkgs/pull/293843 for more infos.
          ExecStart = "${pkgs.logiops_0_2_3}/bin/logid";
        };
      };

      # LogiOps stops working if the mouse is disconnected and reconnected,
      # so we restart the service when the mouse is reconnected.
      services.udev.extraRules =
        let
          restartLogiOps = "${pkgs.systemd}/bin/systemctl restart ${service_name}.service";
        in
        ''
          # The "online" flag is only 1 when the mouse is first connected.
          ACTION=="change", \
          SUBSYSTEM=="power_supply", \
          ATTRS{manufacturer}=="Logitech", \
          ATTRS{model_name}=="MX Master 3S For Mac", \
          ATTRS{online}=="1", \
          RUN+="${restartLogiOps}"

          # This doesn't trigger on my MacBook, but I think it could on other
          # machines(?).
          ACTION=="add", \
          SUBSYSTEM=="hidraw", \
          ATTRS{idVendor}=="046D", \
          ATTRS{idProduct}=="B034", \
          RUN+="${restartLogiOps}"
        '';
    }
  );
}

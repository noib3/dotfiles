{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.hardware.remarkable.remarkable2;
in
{
  options.hardware.remarkable.remarkable2 = {
    enable = mkEnableOption ''
      Enables configurations for the reMarkable 2 tablet
    '';
  };

  config = mkIf cfg.enable {
    # TODO: setup VPN split tunneling to route traffic through the local
    # interface when connecting to the reMarkable via SSH (instead of manually
    # calling e.g. `mullvad-exclude ssh <remarkable>`).

    # Needed to open the SSH port.
    services.openssh.enable = true;
  };
}

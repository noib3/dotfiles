{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.services.bluetooth-autoconnect;

  package = pkgs.stdenv.mkDerivation {
    name = "bluetooth-autoconnect";

    src = pkgs.fetchFromGitHub {
      owner = "jrouleau";
      repo = "bluetooth-autoconnect";
      rev = "v1.3";
      sha256 = "sha256-qfU7fNPNRQxIxxfKZkGAM6Wd3NMuNI+8DqeUW+LYRUw=";
    };

    propagatedBuildInputs = with pkgs; [
      (python3.withPackages (
        pp: with pp; [
          dbus-python
          pygobject3
        ]
      ))
      glib
      gobject-introspection
      wrapGAppsNoGuiHook
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp bluetooth-autoconnect $out/bin/
      chmod +x $out/bin/bluetooth-autoconnect
    '';
  };
in
{
  options.services.bluetooth-autoconnect = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to run the bluetooth-autoconnect script in daemon mode
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.bluetooth-autoconnect = {
      Unit = {
        Description = "Bluetooth autoconnect service";
        Before = [ "bluetooth.service" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${package}/bin/bluetooth-autoconnect -d";
      };

      Install = {
        WantedBy = [ "bluetooth.service" ];
      };
    };
  };
}

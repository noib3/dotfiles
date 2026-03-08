{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.kanshi;

  # A profile is enabled when the `criteria`s of all its outputs match
  # a currently connected monitor.
  #
  # See
  # https://gitlab.freedesktop.org/emersion/kanshi/-/blob/master/doc/kanshi.5.scd?ref_type=heads#L68-L81
  # for the possible values a criteria can have.

  mkCriteria =
    {
      manufacturer,
      model,
      serial,
    }:
    let
      fallback = info: if info == null then "Unknown" else info;
    in
    "${fallback manufacturer} ${fallback model} ${fallback serial}";

  skunkScreen = {
    manufacturer = "Apple Computer Inc";
    model = "Color LCD";
    serial = null;
  };

  uperfectT118 = {
    manufacturer = "Invalid Vendor Codename - RTK";
    model = "J584T05";
    serial = "0x20231117";
  };
in
{
  options.modules.kanshi = {
    enable = mkEnableOption "kanshi";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isLinux;
        message = "kanshi is only available on Linux";
      }
    ];

    services.kanshi = {
      enable = true;

      settings = [
        {
          profile = {
            name = "docked";
            outputs = [
              {
                criteria = mkCriteria uperfectT118;
                status = "enable";
                position = "0,0";
              }
              {
                criteria = mkCriteria skunkScreen;
                status = "disable";
              }
            ];
          };
        }
        {
          profile = {
            name = "mobile";
            outputs = [
              {
                criteria = mkCriteria skunkScreen;
                status = "enable";
                position = "0,0";
              }
            ];
          };
        }
      ];

      systemdTarget = "graphical-session.target";
    };
  };
}

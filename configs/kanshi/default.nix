{ config, pkgs }:

# A profile is enabled when the `criteria`s of all its outputs match a
# currently connected monitor.
#
# See [1] for the possible values a criteria can have.

let
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
  enable = pkgs.stdenv.isLinux;

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

  # See https://discourse.nixos.org/t/starting-kanshi-via-systemd-user-swaywm/27960
  systemdTarget = "";
}

# [1]: https://git.sr.ht/~emersion/kanshi/tree/master/item/doc/kanshi.5.scd#L68-80

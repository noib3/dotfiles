{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.whatsapp;

  # Nixpkgs' WhatsApp version is outdated, causing fetching to fail.
  #
  # See https://github.com/NixOS/nixpkgs/issues/364195 for more infos, and
  # https://formulae.brew.sh/cask/whatsapp to get the latest version.
  whatsapp-for-mac-latest =
    let
      version = "2.25.16.81";
    in
    pkgs.whatsapp-for-mac.overrideAttrs (_oldAttrs: {
      inherit version;
      src = pkgs.fetchzip {
        hash = "sha256-CZcMYWyBpusM+NUlMC2du01cq3uqXvMiIdOienLn/nM=";
        extension = "zip";
        name = "WhatsApp.app";
        url = "https://web.whatsapp.com/desktop/mac_native/release/?version=${version}&extension=zip&configuration=Release&branch=relbranch";
      };
    });
in
{
  options.modules.whatsapp = {
    enable = mkEnableOption "WhatsApp desktop client";

    package = mkOption {
      type = types.package;
      # default = whatsapp-for-mac-latest;
      default = pkgs.whatsapp-for-mac;
      description = "The WhatsApp package to use";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "The WhatsApp desktop client is only available on macOS";
      }
    ];

    home.packages = lib.mkIf pkgs.stdenv.isDarwin [
      cfg.package
    ];

    modules.nixpkgs.allowUnfreePackages = [
      (lib.getName cfg.package)
    ];
  };
}

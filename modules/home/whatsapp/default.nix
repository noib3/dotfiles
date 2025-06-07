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
  # See https://github.com/NixOS/nixpkgs/issues/364195 for more infos.
  whatsapp-for-mac-latest =
    let
      version = "2.25.16.81";
      url = "https://web.whatsapp.com/desktop/mac_native/release/?version=${version}&extension=zip&configuration=Release&branch=relbranch";
    in
    pkgs.whatsapp-for-mac.overrideAttrs (_oldAttrs: {
      inherit version;
      src = pkgs.fetchzip {
        inherit url;
        extension = "zip";
        name = "WhatsApp.app";
        hash = "sha256-CZcMYWyBpusM+NUlMC2du01cq3uqXvMiIdOienLn/nM=";
      };
    });
in
{
  options.modules.whatsapp = {
    enable = mkEnableOption "WhatsApp desktop client";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "The WhatsApp desktop client is only available on macOS";
      }
    ];

    home.packages = lib.mkIf pkgs.stdenv.isDarwin [
      whatsapp-for-mac-latest
    ];

    modules.nixpkgs.allowUnfreePackages = [
      "whatsapp-for-mac"
    ];
  };
}

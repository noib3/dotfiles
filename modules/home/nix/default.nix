{
  lib,
  pkgs,
  ...
}:

{
  config = {
    home.packages =
      with pkgs;
      [
        nixd
        nixVersions.latest
        nixfmt-rfc-style
      ];

    nix = {
      package = pkgs.nixVersions.latest;
      settings = {
        experimental-features = [
          "flakes"
          "nix-command"
          "pipe-operators"
        ];
        trusted-substituters = [
          "https://cache.soopy.moe"
          "https://nix-community.cachix.org"
        ];
        warn-dirty = false;
      };
    };
  };
}

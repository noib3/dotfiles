{
  lib,
  pkgs,
  ...
}:

{
  config = {
    home.packages =
      with pkgs;
      let
        # The last release doesn't have support for the pipe operator.
        latestNil = nil.overrideAttrs (old: rec {
          version = "2e24c98";
          src = fetchFromGitHub {
            owner = "oxalica";
            repo = "nil";
            rev = version;
            hash = "sha256-DCIVdlb81Fct2uwzbtnawLBC/U03U2hqx8trqTJB7WA=";
          };
          cargoDeps = old.cargoDeps.overrideAttrs (
            lib.const {
              name = "${old.pname}-vendor.tar.gz";
              inherit src;
              outputHash = "sha256-FppdLgciTzF6tBZ+07IEzk5wGinsp1XUE7T18DCGvKg=";
            }
          );
        });
      in
      [
        latestNil
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

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.rust;
in
{
  options.modules.rust = {
    enable = mkEnableOption "Rust";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        (rust-bin.selectLatestNightlyWith (
          toolchain:
          toolchain.minimal.override {
            extensions = [
              "clippy"
              "miri"
              # Needed by `cargo-llvm-cov`.
              "llvm-tools"
              "rust-analyzer"
              # Needed by `rust-analyzer` to index `std`.
              "rust-src"
              "rustfmt"
            ];
          }
        ))
        cargo-criterion
        cargo-deny
        cargo-expand
        cargo-flamegraph
        cargo-fuzz
      ]
      # cargo-llvm-cov is currently broken on macOS.
      ++ lib.lists.optionals (!pkgs.stdenv.isDarwin) [ cargo-llvm-cov ];

    home.sessionVariables = {
      CARGO_HOME = "${config.xdg.dataHome}/cargo";
    };

    nixpkgs.overlays = [
      inputs.rust-overlay.overlays.default
    ];
  };
}

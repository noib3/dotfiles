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
  rustBin = inputs.rust-overlay.lib.mkRustBin { } pkgs;

  nightlyToolchain = rustBin.selectLatestNightlyWith (
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
  );
in
{
  options.modules.rust.enable = mkEnableOption "Rust";

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        cargo-criterion
        cargo-deny
        cargo-expand
        cargo-flamegraph
        cargo-fuzz
        nightlyToolchain
      ]
      # cargo-llvm-cov is currently broken on macOS.
      ++ lib.lists.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [ cargo-llvm-cov ];

    home.sessionVariables = {
      CARGO_HOME = "${config.xdg.dataHome}/cargo";
      RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    };

    xdg.dataFile."cargo/config.toml".text = ''
      [build]
      build-dir = "${config.xdg.stateHome}/cargo/build/{workspace-path-hash}"
    '';
  };
}

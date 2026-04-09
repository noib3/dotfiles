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

  cargoTargetDirEnv = pkgs.writeShellApplication {
    name = "cargo-target-dir-env";
    text = ''
      ${builtins.readFile ../scripts/project-hash-utils.sh}
      ${builtins.readFile ./cargo-target-dir-env.sh}
    '';
  };

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

  # Wrap all the executables in the toolchain to get around
  # https://github.com/oxalica/rust-overlay/issues/248
  nightlyToolchainWrapped =
    pkgs.runCommand "rust-nightly-toolchain-wrapped"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p "$out/bin"

        for exe in "${nightlyToolchain}"/bin/*; do
          makeWrapper "$exe" "$out/bin/$(basename "$exe")" \
            --prefix DYLD_FALLBACK_LIBRARY_PATH : "${nightlyToolchain}/lib"
        done
      '';
in
{
  options.modules.rust = {
    enable = mkEnableOption "Rust";
    cargo-target-dir-env = mkOption {
      type = types.package;
      readOnly = true;
      default = cargoTargetDirEnv;
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        cargo-criterion
        cargo-deny
        cargo-expand
        cargo-flamegraph
        cargo-fuzz
        cargoTargetDirEnv
        nightlyToolchain
      ]
      ++ lib.lists.optionals pkgs.stdenv.isDarwin [
        (lib.hiPrio nightlyToolchainWrapped)
      ]
      # cargo-llvm-cov is currently broken on macOS.
      ++ lib.lists.optionals (!pkgs.stdenv.isDarwin) [ cargo-llvm-cov ];

    home.sessionVariables = {
      CARGO_HOME = "${config.xdg.dataHome}/cargo";
      RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    };
  };
}

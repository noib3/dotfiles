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

  nightlyToolchain = pkgs.rust-bin.selectLatestNightlyWith (
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
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        nightlyToolchain
        cargo-criterion
        cargo-deny
        cargo-expand
        cargo-flamegraph
        cargo-fuzz
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

    modules.neovim = {
      tree-sitter-parsers = [ pkgs.vimPlugins.nvim-treesitter-parsers.rust ];
      tree-sitter-queries = [ pkgs.vimPlugins.nvim-treesitter.queries.rust ];
    };

    nixpkgs.overlays = [
      inputs.rust-overlay.overlays.default
    ];
  };
}

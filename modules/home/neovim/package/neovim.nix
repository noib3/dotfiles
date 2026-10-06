{
  inputs,
  lib,
  pkgs,
}:

let
  overlayPackages = "${inputs.nix-community-neovim}/flake/packages";

  neovim-dependencies = import "${overlayPackages}/neovim-dependencies.nix" {
    inherit (inputs) neovim-src;
    inherit lib pkgs;
  };

  dependencyMetadata = lib.pipe "${inputs.neovim-src}/cmake.deps/deps.txt" [
    builtins.readFile
    (lib.splitString "\n")
    (map (
      builtins.match "([A-Z0-9_]+)_(URL|SHA256)[[:space:]]+([^[:space:]]+)[[:space:]]*"
    ))
    (lib.remove null)
    (lib.flip builtins.foldl' { } (
      acc: matches:
      let
        name = lib.toLower (builtins.elemAt matches 0);
        key = lib.toLower (builtins.elemAt matches 1);
        value = builtins.elemAt matches 2;
      in
      acc
      // {
        ${name} = acc.${name} or { } // {
          ${key} = value;
        };
      }
    ))
  ];

  treeSitterSource =
    pkgs.runCommand "tree-sitter-source" { src = neovim-dependencies.treesitter; }
      ''
        mkdir "$out"
        tar --extract --gzip --file "$src" --strip-components=1 --directory "$out"
      '';

  tree-sitter =
    (import "${overlayPackages}/tree-sitter.nix" {
      inherit lib pkgs neovim-dependencies;
    }).overrideAttrs
      (_: {
        cargoHash = null;
        cargoDeps = pkgs.rustPlatform.importCargoLock {
          lockFile = "${treeSitterSource}/Cargo.lock";
        };
      });

  ghosttyMetadata =
    let
      matches = builtins.match "https://github.com/([^/]+)/([^/]+)/archive/([0-9a-f]+)\\.tar\\.gz" dependencyMetadata.ghostty.url;
    in
    {
      owner = builtins.elemAt matches 0;
      repo = builtins.elemAt matches 1;
      rev = builtins.elemAt matches 2;
    };

  ghosttySrc = builtins.fetchGit {
    url = "https://github.com/${ghosttyMetadata.owner}/${ghosttyMetadata.repo}";
    rev = ghosttyMetadata.rev;
  };

  ghostty-vt =
    (pkgs.callPackage "${ghosttySrc}/nix/libghostty-vt.nix" {
      revision = ghosttyMetadata.rev;
      optimize = "ReleaseFast";
      # nixpkgs' Zig 0.16 emits malformed compiler_rt.o section symbols on Linux.
      # Use upstream binaries to keep libghostty-vt statically linked.
      # https://github.com/ghostty-org/ghostty/pull/14489
      zig_0_16 =
        if pkgs.stdenv.hostPlatform.isLinux then
          inputs.zig-overlay.packages.${pkgs.stdenv.hostPlatform.system}."0.16.0".overrideAttrs
            (_: {
              dontFixup = false;
              dontStrip = true;
              setupHook = "${pkgs.path}/pkgs/development/compilers/zig/setup-hook.sh";
              env = pkgs.zig_0_16.env;
            })
        else
          pkgs.zig_0_16;
    }).overrideAttrs
      (oa: {
        # Zig's automatic libc detection selects musl; this build uses glibc.
        zigBuildFlags =
          oa.zigBuildFlags
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            "-Dtarget=${pkgs.stdenv.hostPlatform.system}-gnu"
          ];
      });
in
(import "${overlayPackages}/neovim.nix" {
  inherit (inputs) neovim-src;
  inherit
    lib
    pkgs
    neovim-dependencies
    tree-sitter
    ;
}).overrideAttrs
  (oa: {
    buildInputs = (oa.buildInputs or [ ]) ++ [
      ghostty-vt
    ];
  })

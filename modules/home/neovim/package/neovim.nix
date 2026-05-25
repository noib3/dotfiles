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

  treeSitterRev =
    let
      matches = builtins.match "https://github.com/tree-sitter/tree-sitter/archive/([0-9a-f]+)\\.tar\\.gz" dependencyMetadata.treesitter.url;
    in
    builtins.elemAt matches 0;

  treeSitterCargoLockSource = builtins.fetchGit {
    url = "https://github.com/tree-sitter/tree-sitter";
    rev = treeSitterRev;
  };

  tree-sitter =
    (import "${overlayPackages}/tree-sitter.nix" {
      inherit lib pkgs neovim-dependencies;
    }).overrideAttrs
      (_: {
        cargoHash = null;
        cargoDeps = pkgs.rustPlatform.importCargoLock {
          lockFile = "${treeSitterCargoLockSource}/Cargo.lock";
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

  ghostty-vt = pkgs.callPackage "${ghosttySrc}/nix/libghostty-vt.nix" {
    revision = ghosttyMetadata.rev;
    optimize = "ReleaseFast";
  };
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

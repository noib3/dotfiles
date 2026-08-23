{
  fetchurl,
  fetchzip,
  inputs,
  lib,
  pkgs,
  python313,
}:

let
  pname = "codex-lb";
  version = "1.24.0-beta.3";

  mainSrc = fetchzip {
    url = "https://github.com/Soju06/codex-lb/archive/1ecb51d2e31c0ea808c631ad559bfcd4be586a54.tar.gz";
    hash = "sha256-zmQ/vyVi1MKILgiN+wE1UIdeqhGrGy5PSjCgfRRW1Ek=";
  };

  frontendWheel = fetchurl {
    url = "https://files.pythonhosted.org/packages/72/3e/7780f1c9765eba4dda88dd3c6457a6af0644af73b23a348e55b074fe10de/codex_lb-1.24.0b3-py3-none-any.whl";
    hash = "sha256-yVtBHoaD4ZLG1uvvkWW9iJhYhjVqkoI4H9s+wCQYxHQ=";
  };

  frontend =
    pkgs.runCommand "${pname}-frontend-${version}"
      {
        nativeBuildInputs = [ pkgs.unzip ];
      }
      ''
        mkdir -p "$out"
        unzip -q ${frontendWheel} 'app/static/*' -d wheel
        cp -R wheel/app/static/. "$out"
      '';

  src = pkgs.runCommand "${pname}-${version}-source" { } ''
    mkdir -p "$out"
    cp -R ${mainSrc}/. "$out"
    chmod -R u+w "$out"
    cp -R ${frontend} "$out/app/static"
  '';

  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = src;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  cryptographyOverlayForX86Darwin =
    final: prev:
    lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-darwin") {
      # cryptography 50.0.0 has no x86_64-darwin wheel in codex-lb's uv.lock,
      # so uv2nix falls back to an sdist build that needs the maturin backend.
      cryptography = prev.cryptography.overrideAttrs (old: {
        MATURIN_NO_INSTALL_RUST = "1";
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit (old) pname version src;
          hash = "sha256-heJGLh0MgDPpksWyPLaIkZ5gVEWx8UnaJKv4GvclpmI=";
        };
        nativeBuildInputs =
          (old.nativeBuildInputs or [ ])
          ++ [
            pkgs.rustPlatform.cargoSetupHook
            pkgs.pkg-config
            pkgs.cargo
            pkgs.rustc
          ]
          ++ final.resolveBuildSystem {
            cffi = [ ];
            maturin = [ ];
            setuptools = [ ];
          };
        buildInputs = (old.buildInputs or [ ]) ++ [
          pkgs.openssl
          pkgs.libiconv
        ];
      });
    };

  pythonSet =
    (pkgs.callPackage inputs.pyproject-nix.build.packages {
      python = python313;
    }).overrideScope
      (
        lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.wheel
          overlay
          cryptographyOverlayForX86Darwin
        ]
      );

  venv = pythonSet.mkVirtualEnv "${pname}-env" workspace.deps.default;

  inherit (pkgs.callPackages inputs.pyproject-nix.build.util { }) mkApplication;
in
(mkApplication {
  inherit venv;
  package = pythonSet.${pname};
}).overrideAttrs
  (old: {
    meta = old.meta // {
      mainProgram = "codex-lb";
    };
  })

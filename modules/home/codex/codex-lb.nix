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
  version = "1.22.0";

  mainSrc = fetchzip {
    url = "https://github.com/Soju06/codex-lb/archive/4c0dbc9ceb2b5d70204ea7603cf1b4bef83db234.tar.gz";
    hash = "sha256-HMGgf5w1GcSKvcf0zQL1LqgMHoU1HoB/dnxFVJvYEKY=";
  };

  frontendWheel = fetchurl {
    url = "https://files.pythonhosted.org/packages/d3/93/f1b70213c3c56b7d8af2a12f6eb17ba5fdc73aa9bed17e19a975cfd885c1/codex_lb-1.22.0-py3-none-any.whl";
    hash = "sha256-R2sb9HFr2A/j+FiLnT+QElnZwzAKJ2h0eE4IRq981Lk=";
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
      # cryptography 49.0.0 has no x86_64-darwin wheel in codex-lb's uv.lock,
      # so uv2nix falls back to an sdist build that needs the maturin backend.
      cryptography = prev.cryptography.overrideAttrs (old: {
        MATURIN_NO_INSTALL_RUST = "1";
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit (old) pname version src;
          hash = "sha256-yMCBu/RGRcEQST8tEWCNgVvlQsp2KamOqt60qvOYdt8=";
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

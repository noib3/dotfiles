{
  fetchzip,
  inputs,
  lib,
  pkgs,
  python313,
}:

let
  pname = "codex-lb";
  version = "1.20.0-beta.1";

  src = fetchzip {
    url = "https://github.com/Soju06/codex-lb/releases/download/v${version}/codex_lb-1.20.0b1.tar.gz";
    hash = "sha256-KuENk/M09euJNo+pq8sQ0Ghuk1Sqr+mXK6yF34TG9GY=";
  };

  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = src;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  pythonSet =
    (pkgs.callPackage inputs.pyproject-nix.build.packages {
      python = python313;
    }).overrideScope
      (
        lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.wheel
          overlay
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

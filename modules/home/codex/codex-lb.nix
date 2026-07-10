{
  fetchzip,
  inputs,
  lib,
  pkgs,
  python313,
}:

let
  pname = "codex-lb";
  version = "1.20.2-beta.1-main-20260710";

  bun2nix = inputs.bun2nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

  mainSrc = pkgs.applyPatches {
    name = "${pname}-${version}-patched-source";
    src = fetchzip {
      url = "https://github.com/Soju06/codex-lb/archive/b0f5ea8b03a6b7685d281d74350a22377e05d72e.tar.gz";
      hash = "sha256-h8TnZUUys+AOTX/69EysccZMdXXP042ofe9U5xOUJGA=";
    };
    patches = [
      ./patches/account-model-failover.patch
      ./patches/model-catalog-union.patch
    ];
  };

  frontendBunNix =
    pkgs.runCommand "${pname}-frontend-bun.nix" { nativeBuildInputs = [ bun2nix ]; }
      ''
        bun2nix \
          --lock-file ${mainSrc}/frontend/bun.lock \
          --output-file $out
      '';

  frontend = pkgs.stdenvNoCC.mkDerivation {
    pname = "${pname}-frontend";
    inherit version;
    src = mainSrc;
    sourceRoot = "${mainSrc.name}/frontend";
    postUnpack = ''
      chmod -R u+w ${mainSrc.name}
    '';

    nativeBuildInputs = [ bun2nix.hook ];
    bunDeps = bun2nix.fetchBunDeps {
      bunNix = frontendBunNix;
    };
    dontRunLifecycleScripts = true;

    buildPhase = ''
      runHook preBuild
      bun run build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -R ../app/static $out
      runHook postInstall
    '';
  };

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

{
  lib,
  pkgs,
  bun2nix,
}:

let
  version = "0.4.4";

  src = pkgs.fetchFromGitHub {
    owner = "ProtonDriveApps";
    repo = "sdk";
    rev = "cli/v${version}";
    hash = "sha256-8KqmXWyRYKyS8gZJu0A4zK02cucU8jaek3mKXzq0PaQ=";
  };

  cliRoot = "js/cli";

  bunNix =
    pkgs.runCommand "proton-drive-cli-bun.nix" { nativeBuildInputs = [ bun2nix ]; }
      ''
        bun2nix \
          --lock-file ${src}/${cliRoot}/bun.lock \
          --copy-prefix ${src}/${cliRoot}/ \
          --output-file $out
      '';

  packageJson = lib.importJSON "${src}/${cliRoot}/package.json";
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "proton-drive-cli";
  inherit version src;

  sourceRoot = "${src.name}/${cliRoot}";

  nativeBuildInputs = [
    bun2nix.hook
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.darwin.sigtool ];

  bunDeps = bun2nix.fetchBunDeps {
    inherit bunNix;
    overrides = bun2nix.patchedDependenciesToOverrides {
      patchedDependencies = lib.mapAttrs (_: path: "${src}/${cliRoot}/${path}") (
        packageJson.patchedDependencies or { }
      );
    };
  };

  dontRunLifecycleScripts = true;

  env = {
    CLI_APP_VERSION_NAME = "external-drive-proton_drive_cli";
    CLI_VERSION = version;
    JS_VERSION = "0.17.2";
  };

  postBunNodeModulesInstallPhase = ''
    chmod -R u+w ../sdk
    cp -R node_modules ../sdk/
  '';

  buildPhase = ''
    runHook preBuild
    bun run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 release/proton-drive $out/bin/proton-drive
    ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      export CODESIGN_ALLOCATE=${pkgs.darwin.cctools}/bin/codesign_allocate
      codesign --force --sign - $out/bin/proton-drive
    ''}
    runHook postInstall
  '';

  dontFixup = true;

  meta = {
    description = "Command-line interface for Proton Drive";
    homepage = "https://github.com/ProtonDriveApps/sdk/tree/${src.rev}/${cliRoot}";
    changelog = "https://github.com/ProtonDriveApps/sdk/blob/${src.rev}/${cliRoot}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "proton-drive";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryNativeCode
    ];
  };
}

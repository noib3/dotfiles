{
  fetchurl,
  lib,
  stdenvNoCC,
}:

let
  version = "0.8.0";

  sources = {
    aarch64-darwin = {
      platform = "darwin-arm64";
      hash = "sha512-FIOi+mr+ekmr3DT2ZCC4fgpdSNI29vSnnq5/fXbcOmvuvtzeXiKc5f3vQkUK2kG7zAIWGmSvtHO8qk/ak4xzKQ==";
    };
    x86_64-darwin = {
      platform = "darwin-x64";
      hash = "sha512-T+2Tmr+6tKepbiqvFk1nLOPixswHF+ZbGMMcql9Szmbjq4Q+wvPEUaMmizgpHNlkYyqKv2ycjsN/VCiXMQbJ3Q==";
    };
    aarch64-linux = {
      platform = "linux-arm64-musl";
      hash = "sha512-+zhsqza8NG6Lrh8+ee/dFIEN50jnYqLIjzhAFhmf9yETBMwOxNIgwmDGe4O75NOo1N0qLqDpO5/dJcHkL0SBZQ==";
    };
    x86_64-linux = {
      platform = "linux-x64-musl";
      hash = "sha512-x24sAAzCLAGELAX9cSKk/7zL6MCTi4rIkqElzcvqHo03S+iZFray/d9/FngQW2coP3Wh+aRPYt9Hi+EZt9yFew==";
    };
  };

  source = sources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "proton-drive-cli";
  inherit version;

  src = fetchurl {
    url = "https://proton.me/download/drive/cli/${version}/${source.platform}/proton-drive";
    inherit (source) hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/proton-drive
    runHook postInstall
  '';

  meta = {
    description = "Command-line interface for Proton Drive";
    homepage = "https://github.com/ProtonDriveApps/sdk/tree/cli/v${version}/cli";
    changelog = "https://github.com/ProtonDriveApps/sdk/blob/cli/v${version}/cli/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "proton-drive";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

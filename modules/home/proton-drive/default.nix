{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.proton-drive;
  bun2nix = inputs.bun2nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.modules.proton-drive = {
    enable = mkEnableOption "Proton Drive";

    accountEmail = mkOption {
      type = types.singleLineStr;
      description = "The Proton account email to use for Proton Drive";
      default = "riccardo.mazzarini@pm.me";
      readOnly = true;
    };

    directory = mkOption {
      type = types.singleLineStr;
      default = "${config.home.homeDirectory}/Documents";
      description = "The path to the Proton Drive directory";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.callPackage ./proton-drive-cli.nix { inherit bun2nix; })
    ];

    home.activation = mkIf pkgs.stdenv.isDarwin {
      symlinkDocumentsToProtonDrive = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -e "${cfg.directory}" ] && [ ! -L "${cfg.directory}" ]; then
          ln -s \
            "${config.home.homeDirectory}/Library/CloudStorage/ProtonDrive-${cfg.accountEmail}-folder" \
            "${cfg.directory}"
        fi
      '';
    };
  };
}

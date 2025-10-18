{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.nixpkgs;
in
{
  options.modules.nixpkgs.allowUnfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "List of unfree package names to allow";
    default = [ ];
  };

  config = {
    modules.nixpkgs.allowUnfreePackages = [
      "ookla-speedtest"
      "spotify"
      "widevine-cdm"
      "zoom"
    ];

    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.allowUnfreePackages;
  };
}

{ config, lib, pkgs, ... }:

# Adapted from [1].

with lib;
let
  cfg = config.programs.spacebar;

  toSpacebarConfig = opts:
    concatStringsSep "\n" (mapAttrsToList
      (p: v:
        "spacebar -m config ${p} ${toString v}")
      opts);
in
{
  meta.maintainers = [ maintainers.noib3 ];

  options.programs.spacebar = {
    enable = mkEnableOption "spacebar";

    package = mkOption {
      type = types.package;
      default = pkgs.spacebar;
      defaultText = literalExample "pkgs.spacebar";
      description = "The spacebar package to use.";
    };

    config = mkOption {
      type = types.attrs;
      default = { };
      example = literalExample ''
        {
          clock_format = "%R";
          background_color = "0xff202020";
          foreground_color = "0xffa8a8a8";
        }
      '';
      description = ''
        Key/Value pairs to pass to spacebar's 'config' domain, via the configuration file.
      '';
    };

    extraConfig = mkOption {
      type = types.str;
      default = "";
      example = literalExample ''
        echo "spacebar config loaded..."
      '';
      description = ''
        Extra arbitrary configuration to append to the configuration file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "spacebar/spacebarrc".text = (
        if (cfg.config != { }) then "${toSpacebarConfig cfg.config}"
        else ""
      ) + optionalString (cfg.extraConfig != "") ("\n" + cfg.extraConfig);
    };
  };
}

# [1]: https://github.com/LnL7/nix-darwin/blob/master/modules/services/spacebar/default.nix

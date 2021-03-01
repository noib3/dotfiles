{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.vivid;

  configFile = config: file:
    pkgs.runCommand "${file}.yml" {
      buildInputs = [ pkgs.remarshal ];
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      remarshal -if json -of yaml \
        < ${pkgs.writeText "${file}.json" (builtins.toJSON config)} \
        > $out
    '';

in {
  meta.maintainers = [ mainteners.noib3 ];

  options.programs.vivid = {
    enable = mkEnableOption "vivid";

    package = mkOption {
      type = types.package;
      default = pkgs.vivid;
      defaultText = literalExample "pkgs.vivid";
      description = "The vivid package to install.";
    };

    filetypes = mkOption {
      type = with types;
        let
          prim = either bool (either int str);
          primOrPrimAttrs = either prim (attrsOf prim);
          entry = either prim (listOf primOrPrimAttrs);
          entryOrAttrsOf = t: either entry (attrsOf t);
          entries = entryOrAttrsOf (entryOrAttrsOf entry);
        in attrsOf entries // { description = "Filetypes configuration"; };
      default = { };
      example = literalExample ''
        {
          core = {
            regular_file = [ "$fi" ];
            directory = [ "$di" ];
          };
          text = {
            readme = [ "README.md" ];
            licenses = [ "LICENSE" ];
          };
        }
      '';
      description = ''
        Configuration written to
        <filename>~/.config/vivid/filetypes.yml</filename>.
      '';
    };

    themes = mkOption {
      type = with types;
        let
          prim = either bool (either int str);
          primOrPrimAttrs = either prim (attrsOf prim);
          entry = either prim (listOf primOrPrimAttrs);
          entryOrAttrsOf = t: either entry (attrsOf t);
          entries = entryOrAttrsOf (entryOrAttrsOf entry);
        in attrsOf (attrsOf entries) // { description = "Filetypes configuration"; };
      default = { };
      example = literalExample ''
        {
          core = {
            regular_file = [ "$fi" ];
            directory = [ "$di" ];
          };
          text = {
            readme = [ "README.md" ];
            licenses = [ "LICENSE" ];
          };
        }
      '';
      description = ''
        Configuration written to
        <filename>~/.config/vivid/filetypes.yml</filename>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "vivid/filetypes.yml" = mkIf (cfg.filetypes != { }) {
        source = configFile cfg.filetypes "filetypes";
      };
    } // mapAttrs' (
      name: value: nameValuePair
        ("vivid/themes/${name}.yml")
        ({source = configFile cfg.themes."${name}" name;})
    ) cfg.themes;
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.fonts;

  # The set of font categories, mapping directory names to option keys.
  categories = {
    monospace = "monospace";
    sans-serif = "sansSerif";
    serif = "serif";
    emoji = "emoji";
  };

  # A sizes attrset that uses __functor to fall back to `default` for any
  # program that doesn't have an explicit override.
  mkSizesFunctor =
    sizesAttr:
    let
      overrides = removeAttrs sizesAttr [ "default" ];
    in
    {
      inherit (sizesAttr) default;
      __functor = self: program: overrides.${program} or self.default;
    }
    // overrides;

  fontSubmodule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        example = "IosevkaTerm Nerd Font";
        description = "The font family name as known to fontconfig";
      };

      package = mkOption {
        type = types.package;
        example = "pkgs.nerd-fonts.iosevka-term";
        description = "The Nix package providing the font";
      };

      styles = {
        normal = mkOption {
          type = types.str;
          default = "Regular";
          description = "The normal font style";
        };

        bold = mkOption {
          type = types.str;
          default = "Bold";
          description = "The bold font style";
        };

        italic = mkOption {
          type = types.str;
          default = "Italic";
          description = "The italic font style";
        };

        boldItalic = mkOption {
          type = types.str;
          default = "Bold Italic";
          description = "The bold italic font style";
        };
      };

      sizes = mkOption {
        type = types.attrsOf types.float;
        example = {
          default = 16.5;
          ghostty = 14.0;
        };
        description = ''
          Font sizes keyed by program name, with a mandatory `default` entry.
          Accessed as a functor: `font.sizes "ghostty"` returns the
          ghostty-specific size if defined, otherwise the default.
        '';
      };
    };
  };

  # Auto-discover font .nix files in a category directory.
  discoverNames =
    dir:
    builtins.readDir dir
    |> attrNames
    |> filter (n: hasSuffix ".nix" n && n != "default.nix")
    |> map (removeSuffix ".nix");

  # Auto-discover stack names.
  stackNames = discoverNames ./stacks;

  mkStackOption =
    stackName:
    mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption stackName;

          name = mkOption {
            type = types.str;
            default = stackName;
            readOnly = true;
            description = "The name of the font stack";
          };

          fonts = mkOption {
            type = types.attrsOf types.str;
            default = import ./stacks/${stackName}.nix;
            readOnly = true;
            description = ''
              Mapping from category to font name, e.g.
              `{ monospace = "iosevka-term"; sansSerif = "iosevka-aile"; ... }`.
            '';
          };
        };
      };
      default = { };
    };

  stackOptions =
    stackNames
    |> map (name: nameValuePair name (mkStackOption name))
    |> listToAttrs;
in
{
  # Import all individual font modules from category directories.
  imports =
    categories
    |> mapAttrsToList (
      dirName: _categoryKey:
      let
        dir = ./${dirName};
        names = discoverNames dir;
      in
      map (n: dir + "/${n}.nix") names
    )
    |> concatLists;

  options.modules.fonts = stackOptions // {
    # Per-category lists of all declared fonts. Individual font modules append
    # to these via `config.modules.fonts.<category>`.
    monospace = mkOption {
      type = types.attrsOf fontSubmodule;
      default = { };
      description = "All declared monospace fonts";
    };

    sansSerif = mkOption {
      type = types.attrsOf fontSubmodule;
      default = { };
      description = "All declared sans-serif fonts";
    };

    serif = mkOption {
      type = types.attrsOf fontSubmodule;
      default = { };
      description = "All declared serif fonts";
    };

    emoji = mkOption {
      type = types.attrsOf fontSubmodule;
      default = { };
      description = "All declared emoji fonts";
    };

    current = mkOption {
      type = types.attrs;
      readOnly = true;
      description = "The resolved font configuration for the enabled stack";
    };
  };

  config =
    let
      enabledStacks =
        removeAttrs cfg [
          "current"
          "monospace"
          "sansSerif"
          "serif"
          "emoji"
        ]
        |> mapAttrsToList (_: v: v)
        |> filter (s: s.enable);

      enabledStack = head enabledStacks;
      stackDef = enabledStack.fonts;

      # All declared fonts merged into a single flat attrset. This allows
      # stacks to reference fonts across categories (e.g. using a monospace
      # font for the sans-serif slot).
      allFonts = cfg.monospace // cfg.sansSerif // cfg.serif // cfg.emoji;

      resolveFont =
        fontName:
        let
          fontDef = allFonts.${fontName};
        in
        {
          inherit (fontDef) name package styles;
          sizes = mkSizesFunctor fontDef.sizes;
        };
    in
    {
      assertions = [
        {
          assertion = length enabledStacks == 1;
          message = "Exactly one font stack must be enabled";
        }
      ];

      modules.fonts.current = {
        name = enabledStack.name;
        monospace = resolveFont stackDef.monospace;
        sansSerif = resolveFont stackDef.sansSerif;
        serif = resolveFont stackDef.serif;
        emoji = resolveFont stackDef.emoji;
      };

      home.packages = unique [
        cfg.current.monospace.package
        cfg.current.sansSerif.package
        cfg.current.serif.package
        cfg.current.emoji.package
      ];

      fonts.fontconfig = {
        enable = pkgs.stdenv.isLinux;
        defaultFonts = {
          serif = [ cfg.current.serif.name ];
          sansSerif = [ cfg.current.sansSerif.name ];
          monospace = [ cfg.current.monospace.name ];
          emoji = [ cfg.current.emoji.name ];
        };
      };
    };
}

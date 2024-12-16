{
  pkgs,
  machine,
  colorscheme,
  palette,
  hexlib,
}:

let
  colors = import ./colors.nix { inherit colorscheme palette hexlib; };

  backgroundImageFilename = "backgroundImage.png";

  theme-file = pkgs.writeTextFile {
    name = "theme.txt";
    text = import ./theme.txt.nix {
      inherit colors backgroundImageFilename;
    };
  };

  backgroundImage = pkgs.stdenv.mkDerivation {
    name = "grub-background-image";
    src = ./.;
    installPhase = ''
      mkdir -p $out
      ${pkgs.graphicsmagick-imagemagick-compat}/bin/convert \
        -size 1920x1080 \
        xc:${colors.bg} \
        PNG32:$out/${backgroundImageFilename}
    '';
  };

  theme = pkgs.stdenv.mkDerivation {
    name = "grub-theme";
    src = ./.;
    installPhase = ''
      mkdir -p $out
      cp ${theme-file} $out/theme.txt
      cp -r ${./icons} $out/icons
      cp ${./fixedsys-regular-32.pf2} $out/fixedsys-regular-32.pf2

      cp \
        ${backgroundImage}/${backgroundImageFilename} \
        $out/${backgroundImageFilename}

      ${pkgs.graphicsmagick-imagemagick-compat}/bin/convert \
        -size 1x1 \
        xc:${colors.boot-entry.selected.bg} \
        PNG32:$out/selected-entry-bg-c.png
    '';
  };
in
{
  devices = [ "nodev" ];
  efiSupport = true;
  useOSProber = true;
  gfxmodeEfi = "1920x1080";
  gfxmodeBios = "1920x1080";
  splashImage = "${backgroundImage}/${backgroundImageFilename}";
  inherit theme;
}

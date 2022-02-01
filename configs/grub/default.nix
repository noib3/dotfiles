{ pkgs, colorscheme, palette, hexlib }:

let
  colors = import ./colors.nix { inherit colorscheme palette hexlib; };

  theme-file = pkgs.writeTextFile {
    name = "theme.txt";
    text = import ./theme.txt.nix {
      inherit colors;
    };
  };
in
pkgs.stdenv.mkDerivation {
  name = "grub-theme";
  src = ./.;
  installPhase = ''
    mkdir -p $out
    cp ${theme-file} $out/theme.txt
    cp -r ${./icons} $out/icons
    cp ${./fixedsys-regular-32.pf2} $out/fixedsys-regular-32.pf2

    ${pkgs.graphicsmagick-imagemagick-compat}/bin/convert \
      -size 1920x1080 \
      xc:${colors.bg} \
      PNG32:$out/background.png

    ${pkgs.graphicsmagick-imagemagick-compat}/bin/convert \
      -size 1x1 \
      xc:${colors.boot-entry.selected.bg} \
      PNG32:$out/selected-entry-bg-c.png
  '';
  # cp ${background-image} $out/background.png
}

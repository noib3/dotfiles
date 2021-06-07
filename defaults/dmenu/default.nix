{ pkgs, stdenv, libX11, libXinerama, libXft, zlib, colors, font }:
let
  colors-font = pkgs.writeText "dmenu-colors-font.diff"
    (import ./patches/dmenu-colors-font.diff.nix {
      inherit colors;
      inherit font;
    });
in
stdenv.mkDerivation rec {
  name = "dmenu-5.0";

  src = ./src;

  buildInputs = [ libX11 libXinerama zlib libXft ];

  patches = [
    colors-font
  ];

  postPatch = ''
    sed -ri -e 's!\<(dmenu|dmenu_path|stest)\>!'"$out/bin"'/&!g' dmenu_run
    sed -ri -e 's!\<stest\>!'"$out/bin"'/&!g' dmenu_path
  '';

  preConfigure = ''
    sed -i "s@PREFIX = /usr/local@PREFIX = $out@g" config.mk
  '';

  makeFlags = [ "CC:=$(CC)" ];

  meta = with pkgs.lib; {
    description = "A generic, highly customizable, and efficient menu for the X Window System";
    homepage = "https://tools.suckless.org/dmenu";
    license = licenses.mit;
    platforms = platforms.all;
  };
}

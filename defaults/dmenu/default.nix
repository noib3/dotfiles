{ pkgs, font, colors, cmd ? "dmenu", args ? "" }:
let
  dmenu = pkgs.dmenu.override ({
    patches =
      let
        case-insensitive = pkgs.fetchurl {
          url = "https://tools.suckless.org/dmenu/patches/case-insensitive/dmenu-caseinsensitive-20200523-db6093f.diff";
          sha256 = "0f2w183qr0p9v2cgc4ak1n3g85jpnsxanjhsyhwxf3cvrphhil9i";
        };

        highlight = pkgs.fetchurl {
          url = "https://tools.suckless.org/dmenu/patches/highlight/dmenu-highlight-4.9.diff";
          sha256 = "0q21igv9i8pwhmbnvz6xmg63vm340ygriqn4xmf2bzvdn5hkfijg";
        };

        password = pkgs.fetchurl {
          url = "https://tools.suckless.org/dmenu/patches/password/dmenu-password-5.0.diff";
          sha256 = "1dqxiwwwbya9slm3xbbal564rnigfbr497kac9pxlikjqgpz9a1q";
        };
      in
      [
        # case-insensitive
        highlight
        password
      ];
  });
in
''
  #!/usr/bin/env sh
  ${dmenu}/bin/${cmd} \
    -fn '${font.family}:pixelsize=${font.size}' \
    -nb '${colors.normal.background}' \
    -nf '${colors.normal.foreground}' \
    -sb '${colors.selected.background}' \
    -sf '${colors.selected.foreground}' \
    ${args} "$@"
''

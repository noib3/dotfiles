{ pkgs }:

pkgs.writeShellApplication {
  name = "preview";

  runtimeInputs =
    with pkgs;
    [
      # Contains `als`, used for archives.
      atool
      bat
      chafa
      coreutils
      ffmpegthumbnailer
      file
      gawk
      gnugrep
      gnupg
      # Used for SVGs.
      inkscape
      # Used for audios.
      mediainfo
      # Contains `convert`.
      imagemagick_light
      # Contains `pdftoppm`, used for PDFs.
      poppler-utils
    ]
    ++ pkgs.lib.lists.optionals (!pkgs.stdenv.isDarwin) [
      # Contains `ebook-meta`, used for epubs.
      calibre
      ueberzugpp
    ];

  text = ''
    ${builtins.readFile ./preview-common.sh}
    ${builtins.readFile ./preview.sh}
  '';
}

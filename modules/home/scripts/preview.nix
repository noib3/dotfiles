{ pkgs }:

with pkgs.lib;
pkgs.writeShellApplication {
  name = "preview";

  runtimeInputs =
    with pkgs;
    [
      # Contains `als`, used for archives.
      atool
      bat
      chafa
      ffmpegthumbnailer
      file
      # Used for SVGs.
      inkscape
      # Used for audios.
      mediainfo
      # Contains `convert`.
      imagemagick_light
      # Used for videos.
      mkvtoolnix-cli
      # Contains `pdftoppm`, used for PDFs.
      poppler-utils
    ]
    ++ lib.lists.optionals (!pkgs.stdenv.isDarwin) [
      # Contains `ebook-meta`, used for epubs.
      calibre
      ueberzugpp
    ];

  text = ''
    # if [ $# -ne 1 ]; then
    #   echo "error: expected a file path as the only argument"
    #   exit 1
    # fi
    #
    # if [ ! -f "$1" ]; then
    #   echo "error: the argument is not a path to a file"
    #   exit 1
    # fi

    ${builtins.readFile ./preview.sh}
  '';
}

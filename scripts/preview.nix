{ pkgs }:

pkgs.writeShellApplication {
  name = "preview";

  runtimeInputs = with pkgs; [
    # Contains `als`, used for archives.
    atool
    bat
    # Contains `ebook-meta`, used for epubs.
    calibre
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
    poppler_utils
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

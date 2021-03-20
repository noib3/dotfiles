{ pkgs ? import <nixpkgs> }:

{
  commands = {
    open = ''
      ''${{
        text_files=()
        image_files=()
        for file in $fx; do
          case $(file -Lb --mime-type $file) in
            text/*|application/json|inode/x-empty)
              text_files+=("$file")
              ;;
            image/*)
              setsid -f sxiv "$file"
              # image_files+=("$file")
              ;;
            video/*)
              setsid -f mpv --no-terminal "$file"
              ;;
            application/pdf)
              setsid -f zathura "$file"
              ;;
          esac
        done
        [[ ''${#text_files[@]} -eq 0 ]] || $EDITOR "''${text_files[@]}"
        [[ ''${#image_files[@]} -eq 0 ]] || setsid -f sxiv "''${text_files[@]}"
      }}
    '';
  };

  #previewer.source = pkgs.writeShellScript "pv.sh" ''
  #  #!/usr/bin/env bash

  #  FILE="$1"

  #  function text_preview() {
  #    bat "$FILE"
  #  }

  #  function pdf_preview() {
  #    pdftotext "$FILE" -
  #  }

  #  function image_preview() {
  #    chafa --fill=block --symbols=block "$FILE"
  #  }

  #  function video_preview() {
  #    mediainfo "$FILE"
  #  }

  #  function audio_preview() {
  #    mediainfo "$FILE"
  #  }

  #  function fallback_preview() {
  #    text_preview
  #  }

  #  case "$(file -b --mime-type $FILE)" in
  #    text/*) text_preview ;;
  #    */pdf) pdf_preview ;;
  #    image/*) image_preview ;;
  #    video/*) video_preview ;;
  #    audio/*) audio_preview ;;
  #    *) fallback_preview ;;
  #  esac
  #'';
}

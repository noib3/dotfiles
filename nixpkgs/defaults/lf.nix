{ pkgs }:

{
  settings = {
    dircounts = true;
    drawbox   = true;
    hidden    = true;
    ifs       = "\\n";
    info      = "size";
    period    = 1;
    shell     = "bash";
    timefmt   = "2006-Jan-02 at 15:04:05";
  };

  commands = {
    open = ''
      ''${{
        text_files=()
        for f in $fx; do
          case $(file -b --mime-type $f) in
            text/*|application/json|inode/x-empty) text_files+=("$f");;
          esac
        done
        [[ ''${#text_files[@]} -eq 0 ]] || $EDITOR "''${text_files[@]}"
      }}
    '';

    touch     = ''%touch "$@"   ; lf -remote "send $id select \"$@\""'';
    mkdir     = ''%mkdir -p "$@"; lf -remote "send $id select \"$@\""'';
    give_ex   = ''%chmod +x $fx ; lf -remote "send $id reload"'';
    remove_ex = ''%chmod -x $fx ; lf -remote "send $id reload"'';

    fuzzy_edit = ''
      ''${{
        clear
        filename="$(fzf --prompt="Edit> " --multi --height=8)" \
          && $EDITOR "''${HOME}/''${filename}" \
          || true
      }}
    '';

    fuzzy_cd = ''
      ''${{
        clear
        dirname="$(eval $(echo $FZF_ONLYDIRS_COMMAND) \
                    | fzf --prompt="Cd> " --height=8)" \
          && dirname="$(echo ''${dirname} | sed 's/\ /\\\ /g')" \
          && lf -remote "send $id cd ~/''${dirname}" \
          || true
      }}
    '';
  };

  keybindings = {
    m            = null;
    u            = null;
    x            = "cut";
    d            = "delete";
    "<enter>"    = "push $";
    t            = "push :touch<space>";
    k            = "push :mkdir<space>";
    "+"          = "make_executable";
    "-"          = "remove_executable";
    "<c-x><c-e>" = "fuzzy_edit";
    "<c-x><c-d>" = "fuzzy_cd";
  };

  cmdKeybindings = {
    "<up>"   = "cmd-history-prev";
    "<down>" = "cmd-history-next";
  };

  previewer.source = pkgs.writeShellScript "pv.sh" ''
    #!/usr/bin/env bash

    FILE="$1"

    function text_preview() {
      bat "$FILE"
    }

    function pdf_preview() {
      pdftotext "$FILE" -
    }

    function image_preview() {
      chafa --fill=block --symbols=block "$FILE"
    }

    function video_preview() {
      mediainfo "$FILE"
    }

    function audio_preview() {
      mediainfo "$FILE"
    }

    function fallback_preview() {
      text_preview
    }

    case "$(file -b --mime-type $FILE)" in
      text/*) text_preview ;;
      */pdf) pdf_preview ;;
      image/*) image_preview ;;
      video/*) video_preview ;;
      audio/*) audio_preview ;;
      *) fallback_preview ;;
    esac
  '';
}

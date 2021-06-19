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
            application/gzip)
              tar -xvzf "$file"
              ;;
            application/xtar)
              tar -xvf "$file"
              ;;
            application/zip)
              unzip "$file"
              ;;
          esac
        done
        [[ ''${#text_files[@]} -eq 0 ]] || $EDITOR "''${text_files[@]}"
        [[ ''${#image_files[@]} -eq 0 ]] || setsid -f sxiv "''${text_files[@]}"
      }}
    '';

    unmount_device = ''
      %{{
        udisksctl unmount -b "/dev/disk/by-label/''$(basename "$f")" \
          && udisksctl power-off -b "/dev/disk/by-label/''$(basename "$f")"
      }}
    '';

    drag_and_drop = ''%dragon -a -x $fx'';
  };

  keybindings = {
    unm = "unmount_device";
    ag = "drag_and_drop";
    gdl = "cd ~/Downloads";
    gvl = "cd /run/media/noib3";
  };
}

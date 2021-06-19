{
  commands = {
    open = ''
      ''${{
        text_files=()
        image_files=()
        for f in $fx; do
          case $(file -Lb --mime-type $f) in
            text/*|application/json|inode/x-empty) text_files+=("$f");;
            image/*) image_files+=("$f");;
            video/*) open -n "$f";;
            *) open "$f" &>/dev/null;;
          esac
        done
        [[ ''${#text_files[@]} -eq 0 ]]  || $EDITOR "''${text_files[@]}"
        [[ ''${#image_files[@]} -eq 0 ]] || open "''${image_files[@]}"
      }}
    '';

    open_pdf_with_preview = ''
      ''${{
        for f in $fx; do
          [[ $(head -c 4 $f) != "%PDF" ]] || open -a Preview "$f"
        done
      }}
    '';

    set_wallpaper = ''
      ''${{
        [[ $(file -b --mime-type "$f") == image/* ]] \
          && osascript -e \
              "tell application \"Finder\" to set desktop picture to POSIX file \
                \"$f\"" &>/dev/null \
          && lf -remote "send $id echo '\033[32mWallpaper set correctly\033[0m'" \
          || lf -remote "send $id echoerr 'Error: could not set wallpaper'"
        osascript -e "quit app \"Finder\"" &>/dev/null
      }}
    '';

    unmount_device = ''$clear && unmount_device'';
  };

  keybindings = {
    P = "open_pdf_with_preview";
    unm = "unmount_device";
    gdl = "cd ~/Downloads";
    gvl = "cd /Volumes";
    s = "set_wallpaper";
  };
}

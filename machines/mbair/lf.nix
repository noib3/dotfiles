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
          && lf -remote "send $id echo \"\033[32mWallpaper set correctly\033[0m\"" \
          || lf -remote "send $id echoerr 'Error: could not set wallpaper'"
        osascript -e "quit app \"Finder\"" &>/dev/null
      }}
    '';

    eject_disk = ''
      ''${{
        clear
        space_left=$( \
          diskutil info "$f" 2>/dev/null \
          | sed -n "s/.*Volume Free Space:\s*//p" \
          | awk '{print $1, $2}'\
        )
        diskutil eject "$f" &>/dev/null \
          && lf -remote \
              "send $id echo \"\033[32m$(basename $f) has been ejected\
      properly\033[0m\"" \
          && terminal-notifier \
              -title "Disk ejected" \
              -subtitle "$(basename $f) has been ejected" \
              -message "There are ''${space_left} left on disk" \
              -appIcon "''${HOME}/.config/lf/hard-disk-icon.png" \
          || lf -remote "send $id echoerr 'Error: could not eject disk'"
      }}
    '';

    mount_ocean = ''
      ''${{
        mnt_dir="''${HOME}/ocean"
        mkdir "''${mnt_dir}"
        sshfs ocean: "''${mnt_dir}" -F "''${HOME}/.ssh/config" \
          && lf -remote "send $id cd ''${mnt_dir}" \
        lf -remote "send $id reload"
      }}
    '';

    unmount_ocean = ''
      ''${{
        mnt_dir="''${HOME}/ocean"
        lf -remote "send $id cd ''${HOME}"
        umount -f "''${mnt_dir}" && rm -rf "''${mnt_dir}"
        lf -remote "send $id reload"
      }}
    '';
  };

  keybindings = {
    P = "open_pdf_with_preview";
    s = "set_wallpaper";
    j = "eject_disk";
    mo = "mount_ocean";
    uo = "unmount_ocean";
    gvl = ''cd "/Volumes"'';
  };
}

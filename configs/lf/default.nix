{
  lib,
  pkgs,
}:

let
  inherit (pkgs.stdenv) isDarwin isLinux;
  preview = lib.getExe pkgs.scripts.preview;
  chmod = "${pkgs.uutils-coreutils-noprefix}/bin/chmod";
in
{
  enable = true;

  settings = {
    dircounts = true;
    drawbox = true;
    hidden = true;
    icons = true;
    ifs = "\\n";
    info = "size";
    period = 1;
    promptfmt = ''\033[33;1m%u\033[0m on \033[32;1m%h\033[0m in \033[36;1m%d\033[0m\033[1m%f\033[0m'';
    ratios = "1:2:2";
    shell = "bash";
    timefmt = "January 02, 2006 at 15:04:05";
  };

  commands = {
    open = ''
      ''${{
        text_files=()
        image_files=()
        for file in $fx; do
          case $(${pkgs.file}/bin/file -Lb --mime-type $file) in
            text/*|application/csv|application/javascript|application/json|application/x-pem-file|inode/x-empty)
              text_files+=("$file")
              ;;
            image/*)
              image_files+=("$file")
              ;;
    ''
    + (
      if isLinux then
        ''
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
        ''
      else if isDarwin then
        ''
          video/*)
            open -n "$f"
            ;;
          *)
            open "$f" &>/dev/null
            ;;
        ''
      else
        ""
    )
    + (
      let
        openImages = if isDarwin then "open" else "setsid -f feh";
      in
      ''
            esac
          done
          [[ ''${#text_files[@]} -eq 0 ]] || $EDITOR "''${text_files[@]}"
          [[ ''${#image_files[@]} -eq 0 ]] || ${openImages} "''${image_files[@]}"
        }}
      ''
    );

    # Override the built-in paste to use append "-copy-{n}" before the extension
    # if a file with the same name already exists in the destination, rather
    # than the default ".~{n}~" suffix.
    paste = ''
      %{{
        # Read the copy/cut buffer to get the mode and file list.
        files="''${XDG_DATA_HOME:-$HOME/.local/share}/lf/files"
        mode=$(head -1 "$files")
        list=$(tail -n +2 "$files")

        [ -n "$list" ] || exit 0

        # Given a destination path, return it as-is if nothing conflicts,
        # or append "-copy-{n}" (before the extension) until the name is
        # unique.
        gen_name() {
          local dest="$1"
          [ -e "$dest" ] || { echo "$dest"; return; }

          local dir base name ext n
          dir=$(dirname "$dest")
          base=$(basename "$dest")

          # Strip the leading dot so we split on the first dot that has
          # text before it.
          case "$base" in
            .*) prefix="."; rest="''${base#.}" ;;
            *)  prefix="";  rest="$base" ;;
          esac

          name="''${prefix}''${rest%%.*}"
          ext="''${rest#*.}"

          # Directories and extensionless files: append at the end.
          if [ -d "$dest" ] || [ "$ext" = "$rest" ]; then
            n=1
            while [ -e "$dir/''${base}-copy-''${n}" ]; do n=$((n + 1)); done
            echo "$dir/''${base}-copy-''${n}"
          else
            # Insert before the extension.
            n=1
            while [ -e "$dir/''${name}-copy-''${n}.''${ext}" ]; do n=$((n + 1)); done
            echo "$dir/''${name}-copy-''${n}.''${ext}"
          fi
        }

        while IFS= read -r src; do
          dest=$(gen_name "$PWD/$(basename "$src")")
          case "$mode" in
            copy) cp -r "$src" "$dest" ;;
            move) mv "$src" "$dest" ;;
          esac
        done <<< "$list"

        # Clear the buffer after a move so files can't be moved again.
        if [ "$mode" = "move" ]; then
          lf -remote "send $id clear"
        fi
      }}
    '';

    touch = ''%touch "$@"; lf -remote "send $id select '$@'"'';
    mkdir = ''%mkdir -p "$@"; lf -remote "send $id select '$@'"'';
    make-ex = ''%${chmod} -R u+x $fx; lf -remote "send $id reload"'';
    remove-ex = ''%${chmod} -R -x+X $fx; lf -remote "send $id reload"'';

    make-tarball = ''
      %{{
        dirname="$@"
        mkdir -p "$dirname"
        cp $fx "$dirname"
        tar -cvzf "$dirname.tar.gz" "$dirname"
        rm -rf "$dirname"
        lf -remote "send $id select '$dirname.tar.gz'"
      }}
    '';

    fuzzy-cd = ''
      ''${{
        clear
        dirname="$(eval "$FZF_ALT_C_COMMAND" | eval "fzf $FZF_ALT_C_OPTS")"
        [ -z "$dirname" ] || lf -remote "send $id cd '$HOME/$dirname'"
      }}
    '';

    fuzzy-edit = ''
      ''${{
        clear
        readarray -t filenames < <(\
          fzf --multi --prompt='Edit> ' --preview='${preview} ~/{}' \
            | sed -r "s!^!$HOME/!" \
        )
        [ ''${#filenames[@]} -eq 0 ] || $EDITOR "''${filenames[@]}"
      }}
    '';

    fuzzy-ripgrep = "$clear; fuzzy-ripgrep";

    unmount-device = (
      if isLinux then
        ''
          %{{
            udisksctl unmount -b "/dev/disk/by-label/''$(basename "$f")" \
              && udisksctl power-off -b "/dev/disk/by-label/''$(basename "$f")"
          }}
        ''
      else if isDarwin then
        ''
          %{{
            space_left=$(\
              diskutil info "$f" 2>/dev/null \
                | sed -n "s/.*Volume Free Space:\s*//p" \
                | awk '{print $1, $2}'
            )

            diskutil eject "$f" &>/dev/null \
              && lf -remote "send $id echo \"\033[32m$(basename $f) has been ejected properly\033[0m\"" \
              && terminal-notifier \
                  -title "Disk ejected" \
                  -subtitle "$(basename $f) has been ejected" \
                  -message "There are ''${space_left} left on disk" \
                  -appIcon "${builtins.toString ./hard-disk-icon.png}" \
              || lf -remote "send $id echoerr 'Error: could not eject disk'"
          }}
        ''
      else
        ""
    );
  }
  // (
    if isLinux then
      { drag-and-drop = "%${pkgs.xdragon}/bin/dragon -a -x $fx"; }
    else if isDarwin then
      {
        open-pdf-with-preview = ''
          ''${{
            for f in $fx; do
              [[ $(head -c 4 $f) != "%PDF" ]] || open -a Preview "$f"
            done
          }}
        '';
        set-wallpaper = ''
          ''${{
            [[ $(file -b --mime-type "$f") == image/* ]] \
              && osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$f\"" &>/dev/null \
              && lf -remote "send $id echo '\033[32mWallpaper set correctly\033[0m'" \
              || lf -remote "send $id echoerr 'Error: could not set wallpaper'"
            osascript -e "quit app \"Finder\"" &>/dev/null
          }}
        '';
      }
    else
      { }
  );

  keybindings = {
    m = null;
    u = null;
    l = null;
    d = "delete";
    k = "push :mkdir<space>";
    t = "push :touch<space>";
    x = "cut";
    "+" = "make-ex";
    "-" = "remove-ex";
    "<enter>" = "push $";
    "<c-x><c-d>" = "fuzzy-cd";
    "<c-x><c-e>" = "fuzzy-edit";
    "<c-x><c-r>" = "fuzzy-ripgrep";
    lg = "$lazygit";
    mtb = "push :make-tarball<space>";
    unm = "unmount-device";
  }
  // (
    if isLinux then
      {
        ag = "drag-and-drop";
        gvl = "cd /run/media/noib3";
      }
    else if isDarwin then
      {
        P = "open-pdf-with-preview";
        s = "set-wallpaper";
        gvl = "cd /Volumes";
      }
    else
      { }
  );

  cmdKeybindings = {
    "<up>" = "cmd-history-prev";
    "<down>" = "cmd-history-next";
  };

  previewer.source = preview;

  extraConfig =
    let
      cleaner = pkgs.writeShellApplication {
        name = "lf-kitty-cleaner";
        runtimeInputs = with pkgs; [ kitty.kitten ];
        text = builtins.readFile ./kitty-cleaner.sh;
      };
    in
    "set cleaner ${lib.getExe cleaner}";
}

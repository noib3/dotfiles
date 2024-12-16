{
  lib,
  pkgs,
}:

let
  inherit (pkgs.stdenv) isDarwin isLinux;

  cleaner =
    let
      pkg = pkgs.writeShellApplication {
        name = "lf-ueberzug-cleaner";
        runtimeInputs = with pkgs; [ ueberzugpp ];
        text = builtins.readFile ./ueberzug-cleaner.sh;
      };
    in
    "${pkg}/bin/${pkg.name}";

  preview = "${pkgs.scripts.preview}/bin/${pkgs.scripts.preview.name}";

  chmod = "${pkgs.uutils-coreutils-noprefix}/bin/chmod";
in
{
  enable = true;

  package = lib.mkIf (!isDarwin) (
    pkgs.hiPrio (
      pkgs.writeShellApplication {
        name = "lf";
        runtimeInputs = with pkgs; [
          lf
          ueberzugpp
        ];
        text = builtins.readFile ./ueberzug-launcher.sh;
      }
    )
  );

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

  commands =
    {
      open =
        ''
          ''${{
            text_files=()
            image_files=()
            for file in $fx; do
              case $(${pkgs.file}/bin/file -Lb --mime-type $file) in
                text/*|application/javascript|application/json|application/csv|inode/x-empty)
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

      fuzzy-ripgrep = ''$clear; fuzzy-ripgrep'';

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

  keybindings =
    {
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
  extraConfig = "set cleaner ${cleaner}";
}

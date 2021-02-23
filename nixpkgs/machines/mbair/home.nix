{ config, lib, pkgs, ... }:

let
  unstable = import <nixpkgs-unstable> { config = { allowUnfree = true; }; };
  theme     = "onedark";

  baseAlacrittyConfig    = import ./base/alacritty.nix;
  machineAlacrittyConfig = import ./machines/mbair/alacritty.nix;
  batConfig              = import ./base/bat.nix;
  baseFishConfig         = import ./base/fish.nix;
  machineFishConfig      = import ./machines/mbair/fish.nix;
  fzfConfig              = import ./base/fzf.nix;
  gitConfig              = import ./base/git.nix;
  starshipConfig         = import ./base/starship.nix;

in {
  home = {
    username = "noibe";
    homeDirectory = "/Users/noibe";
    stateVersion = "21.03";

    packages = with pkgs; [
      # auto-selfcontrol
      bash
      buku
      calcurse
      chafa
      coreutils
      direnv
      duti
      entr
      fd
      ffmpeg
      findutils
      # firefox
      # font-jetbrains-mono-nerd-font
      # font-roboto-mono-nerd-font
      # font-sf-mono-nerd-font
      gnused
      gotop
      jq
      lazygit
      # logitech-options
      # mactex-no-gui
      # mas
      # mysides
      mediainfo
      mpv
      neovim-nightly
      # nodejs
      # nordvpn
      openssh
      osxfuse
      # pdftotext
      pfetch
      (python39.withPackages(
        ps: with ps; [
          autopep8
          black
          flake8
          ipython
          isort
          jedi
        ]
      ))
      # redshift
      rsync
      # selfcontrol
      # skhd
      # skim
      # spacebar
      # ookla-speedtest
      # sshfs
      # syncthing
      # tastyworks
      # tccutil
      terminal-notifier
      transmission-remote-cli
      vivid
      wget
      xmlstarlet
      # yabai
    ];

    sessionVariables = {
      COLORTERM    = "truecolor";
      EDITOR       = "nvim";
      HISTFILE     = "$HOME/.cache/bash/bash_history";
      MANPAGER     = "nvim -c 'set ft=man' -";
      LANG         = "en_US.UTF-8";
      LC_ALL       = "en_US.UTF-8";
      LESSHISTFILE = "$HOME/.cache/less/lesshst";
      LS_COLORS    = "$(vivid generate ${theme})";
      PRIVATEDIR   = "$HOME/Sync/private";
      SCRSHOTDIR   = "$HOME/Sync/screenshots";
      SCRIPTSDIR   = "$HOME/Sync/scripts";

      FZF_ONLYDIRS_COMMAND = "fd --base-directory=$HOME --hidden --type=d --color=always";
    };
  };

  nixpkgs = {
    config = {
      allowUnsupportedSystem = true;
    };

    overlays = [
      (self: super: {
        direnv = unstable.direnv;
        fzf = unstable.fzf;
        lf = unstable.lf;
        python39 = unstable.python39;
        starship = unstable.starship;
      })
      (import (builtins.fetchTarball {
        url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
      }))
    ];
  };

  programs.home-manager.enable = true;

  programs.alacritty = {
    enable = true;
    settings = (
      lib.attrsets.recursiveUpdate baseAlacrittyConfig machineAlacrittyConfig
    );
  };

  programs.bat = {
    enable = true;
    config = batConfig;
  };

  programs.fish = {
    enable = true;

    shellAliases = {
      ls = "ls -Alhv --color --file-type --group-directories-first --quoting-style=literal";
      grep = "grep --ignore-case --color=auto";
      wget = "wget --hsts-file=~/.cache/wget/wget-hsts";
      ipython = "ipython --no-confirm-exit";
      cat = "bat";
      reboot = ''osascript -e "tell app \"System Events\" to restart"'';
      shutdown = ''osascript -e "tell app \"System Events\" to shut down"'';
    };

    shellAbbrs = {
      ipy = "ipython";
      lg = "lazygit";
      hms = "home-manager switch";
      hmn = "home-manager news";
      psh = "peek push";
      pll = "peek pull";
    };

    interactiveShellInit = ''
      set fish_greeting

      set fish_cursor_default block
      set fish_cursor_insert line
      set fish_cursor_replace_one underscore
      set fish_cursor_visual block

      switch $COLORSCHEME
        case afterglow
          set gray 797979
          set cyan b05279
          set selection_background 5a647e
          set -x fzf_color_bgplus "#242424"
        case gruvbox
          set gray 928374
          set cyan 689d6a
          set selection_background 665c54
          set -x fzf_color_bgplus "#323232"
        case onedark
          set gray 5c6073
          set cyan 56b6c2
          set selection_background 5a647e
          set -x fzf_color_bgplus "#32363e"
      end

      set -x FZF_DEFAULT_OPTS \
        $FZF_DEFAULT_OPTS" --color='bg+:$fzf_color_bgplus'"

      set fish_color_user green
      set fish_color_host white
      set fish_color_host_remote white
      set fish_color_cwd blue
      set fish_color_command green
      set fish_color_error red
      set fish_color_quote yellow
      set fish_color_param $cyan
      set fish_color_operator $cyan
      set fish_color_autosuggestion $gray --italics
      set fish_color_comment $gray --italics
      set fish_color_valid_path --underline
      set fish_color_redirection white
      set fish_color_end cyan
      set fish_color_selection --background=$selection_background

      fish_vi_key_bindings

      bind \cA beginning-of-line
      bind \cE end-of-line
      bind yy fish_clipboard_copy
      bind Y fish_clipboard_copy
      bind p fish_clipboard_paste

      bind -M visual \cA beginning-of-line
      bind -M visual \cE end-of-line

      bind -M insert \cA beginning-of-line
      bind -M insert \cE end-of-line
      bind -M insert \e\x7F backward-kill-word
      bind -M insert \cW exit
      bind -M insert \cX\cD fuzzy_cd
      bind -M insert \cX\cE fuzzy_edit
      bind -M insert \cX\cF fuzzy_history
      bind -M insert \cS fuzzy_search
      bind -M insert \cG clear_no_scrollback

      function __reset_cursor_line --on-event="fish_prompt"
        printf "\e[5 q"
      end

      set dircolor \
        (echo $LS_COLORS | sed 's/\(^\|.*:\)di=\([^:]*\).*/\2/')
      set fgodcolor \
        (echo $LS_COLORS | sed 's/\(^\|.*:\)\*\.fgod=\([^:]*\).*/\2/')

      set FZF_DEFAULT_COMMAND_EXT \
        "| sed 's/\x1b\["$dircolor"m/\x1b\["$fgodcolor"m/g'"
      set FZF_ONLYDIRS_COMMAND_EXT $FZF_DEFAULT_COMMAND_EXT \
        "| sed 's/\(.*\)\x1b\["$fgodcolor"m/\1\x1b\["$dircolor"m/'"

      set -x FZF_DEFAULT_COMMAND $FZF_DEFAULT_COMMAND $FZF_DEFAULT_COMMAND_EXT
      set -x FZF_ONLYDIRS_COMMAND $FZF_ONLYDIRS_COMMAND $FZF_ONLYDIRS_COMMAND_EXT

      bass source ~/.nix-profile/etc/profile.d/nix{,-daemon}.sh

      direnv hook fish | source
    '';

    plugins = [
      {
        name = "bass";
        src = pkgs.fetchFromGitHub {
          owner = "edc";
          repo = "bass";
          rev = "2fd3d2157d5271ca3575b13daec975ca4c10577a";
          sha256 = "0mb01y1d0g8ilsr5m8a71j6xmqlyhf8w4xjf00wkk8k41cz3ypky";
        };
      }
      {
        name = "pisces";
        src = pkgs.fetchFromGitHub {
          owner = "laughedelic";
          repo = "pisces";
          rev = "v0.7.0";
          sha256 = "073wb83qcn0hfkywjcly64k6pf0d7z5nxxwls5sa80jdwchvd2rs";
        };
      }
    ];

    functions = {
      clear_no_scrollback.body = ''
        clear && printf "\e[3J"
        commandline --function repaint
      '';

      fuzzy_edit.body = ''
        set -l filenames (fzf --prompt="Edit> " --multi --height=8) \
          && set -l filenames (
            echo "~/"(string escape -- $filenames) | tr "\n" " " | sed 's/\s$//'
          ) \
          && commandline $EDITOR" "$filenames \
          && commandline --function execute
        commandline --function repaint
      '';

      fuzzy_cd.body = ''
        set -l dirname (
          eval (echo $FZF_ONLYDIRS_COMMAND) | fzf --prompt="Cd> " --height=8
        ) \
          && cd $HOME/$dirname
        emit fish_prompt
        commandline -f repaint
      '';

      fuzzy_history.body = ''
        history merge
        set -l command_with_timestamps (
          history --null --show-time="%m/%e %H:%M:%S | " \
            | fzf --read0 --tiebreak=index --prompt="History> " --height=8 \
            | string collect \
        ) \
          && set -l command (string split -m1 " | " $command_with_timestamps)[2] \
          && commandline $command
        commandline --function repaint
      '';

      fuzzy_search.body = ''
        set -l filenames (fzf --prompt="Paste> " --multi --height=8) \
          && set -l filenames (
            echo "~/"(string escape -- $filenames) | tr "\n" " " | sed 's/\s$//'
          ) \
          && commandline --insert $filenames
        commandline --function repaint
      '';
    };
  };

  programs.fzf = lib.attrsets.recursiveUpdate fzfConfig {
    enable = true;
  };

  programs.git = lib.attrsets.recursiveUpdate gitConfig {
    enable = true;
  };

  programs.lf = {
    enable = true;

    settings = {
      dircounts = true;
      drawbox = true;
      hidden = true;
      ifs = "\\n";
      info = "size";
      period = 1;
      shell = "bash";
      timefmt = "2006-Jan-02 at 15:04:05";
    };

    commands = {
      open = ''
        ''${{
          text_files=()
          image_files=()
          for f in $fx; do
            case $(file -b --mime-type $f) in
              text/*|application/json|inode/x-empty) text_files+=("$f");;
            esac
          done
          [[ ''${#image_files[@]} -eq 0 ]] || open "''${image_files[@]}"
          [[ ''${#text_files[@]} -eq 0 ]] || $EDITOR "''${text_files[@]}"
        }}
      '';
      open_pdf_with_preview = ''
        ''${{
          for f in $fx; do
            [[ $(head -c 4 $f) != "%PDF" ]] || open -a Preview "$f"
          done
        }}
      '';
      touch = ''%touch "$@"; lf -remote "send $id select \"$@\""'';
      mkdir = ''%mkdir -p "$@"; lf -remote "send $id select \"$@\""'';
      make_executable = ''%chmod +x $fx; lf -remote "send $id reload"'';
      remove_executable = ''%chmod -x $fx; lf -remote "send $id reload"'';
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
                "send $id echo \"\033[32m$(basename $f) has been properly \
        ejected\033[0m\"" \
            && terminal-notifier \
                -title "Disk ejected" \
                -subtitle "$(basename $f) has been ejected" \
                -message "There are ''${space_left} left on disk" \
                -appIcon "''${HOME}/.config/lf/hard-disk-icon.png" \
            || lf -remote "send $id echoerr 'Error: could not eject disk'"
        }}
      '';
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
          dirname="$(eval $(echo $FZF_ONLYDIRS_COMMAND) | \
                      fzf --prompt="Cd> " --height=8)" \
            && dirname="$(echo ''${dirname} | sed 's/\ /\\\ /g')" \
            && lf -remote "send $id cd ~/''${dirname}" \
            || true
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
      m = null;
      u = null;
      x = "cut";
      d = "delete";
      "<enter>" = "push $";
      t = "push :touch<space>";
      k = "push :mkdir<space>";
      P = "open_pdf_with_preview";
      "+" = "make_executable";
      "-" = "remove_executable";
      s = "set_wallpaper";
      j = "eject_disk";
      "<c-x><c-e>" = "fuzzy_edit";
      "<c-x><c-d>" = "fuzzy_cd";
      mo = "mount_ocean";
      uo = "unmoune_ocean";
      gvl = ''cd "/Volumes"'';
    };

    cmdKeybindings = {
      "<up>" = "cmd-history-prev";
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
  };

  programs.starship = {
    enable = true;
    settings = starshipConfig;
  };
}

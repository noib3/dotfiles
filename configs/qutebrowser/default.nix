{
  config,
  lib,
  pkgs,
  colorscheme,
  palette,
}:

let
  colors = import ./colors.nix { inherit colorscheme lib palette; };

  add-torrent = pkgs.writeShellScriptBin "add-torrent" (builtins.readFile ./scripts/add-torrent.sh);

  fill-bitwarden = pkgs.writers.writePython3Bin "fill-bitwarden" {
    libraries = [ pkgs.python310Packages.tldextract ];
  } (builtins.readFile ./scripts/fill-bitwarden.py);

  homePage = "https://start.duckduckgo.com";
in
{
  enable = pkgs.stdenv.isLinux;

  package = lib.mkIf pkgs.stdenv.isLinux (
    pkgs.qutebrowser.override {
      enableWideVine = true;
    }
  );

  searchEngines = {
    "DEFAULT" = "https://duckduckgo.com/?q={}";
    "yt" = "https://youtube.com/results?search_query={}";
    "nixo" = "https://search.nixos.org/options?channel=unstable&query={}";
    "nixp" = "https://search.nixos.org/packages?channel=unstable&query={}";
  };

  settings = {
    # https://qutebrowser.org/doc/help/settings.html#auto_save.session.
    auto_save.session = true;

    colors = {
      tabs = {
        odd.bg = colors.tabs.unfocused.bg;
        odd.fg = colors.tabs.unfocused.fg;
        even.bg = colors.tabs.unfocused.bg;
        even.fg = colors.tabs.unfocused.fg;
        selected.odd.bg = colors.tabs.focused.bg;
        selected.odd.fg = colors.tabs.focused.fg;
        selected.even.bg = colors.tabs.focused.bg;
        selected.even.fg = colors.tabs.focused.fg;
        indicator.error = colors.tabs.indicator.error;
        indicator.start = colors.tabs.indicator.start;
        indicator.stop = colors.tabs.indicator.stop;
      };

      hints = {
        bg = colors.hints.bg;
        fg = colors.hints.fg;
        match.fg = colors.hints.match.fg;
      };

      completion = {
        category.bg = colors.completion.header.bg;
        category.fg = colors.completion.header.fg;
        category.border.top = colors.completion.header.bg;
        category.border.bottom = colors.completion.header.bg;

        odd.bg = colors.completion.odd.bg;
        even.bg = colors.completion.even.bg;

        fg = [
          colors.completion.fg
          colors.completion.urls.fg
          colors.completion.fg
        ];

        match.fg = colors.completion.match.fg;

        item.selected.bg = colors.completion.selected.bg;
        item.selected.border.top = colors.completion.selected.bg;
        item.selected.border.bottom = colors.completion.selected.bg;
        item.selected.fg = colors.completion.selected.fg;
        item.selected.match.fg = colors.completion.selected.match.fg;
      };

      statusbar = {
        command = {
          bg = colors.statusbar.bg;
          fg = colors.statusbar.fg;
          private.bg = colors.statusbar.private.bg;
          private.fg = colors.statusbar.private.fg;
        };
        insert = {
          bg = colors.statusbar.insert.bg;
          fg = colors.statusbar.insert.fg;
        };
        normal = {
          bg = colors.statusbar.bg;
          fg = colors.statusbar.fg;
        };
        passthrough = {
          bg = colors.statusbar.passthrough.bg;
          fg = colors.statusbar.passthrough.fg;
        };
        private = {
          bg = colors.statusbar.private.bg;
          fg = colors.statusbar.private.fg;
        };
        url = {
          fg = colors.statusbar.url.fg;
          hover.fg = colors.statusbar.url.hover.fg;
          success.http.fg = colors.statusbar.url.success.http.fg;
          success.https.fg = colors.statusbar.url.success.https.fg;
          warn.fg = colors.statusbar.url.warn.fg;
          error.fg = colors.statusbar.url.error.fg;
        };
      };

      messages = {
        info = {
          bg = colors.statusbar.bg;
          fg = colors.statusbar.fg;
          border = colors.statusbar.bg;
        };

        error = {
          bg = colors.messages.error.bg;
          fg = colors.messages.error.fg;
          border = colors.messages.error.bg;
        };
      };
    };

    completion = {
      height = "21%";
      open_categories = [ "history" ];
      scrollbar = {
        padding = 0;
        width = 0;
      };
      show = "always";
      shrink = true;
      timestamp_format = "";
    };

    content = {
      autoplay = false;
      javascript.clipboard = "access";
      pdfjs = true;
    };

    downloads = {
      position = "bottom";
      remove_finished = 3000;
    };

    fileselect = {
      handler = "external";
      multiple_files.command = [
        "alacritty"
        "--embed"
        "$(xdotool getactivewindow)"
        "-e"
        "lf"
        "-selection-path"
        "{}"
      ];
      single_file.command = [
        "alacritty"
        "--embed"
        "$(xdotool getactivewindow)"
        "-e"
        "lf"
        "-selection-path"
        "{}"
      ];
    };

    fonts =
      let
        font = config.fonts.serif;
      in
      {
        default_family = font.name;
        default_size = toString (font.size config "qutebrowser") + "pt";
      };

    hints = {
      border = "none";
      radius = 1;
    };

    scrolling = {
      bar = "never";
      smooth = true;
    };

    statusbar = {
      widgets = [
        "keypress"
        "text: "
        "search_match"
        "text:  "
        "url"
        "text: "
        "scroll"
        "text: "
        "history"
        "text: "
      ];
    };

    tabs = {
      close_mouse_button = "right";
      last_close = "close";
      mode_on_change = "restore";
      mousewheel_switching = false;
      title.format = "{perc}{audio}{index}: {current_title}";
    };

    url = {
      default_page = homePage;
      start_pages = [ homePage ];
    };

    zoom.default = "130%";
  };

  keyMappings = {
    "<Super-l>" = "o";
    "<Super-t>" = "O";
  };

  keyBindings = {
    normal = {
      ",p" = "tab-move -";
      ",n" = "tab-move +";

      "<Super-r>" = "config-source";

      "<Super-c>" = "fake-key <Ctrl-c>";

      "<Super-Up>" = "scroll-to-perc 0";
      "<Super-Down>" = "scroll-to-perc";
      "<Super-Left>" = "back";
      "<Super-Right>" = "forward";

      "<Super-n>" = "open -w";
      "<Super-Shift-n>" = "open -p";

      "<Super-w>" = "tab-close";
      "<Super-1>" = "tab-focus 1";
      "<Super-2>" = "tab-focus 2";
      "<Super-3>" = "tab-focus 3";
      "<Super-4>" = "tab-focus 4";
      "<Super-5>" = "tab-focus 5";
      "<Super-6>" = "tab-focus 6";
      "<Super-7>" = "tab-focus 7";
      "<Super-8>" = "tab-focus 8";
      "<Super-9>" = "tab-focus 9";
      "<Super-0>" = "tab-focus 10";

      ",f" = "spawn --userscript ${fill-bitwarden}/bin/fill-bitwarden";
      ",t" = "hint links userscript ${add-torrent}/bin/add-torrent";

      "gh" = "open ${homePage}";
      "th" = "open -t ${homePage}";

      "gtb" = "open https://github.com/noib3";
      "ttb" = "open -t https://github.com/noib3";

      "gma" = "open https://mail.protonmail.com/inbox";
      "tma" = "open -t https://mail.protonmail.com/inbox";

      "gkp" = "open https://keep.google.com";
      "tkp" = "open -t https://keep.google.com";

      "grhm" = "open https://github.com/nix-community/home-manager/find/master";
      "trhm" = "open -t https://github.com/nix-community/home-manager/find/master";

      "gnv" = "open https://github.com/neovim/neovim/tree/master/src/nvim";
      "tnv" = "open -t https://github.com/neovim/neovim/tree/master/src/nvim";

      "gbg" = "open https://rarbgunblocked.org/torrents.php";
      "tbg" = "open -t https://rarbgunblocked.org/torrents.php";

      "g12ft" = "open https://12ft.io/";
      "t12ft" = "open -t https://12ft.io/";

      "gtra" = "open http://localhost:9091/transmission/web/";
      "ttra" = "open -t http://localhost:9091/transmission/web/";
    };

    command = {
      "<Super-w>" = "tab-close";

      "<Super-c>" = "completion-item-yank";
      "<Super-v>" = "fake-key --global <Ctrl-v>";

      "<Super-Left>" = "rl-beginning-of-line";
      "<Super-Right>" = "rl-end-of-line";
      "<Alt-Backspace>" = "rl-backward-kill-word";
      "<Super-Backspace>" = "rl-unix-line-discard";
    };

    insert = {
      "<Super-w>" = "tab-close";

      "<Super-c>" = "fake-key <Ctrl-c>";
      "<Super-v>" = "fake-key <Ctrl-v>";
      "<Super-x>" = "fake-key <Ctrl-x>";
      "<Super-z>" = "fake-key <Ctrl-z>";

      "<Super-Left>" = "fake-key <Home>";
      "<Super-Right>" = "fake-key <End>";
      "<Alt-Backspace>" = "fake-key <Ctrl-Backspace>";
      "<Super-Backspace>" = "fake-key <Shift-Home><Delete>";

      "<Super-1>" = "tab-focus 1";
      "<Super-2>" = "tab-focus 2";
      "<Super-3>" = "tab-focus 3";
      "<Super-4>" = "tab-focus 4";
      "<Super-5>" = "tab-focus 5";
      "<Super-6>" = "tab-focus 6";
      "<Super-7>" = "tab-focus 7";
      "<Super-8>" = "tab-focus 8";
      "<Super-9>" = "tab-focus 9";
      "<Super-0>" = "tab-focus 10";
    };
  };

  extraConfig = ''
    c.statusbar.padding = { "top": 2, "bottom": 2, "left": 8, "right": 8 }
    c.tabs.padding = { "top": 2, "bottom": 2, "left": 8, "right": 8 }

    config.unbind("gm")
    config.unbind("gd")
    config.unbind("gb")
    config.unbind("tl")
    config.unbind("gt")
    config.load_autoconfig(True)
  '';
}

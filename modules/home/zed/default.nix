{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.zed;
in
{
  options.modules.zed = {
    enable = mkEnableOption "Zed";
  };

  config = mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      mutableUserSettings = false;
      themes = import ./themes;
      userKeymaps = {

      };
      userSettings =
        let
          buffer_font = config.fonts.monospace;
          preferred_line_length = 79;
        in
        {
          auto_update = false;
          autosave = "on_focus_change";
          buffer_font_family = buffer_font.name;
          buffer_font_size = buffer_font.size config "zed";
          current_line_highlight = "none";
          cursor_blink = false;
          diagnostics.inline.enabled = true;
          features.edit_prediction_provider = "copilot";
          git = {
            git_gutter = "hide";
            inline_blame.enabled = false;
          };
          go_to_definition_fallback = "none";
          gutter = {
            folds = false;
            line_numbers = true;
            min_line_number_digits = 2;
          };
          indent_guides.enabled = false;
          load_direnv = "shell_hook";
          on_last_window_closed = "quit_app";
          inherit preferred_line_length;
          preview_tabs.enabled = false;
          relative_line_numbers = true;
          scroll_beyond_last_line = "off";
          scrollbar = {
            cursors = false;
            git_diff = false;
            selected_symbols = false;
            selected_text = false;
          };
          search.button = false;
          seed_search_query_from_cursor = "selection";
          selection_highlight = false;
          show_whitespaces = "all";
          soft_wrap = "editor_width";
          status_bar = {
            active_language_button = false;
            cursor_position_button = false;
            line_endings_button = false;
          };
          tab_bar = {
            show_nav_history_buttons = false;
            show_tab_bar_buttons = false;
          };
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
          theme = "Gruvbox Material Dark";
          toolbar.quick_actions = false;
          use_smartcase_search = true;
          use_system_path_prompts = false;
          use_system_prompts = false;
          vim_mode = true;
          wrap_guides = [ preferred_line_length ];
        }
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          ui_font_family = ".SystemUIFont";
          use_system_window_tabs = true;
        };
    };
  };
}

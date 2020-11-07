function set_theme --description "Set fish's theme by sourcing a file \
in $THEME_DIR"
  if not set --query THEME_DIR
    set THEME_DIR ~/.config/fish/themes
  end
  source $THEME_DIR/$argv.fish
end

{ default }:

{
  settings = {
    window = {
      padding.x = 3;
      padding.y = 0;
    };

    key_bindings = [
      {
        key = "C";
        mods = "Super";
        action = "Copy";
      }
      {
        key = "V";
        mods = "Super";
        action = "Paste";
      }
    ] ++ default.settings.key_bindings;
  };
}

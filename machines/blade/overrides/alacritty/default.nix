{ default }:

{
  settings = {
    window = {
      padding.x = 7;
      padding.y = 2;
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

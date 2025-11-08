{
  config,
  pkgs,
  lib,
}:

let
  preferences = {
    brave.new_tab_page = {
      show_stats = false;
    };
  };

  profile = "Default";

  preferencesPath = "${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser/${profile}/Preferences";

  # Flatten nested attrset into list of [{path, value}].
  flattenPrefs =
    prefix: attrs:
    lib.concatLists (
      lib.mapAttrsToList (
        k: v:
        let
          newPrefix = prefix ++ [ k ];
        in
        if lib.isAttrs v then
          flattenPrefs newPrefix v
        else
          [
            {
              path = newPrefix;
              value = v;
            }
          ]
      ) attrs
    );

  prefUpdates = builtins.toJSON (flattenPrefs [ ] preferences);
in
''
  # Exit early if Preferences doesn't exist yet.
  [[ -f "${preferencesPath}" ]] || exit 0

  # Apply each preference update.
  $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
    --argjson updates '${prefUpdates}' \
    'reduce $updates[] as $update (.; setpath($update.path; $update.value))' \
    "${preferencesPath}" > "${preferencesPath}.tmp"

  $DRY_RUN_CMD mv "${preferencesPath}.tmp" "${preferencesPath}"
''

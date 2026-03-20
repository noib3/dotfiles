# Returns a bash script that writes custom search engines into Brave's
# "Web Data" SQLite database for a single profile, and optionally inserts
# favicons into the "Favicons" database.  Quits and relaunches Brave if
# it's running.
{
  lib,
  imagemagick,
  openssl,
  sqlite,
  unixtools,
  writeText,
  # ──
  engines, # attrsOf { name, url, favicon? }
  dbPath,
  faviconsDbPath,
  hashFile,
  isDarwin,
}:

let
  nix2Sql =
    v: if builtins.isString v then "'${builtins.replaceStrings [ "'" ] [ "''" ] v}'" else toString v;

  enginesList = lib.mapAttrsToList (keyword: engine: {
    inherit keyword;
    short_name = engine.name;
    inherit (engine) url;
    favicon_url = if engine ? favicon && engine.favicon != null then "nix-managed://${keyword}" else "";
    safe_for_autoreplace = 0;
    created_by_policy = 1;
    input_encodings = "UTF-8";
  }) engines;

  sqlScript = writeText "brave-search-engines.sql" ''
    -- Remove all policy-managed search engines.
    DELETE FROM keywords WHERE created_by_policy = 1;

    -- Insert the configured search engines.
    ${lib.concatMapStringsSep "\n" (
      engine:
      let
        columns = builtins.attrNames engine;
        values = map (col: nix2Sql engine.${col}) columns;
      in
      "INSERT INTO keywords (${lib.concatStringsSep ", " columns}) VALUES (${lib.concatStringsSep ", " values});"
    ) enginesList}
  '';

  enginesWithFavicons = lib.filterAttrs (_: e: e ? favicon && e.favicon != null) engines;

  faviconEntries = lib.mapAttrsToList (keyword: engine: {
    inherit keyword;
    faviconUrl = "nix-managed://${keyword}";
    src = engine.favicon;
  }) enginesWithFavicons;

  sha = lib.getExe' openssl "openssl";
  convert = lib.getExe' imagemagick "magick";
  sqlite3 = lib.getExe sqlite;
  xxd = lib.getExe unixtools.xxd;

  pgrep = if isDarwin then ''/usr/bin/pgrep -x "Brave Browser"'' else "pgrep -x brave";

  quit =
    if isDarwin then ''/usr/bin/osascript -e 'quit app "Brave Browser"' '' else "pkill -TERM brave";

  relaunch = if isDarwin then ''/usr/bin/open -a "Brave Browser"'' else "brave &";
in
''
  _set_brave_search_engines() {
    [[ -f "${dbPath}" ]] || return 0

    local script_hash
    script_hash=$(${sha} dgst -sha256 ${sqlScript} ${
      lib.concatMapStringsSep " " (e: toString e.src) faviconEntries
    } | cut -d' ' -f2 | ${sha} dgst -sha256 | cut -d' ' -f2)

    if [[ -f "${hashFile}" ]] && [[ "$(cat "${hashFile}")" == "$script_hash" ]]; then
      return 0
    fi

    local brave_was_running=0
    if ${pgrep} > /dev/null 2>&1; then
      brave_was_running=1
      ${quit}
      while ${pgrep} > /dev/null 2>&1; do sleep 0.5; done
    fi

    run ${sqlite3} "${dbPath}" < ${sqlScript}

    ${lib.concatMapStringsSep "\n" (entry: ''
          if [[ -f "${faviconsDbPath}" ]]; then
            local icon hex
            icon=$(mktemp)
            ${convert} -density 384 -background none "${toString entry.src}[0]" -resize 256x256 -gravity center -extent 256x256 PNG32:"$icon"

            hex=$(${xxd} -p "$icon" | tr -d '\n')

            run ${sqlite3} "${faviconsDbPath}" <<FAVICON_SQL
      INSERT OR IGNORE INTO favicons (url, icon_type) VALUES ('${entry.faviconUrl}', 1);
      DELETE FROM favicon_bitmaps WHERE icon_id = (SELECT id FROM favicons WHERE url = '${entry.faviconUrl}');
      INSERT INTO favicon_bitmaps (icon_id, last_updated, image_data, width, height)
        VALUES ((SELECT id FROM favicons WHERE url = '${entry.faviconUrl}'), strftime('%s', 'now'), X'$hex', 256, 256);
      FAVICON_SQL

            rm -f "$icon"
          fi
    '') faviconEntries}

    if [[ "$brave_was_running" -eq 1 ]]; then
      run ${relaunch}
    fi

    run mkdir -p "$(dirname "${hashFile}")"
    echo "$script_hash" > "${hashFile}"
  }

  _set_brave_search_engines
''

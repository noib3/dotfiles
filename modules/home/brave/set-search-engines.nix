# Returns a bash script that writes custom search engines into Brave's
# "Web Data" SQLite database for a single profile, and optionally inserts
# favicons into the "Favicons" database.
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
  hashName,
  cacheHome,
  isDarwin,
}:

let
  nix2Sql =
    v: if builtins.isString v then "'${builtins.replaceStrings [ "'" ] [ "''" ] v}'" else toString v;

  enginesList = lib.mapAttrsToList (keyword: engine: {
    inherit keyword;
    short_name = engine.name;
    inherit (engine) url;
    # NOT NULL in the schema — set to our managed URL when a favicon is
    # provided, empty string otherwise.
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

  # Engines that have a favicon derivation.
  enginesWithFavicons = lib.filterAttrs (_: e: e ? favicon && e.favicon != null) engines;

  # For each engine with a favicon, generate a SQL snippet that:
  #   1. Inserts a row into `favicons` (the icon URL)
  #   2. Inserts 16x16 and 32x32 PNG bitmaps into `favicon_bitmaps`
  #   3. Updates the `favicon_url` in `keywords` to point to the icon URL
  #
  # The actual PNG conversion happens at build time via ImageMagick, and
  # the binary data is hex-encoded so it can be inlined into the SQL as
  # X'...' literals.
  mkFaviconDerivation =
    keyword: engine:
    let
      faviconUrl = "nix-managed://${keyword}";
    in
    {
      inherit keyword faviconUrl;
      icon16 = engine.favicon;
      icon32 = engine.favicon;
    };

  faviconEntries = lib.mapAttrsToList mkFaviconDerivation enginesWithFavicons;

  pgrep = if isDarwin then ''/usr/bin/pgrep -x "Brave Browser"'' else "pgrep -x brave";

  quit =
    if isDarwin then ''/usr/bin/osascript -e 'quit app "Brave Browser"' '' else "pkill -TERM brave";

  relaunch = if isDarwin then ''/usr/bin/open -a "Brave Browser"'' else "brave &";

  convert = lib.getExe' imagemagick "magick";
  sqlite3 = lib.getExe sqlite;
in
''
  is_brave_running() {
    ${pgrep} > /dev/null 2>&1
  }

  quit_brave() {
    ${quit}
    while is_brave_running; do sleep 0.5; done
  }

  relaunch_brave() {
    run ${relaunch}
  }

  apply_brave_search_engines() {
    # Exit early if Brave hasn't yet created the DB.
    [[ -f "${dbPath}" ]] || return 0

    # Generate the checksum of the SQL script + favicon sources.
    script_hash=$(${lib.getExe' openssl "openssl"} dgst -sha256 ${sqlScript} ${
      lib.concatMapStringsSep " " (e: toString e.icon16) faviconEntries
    } | cut -d' ' -f2 | ${lib.getExe' openssl "openssl"} dgst -sha256 | cut -d' ' -f2)
    hash_file="${cacheHome}/home-manager/${hashName}.hash"

    # Exit early if nothing has changed.
    if [[ -f "$hash_file" ]] && [[ "$(cat "$hash_file")" == "$script_hash" ]]; then
      return 0
    fi

    # The database is locked while Brave is running, so we need to quit
    # it first.
    brave_was_running=0
    if is_brave_running; then
      brave_was_running=1
      quit_brave
    fi

    # Apply search engine changes.
    run ${sqlite3} "${dbPath}" < ${sqlScript}

    # Apply favicon changes.
    ${lib.concatMapStringsSep "\n" (entry: ''
          if [[ -f "${faviconsDbPath}" ]]; then
            # Convert the source image to 16x16 and 32x32 PNGs.
            icon16=$(mktemp)
            icon32=$(mktemp)
            ${convert} "${toString entry.icon16}[0]" -resize 16x16 -background none -gravity center -extent 16x16 PNG32:"$icon16"
            ${convert} "${toString entry.icon32}[0]" -resize 32x32 -background none -gravity center -extent 32x32 PNG32:"$icon32"

            hex16=$(${lib.getExe unixtools.xxd} -p "$icon16" | tr -d '\n')
            hex32=$(${lib.getExe unixtools.xxd} -p "$icon32" | tr -d '\n')

            run ${sqlite3} "${faviconsDbPath}" <<FAVICON_SQL
      -- Upsert the favicon URL.
      INSERT OR IGNORE INTO favicons (url, icon_type) VALUES ('${entry.faviconUrl}', 1);

      -- Remove old bitmaps for this favicon.
      DELETE FROM favicon_bitmaps WHERE icon_id = (SELECT id FROM favicons WHERE url = '${entry.faviconUrl}');

      -- Insert 16x16 bitmap.
      INSERT INTO favicon_bitmaps (icon_id, last_updated, image_data, width, height)
      VALUES (
        (SELECT id FROM favicons WHERE url = '${entry.faviconUrl}'),
        strftime('%s', 'now'),
        X'$hex16',
        16, 16
      );

      -- Insert 32x32 bitmap.
      INSERT INTO favicon_bitmaps (icon_id, last_updated, image_data, width, height)
      VALUES (
        (SELECT id FROM favicons WHERE url = '${entry.faviconUrl}'),
        strftime('%s', 'now'),
        X'$hex32',
        32, 32
      );
      FAVICON_SQL

            rm -f "$icon16" "$icon32"
          fi
    '') faviconEntries}

    # Restart Brave if it was running.
    if [[ "$brave_was_running" -eq 1 ]]; then
      relaunch_brave
    fi

    # Store the hash.
    run mkdir -p "$(dirname "$hash_file")"
    run echo "$script_hash" > "$hash_file"
  }

  apply_brave_search_engines
''

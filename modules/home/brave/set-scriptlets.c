/* Brave's ValueStore keeps a JSON array in the SCRIPTLETS LevelDB key.
 * Only entries with the user-nix- prefix are managed by this module. */
#include <jansson.h>
#include <leveldb/c.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  if (argc != 3) {
    fprintf(stderr, "Usage: %s DATABASE RESOURCES_JSON\n", argv[0]);
    return 1;
  }

  json_error_t json_error;
  json_t *resources = json_load_file(argv[2], 0, &json_error);
  if (!json_is_array(resources)) {
    fprintf(stderr, "Invalid scriptlet resources: %s\n", argv[2]);
    json_decref(resources);
    return 1;
  }

  char *error = NULL;
  leveldb_options_t *options = leveldb_options_create();
  leveldb_options_set_create_if_missing(options, 1);
  leveldb_t *db = leveldb_open(options, argv[1], &error);
  leveldb_options_destroy(options);
  int status = 1;
  json_t *existing = NULL, *merged = NULL;
  char *encoded = NULL;
  if (error != NULL) goto cleanup;

  size_t length;
  leveldb_readoptions_t *read_options = leveldb_readoptions_create();
  char *value = leveldb_get(db, read_options, "SCRIPTLETS", 10, &length, &error);
  leveldb_readoptions_destroy(read_options);
  if (error == NULL) {
    existing = value ? json_loadb(value, length, 0, &json_error) : json_array();
  }
  leveldb_free(value);
  if (error != NULL) goto cleanup;
  if (!json_is_array(existing)) {
    fprintf(stderr, "Invalid existing scriptlets in %s\n", argv[1]);
    goto cleanup;
  }

  merged = json_array();
  size_t index;
  json_t *resource;
  json_array_foreach(existing, index, resource) {
    const char *name = json_string_value(json_object_get(resource, "name"));
    if (name == NULL || strncmp(name, "user-nix-", 9) != 0) {
      if (json_array_append(merged, resource) != 0) goto cleanup;
    }
  }
  if (json_array_extend(merged, resources) != 0) goto cleanup;
  encoded = json_dumps(merged, JSON_COMPACT);
  if (encoded == NULL) goto cleanup;

  leveldb_writeoptions_t *write_options = leveldb_writeoptions_create();
  leveldb_writeoptions_set_sync(write_options, 1);
  leveldb_put(db, write_options, "SCRIPTLETS", 10, encoded, strlen(encoded), &error);
  leveldb_writeoptions_destroy(write_options);
  status = error != NULL;

cleanup:
  if (error != NULL) fprintf(stderr, "LevelDB: %s\n", error);
  leveldb_free(error);
  free(encoded);
  json_decref(merged);
  json_decref(existing);
  json_decref(resources);
  if (db != NULL) leveldb_close(db);
  return status;
}

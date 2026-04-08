/*
 * macOS privacy checks for screen/audio capture key off the app bundle
 * executable. A shell script launcher caused TCC to attribute requests to the
 * script interpreter instead of Brave, so we use this tiny native launcher in
 * the bundle and move the original Brave binary aside to Brave Browser.orig.
 */

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef BRAVE_FEATURES_FLAGS
#define BRAVE_FEATURES_FLAGS ""
#endif

static const char original_name[] = "Brave Browser.orig";
static const char features_flags[] = BRAVE_FEATURES_FLAGS;

static int count_tokens(const char *value) {
  int count = 0;
  int in_token = 0;

  for (const char *cursor = value; *cursor != '\0'; cursor++) {
    if (*cursor == ' ') {
      in_token = 0;
      continue;
    }

    if (!in_token) {
      count++;
      in_token = 1;
    }
  }

  return count;
}

int main(int argc, char **argv) {
  const char *program = argv[0] != NULL ? argv[0] : "Brave Browser";
  const char *slash = strrchr(program, '/');
  char *original_path = NULL;
  char *flags_copy = NULL;
  int flags_argc = 0;

  if (slash != NULL) {
    size_t dir_len = (size_t)(slash - program);

    original_path = malloc(dir_len + sizeof(original_name) + 1);
    if (original_path == NULL) {
      perror("malloc");
      return 111;
    }

    memcpy(original_path, program, dir_len);
    original_path[dir_len] = '/';
    memcpy(original_path + dir_len + 1, original_name, sizeof(original_name));
  } else {
    original_path = strdup(original_name);
    if (original_path == NULL) {
      perror("strdup");
      return 111;
    }
  }

  if (features_flags[0] != '\0') {
    flags_argc = count_tokens(features_flags);
    flags_copy = strdup(features_flags);
    if (flags_copy == NULL) {
      perror("strdup");
      return 111;
    }
  }

  char **new_argv =
      calloc((size_t)argc + (size_t)flags_argc + 1, sizeof(char *));
  if (new_argv == NULL) {
    perror("calloc");
    return 111;
  }

  int i = 0;
  new_argv[i++] = (char *)program;

  if (flags_copy != NULL) {
    char *saveptr = NULL;
    char *token = strtok_r(flags_copy, " ", &saveptr);

    while (token != NULL) {
      new_argv[i++] = token;
      token = strtok_r(NULL, " ", &saveptr);
    }
  }

  for (int j = 1; j < argc; j++) {
    new_argv[i++] = argv[j];
  }
  new_argv[i] = NULL;

  execv(original_path, new_argv);
  perror("execv");

  return errno == ENOENT ? 127 : 126;
}

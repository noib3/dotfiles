{ pkgs }:

pkgs.buildNpmPackage (finalAttrs: {
  pname = "claude-code-acp";
  version = "0.10.0";

  src = pkgs.fetchFromGitHub {
    owner = "zed-industries";
    repo = "claude-code-acp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ZbCumFZyGFoNBNK6PC56oauuN2Wco3rlR80/1rBPORk=";
  };

  npmDepsHash = "sha256-nzP2cMYKoe4S9goIbJ+ocg8bZPY/uCTOm0bLbn4m6Mw=";
})

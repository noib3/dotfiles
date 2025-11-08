{
  enable = true;

  settings = {
    notARepository = "skip";
    git.pagers = [
      {
        colorArg = "always";
        pager = "delta --paging=never";
      }
    ];
    gui = {
      nerdFontsVersion = "3";
      showCommandLog = false;
    };
  };
}

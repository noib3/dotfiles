self: super: {
  vimv = super.vimv.overrideAttrs (old: {
    version = "2021-01-11";
    src = super.fetchFromGitHub {
      owner = "thameera";
      repo = "vimv";
      rev = "27ca316f308d0cf1561ac660b6727ee1e235590b";
      sha256 = "1xa7k531pgfg92l4zy91kvjwj0r6vrfjf2b99fi2hkkdfd65biff";
    };
    meta = old.meta or { } // {
      platforms = super.lib.platforms.unix;
    };
  });
}

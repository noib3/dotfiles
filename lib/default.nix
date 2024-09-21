{
  overlay = final: prev: {
    lib = prev.lib // {
      hex = import ./hex.nix { inherit (prev) lib; };
    };
  };
}

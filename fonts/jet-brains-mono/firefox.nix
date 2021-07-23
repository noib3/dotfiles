{ machine }:

{
  family = "JetBrainsMono Nerd Font";
  size =
    if machine == "blade" then
      "22px"
    else if machine == "mbair" then
      "19px"
    else "";
}

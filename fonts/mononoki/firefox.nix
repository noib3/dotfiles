{ machine }:

{
  family = "Mononoki Nerd Font";
  size =
    if machine == "blade" then
      "23px"
    else if machine == "mbair" then
      "20px"
    else "";
}

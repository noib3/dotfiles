{
  settings = {
    character = {
      success_symbol = "[λ](fg:purple)";
      error_symbol = "[λ](fg:red)";
      vicmd_symbol = "[λ](fg:purple)";
    };

    directory = {
      format = " in [$path]($style)[$read_only]($read_only_style) ";
      truncation_length = 1;
      fish_style_pwd_dir_length = 1;
    };

    hostname = {
      format = " on [$hostname]($style)";
      ssh_only = false;
    };

    python = {
      python_binary = "python3";
    };

    status = {
      map_symbol = true;
      disable = false;
    };

    username = {
      format = "[$user]($style)";
      show_always = true;
    };
  };
}

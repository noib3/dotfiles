{
  settings = {
    character = {
      success_symbol = "[\\$](fg:cyan bold)";
      error_symbol = "[\\$](fg:red bold)";
      vicmd_symbol = "[\\$](fg:cyan bold)";
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
      disabled = false;
    };

    username = {
      format = "[$user]($style)";
      show_always = true;
    };
  };
}

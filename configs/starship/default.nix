let
  lib = import <nixpkgs/lib>;
in
{
  settings = {
    format = lib.concatStrings [
      "$username"
      "$hostname"
      "$shlvl"
      "$kubernetes"
      "$directory"
      "$vcsh"
      "$git_branch"
      "$git_commit"
      "$git_state"
      "$git_status"
      "$hg_branch"
      "$docker_context"
      "$package"
      "$cmake"
      "$dart"
      "$deno"
      "$dotnet"
      "$elixir"
      "$elm"
      "$erlang"
      "$golang"
      "$helm"
      "$java"
      "$julia"
      "$kotlin"
      "$nim"
      "$nodejs"
      "$ocaml"
      "$perl"
      "$php"
      "$purescript"
      "$python"
      "$red"
      "$ruby"
      "$rust"
      "$scala"
      "$swift"
      "$terraform"
      "$vlang"
      "$vagrant"
      "$zig"
      "$conda"
      "$memory_usage"
      "$gcloud"
      "$openstack"
      "$env_var"
      "$crystal"
      "$lua"
      "$custom"
      "$cmd_duration"
      "$line_break"
      "$jobs"
      "$battery"
      "$time"
      "$shell"
      "$character"
      "$status"
    ];

    character = {
      success_symbol = "[|>](bold cyan)";
      error_symbol = "[✖](bold red)";
      vicmd_symbol = "[<|](bold cyan)";
    };

    directory = {
      format = " in [$path]($style)[$read_only]($read_only_style) ";
      truncation_length = 1;
      fish_style_pwd_dir_length = 1;
    };

    git_status = {
      format = "([\\($staged$untracked$modified$renamed$deleted\\)]($style) )";
      staged = "[$\{count\}s](fg:blue bold)";
      untracked = "[$\{count\}a](fg:green bold)";
      modified = "[$\{count\}m](fg:yellow bold)";
      renamed = "[$\{count\}r](fg:purple bold)";
      deleted = "[$\{count\}d](fg:red bold)";
      style = "bold purple";
    };

    hostname = {
      format = " on [$hostname]($style)";
      style = "bold green";
      ssh_only = false;
    };

    nodejs = {
      detect_folders = [ ];
    };

    python = {
      python_binary = "python3";
    };

    username = {
      format = "[$user]($style)";
      show_always = true;
    };
  };

  enableFishIntegration = true;
}

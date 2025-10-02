{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.kubectl;
  configDir = "${config.xdg.configHome}/kube";
  configFile = "config.yaml";
in
{
  options.modules.kubectl = {
    enable = mkEnableOption "kubectl";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.kubectl
    ];

    home.sessionVariables.KUBECONFIG = "${configDir}/${configFile}";

    programs.kubecolor.enable = true;

    xdg.configFile."kube/${configFile}".text = ''
      apiVersion: v1
      kind: Config

      clusters:
      - name: nomad
        cluster:
          server: https://k8s.nomad.foo

      users:
      - name: noib3
        user:
          tokenFile: ${configDir}/token.txt

      contexts:
      - name: nomad
        context:
          cluster: nomad
          namespace: default
          user: noib3

      current-context: nomad
    '';
  };
}

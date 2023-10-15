self: {
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.user-login-session;
in {
  options.programs.user-login-session = {
    enable = mkEnableOption ''
      User-managed login sessions, for separating the WM / DE from the base system.
    '';

    package = mkOption {
      type = types.nullOr types.package;
      default = self.packages.${pkgs.system}.default;
      description = ''
        user-login-session package to use.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.xserver.displayManager.sessionPackages = lib.optional (cfg.package != null) cfg.package;
  };
}

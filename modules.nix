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

    entries = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption ''
            Enable this specific entry.
          '';

          alias = mkOption {
            type = types.nullOr types.string;
            description = ''
              Name alias to show in the session entry.
            '';
          };

          extraEnv = mkOption {
            type = types.attrsOf types.string;
            default = {};
            description = ''
              Set of environment variables to set for this specific entry.
            '';
          };
        };
      });
    };
  };

  config = let
    name = "user-login-session";

    # Define the script (included externally) and its necessary dependencies
    script = pkgs.writeScriptBin name ''
      # Immediately die if there is an error
      set -e

      # Do not expand glob * in paths
      set -o noglob

      # Helper function to display a dialog showing that a configuration does
      #  not yet exist.
      show_error_not_configured() {
          ${pkgs.dialog}/bin/dialog \
              --title "Session Not Configured" \
              --msgbox "The current user '$USER' has not set up their session!" 10 50

          exit -1
      }

      # Get the XDG config directory
      if [ -z "''${XDG_CONFIG_HOME}" ]; then
          XDG_CONFIG_HOME=$HOME/.config
      fi

      # Look for the required configuration file in the set of XDG config directories
      SESSION="''${XDG_CONFIG_HOME}/user-login-session/session"
      if [ -f "$SESSION" ]; then
          echo "Found user session at '$SESSION'. Executing..."
          sh $SESSION
      else
          show_error_not_configured
      fi

    '';

    attrsToEnv = envs:
      builtins.concatStringsSep " " (builtins.attrValues (
        builtins.mapAttrs (k: v: "${k}='${builtins.replaceStrings ["'"] ["\""] v}'") envs
      ));

    sessions = builtins.attrValues (builtins.mapAttrs (name: {
      enable,
      alias,
      extraEnv,
    }:
      pkgs.writeTextDir "share/wayland-sessions/user-login-session.${name}.desktop" ''
        [Desktop Entry]
        Name=User-Managed Login Session (${alias})
        Comment=User-managed session settings.
        Exec=${pkgs.coreutils}/bin/env ${attrsToEnv extraEnv} ${script}/bin/user-login-session
        Type=Application
      '')
    cfg.entries);

    user-login-session = pkgs.symlinkJoin {
      name = "user-login-session";

      paths = [script] ++ sessions;
      buildInputs = with pkgs; [makeBinaryWrapper];
      postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";

      passthru.providedSessions = builtins.attrValues (
        builtins.mapAttrs (name: value: "user-login-session.${name}") cfg.entries
      );
    };
  in
    mkIf cfg.enable {
      services.xserver.displayManager.sessionPackages = [user-login-session];
    };
}

{
  description = "Simple login manager using user-defined sessions.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    utils,
  }:
    utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        name = "user-login-session";
        src = builtins.readFile ./user-login-session.sh;
        scriptBuildInputs = with pkgs; [dialog];
        script = (pkgs.writeScriptBin name src).overrideAttrs (old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });

        session = pkgs.writeTextDir "share/wayland-sessions/user-login-session.desktop" ''
          [Desktop Entry]
          Name=User-Managed Login Session
          Comment=User-managed session settings.
          Exec=${script}/bin/user-login-session
          Type=Application
        '';
        sessionLocation = "user-login-session/session";
      in {
        packages = rec {
          default = user-login-session;

          user-login-session = pkgs.symlinkJoin {
            inherit name;

            paths = [script session] ++ scriptBuildInputs;
            buildInputs = [pkgs.makeWrapper];
            postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";

            passthru.providedSessions = [
              "user-login-session"
            ];
          };
        };

        nixosModules.default = import ./modules.nix self;
        homeManagerModules.default = import ./homeManagerModules.nix self;
      }
    );
}

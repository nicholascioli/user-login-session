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
      system: {
        nixosModules.default = import ./modules.nix self;
        homeManagerModules.default = import ./homeManagerModules.nix self;
      }
    );
}

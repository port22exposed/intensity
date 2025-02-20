{
  description = "intensity flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          system = system;
        };
      in
      {
        devShells.default = pkgs.mkShell
          {
            nativeBuildInputs = with pkgs; [
              zig
            ];
          };
      });
}

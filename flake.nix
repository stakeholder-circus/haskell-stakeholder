{
  description = "haskell-stakeholder local development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            ghc
            cabal-install
            hlint
            fourmolu
            python3
            docker-client
          ];
        };

        apps.check = {
          type = "app";
          program = toString (pkgs.writeShellScript "haskell-stakeholder-check" ''
            set -euo pipefail
            python3 scripts/validate_scaffold.py
            fourmolu -m check app src test
            hlint .
            cabal build all
            cabal test all
          '');
        };
      });
}

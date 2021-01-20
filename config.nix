{  }:

let
  compiler = "ghc884";

  config = {
    packageOverrides = pkgs: rec {
      haskell = pkgs.haskell // {
        packages = pkgs.haskell.packages // {
          "${compiler}" = pkgs.haskell.packages."${compiler}".override {
            overrides = 
              let
                collapseOverrides = 
                  pkgs.lib.fold pkgs.lib.composeExtensions (_: _: {});

                autoOverrides = self: super:
                  let
                    toPackage = file: _: {
                      name = builtins.replaceStrings [ ".nix" ] [ "" ] file;
                      value = haskell.lib.dontCheck (self.callPackage (./. + "/nix/${file}") {  });
                    };
                  in
                    pkgs.lib.mapAttrs' toPackage (builtins.readDir ./nix);

                manualOverrides = self: super: {
                  # Does not compile properly with tests enabled.
                  base64 = pkgs.haskell.lib.dontCheck pkgs.haskell.packages."${compiler}".base64;

                  # Don't forget that persistent-sqlite uses a system dependency.
                  persistent-sqlite = pkgs.haskell.lib.dontCheck
                    (self.callPackage (./. + "/nix/persistent-sqlite.nix") { sqlite = pkgs.sqlite; });
                };
              in
                collapseOverrides [ autoOverrides manualOverrides ];
          };
        };
      };
    };
  };
in
  { compiler = compiler;
    nixpkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/a1bb960c13a05c95821a5f44a09881f21325a475.tar.gz") { inherit config; };
  }

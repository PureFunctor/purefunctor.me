{  }:

let
  compiler = "ghc884";

  # Place dependencies not bundled with GHC here
  dependencies = [
    "aeson"
    "jose"
    "lens"
    "monad-logger"
    "password"
    "persistent"
    "persistent-sqlite"
    "persistent-template"
    "servant"
    "servant-server"
    "servant-auth"
    "servant-auth-server"
    "wai"
    "warp"
  ];

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
                    toPackage = name: {
                      inherit name;
                      value = pkgs.haskell.lib.dontCheck super."${name}";
                    };
                  in
                    builtins.listToAttrs (map toPackage dependencies);

                manualOverrides = self: super: {
                  # Does not compile properly with tests enabled.
                  base64 = pkgs.haskell.lib.dontCheck super.base64;

                  # Make sure that our project has its own derivation.
                  purefunctor-me = super.callCabal2nix "purefunctor-me" ./. { };
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

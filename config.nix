{ doCheck ? false 
}:

let
  compiler = "ghc884";

  sources = import ./nix/sources.nix { };

  gitignore = import sources."gitignore.nix" { };
  inherit (gitignore) gitignoreFilter;

  config = {
    packageOverrides = pkgs: rec {
      haskell = pkgs.haskell // {
        packages = pkgs.haskell.packages // {
          "${compiler}" = pkgs.haskell.packages."${compiler}".override {
            overrides = 
              let
                collapseOverrides = 
                  pkgs.lib.fold pkgs.lib.composeExtensions (_: _: {});

                manualOverrides = self: super: {
                  # Make sure that our project has its own derivation.
                  purefunctor-me = 
                    let
                      check = if doCheck then haskell.lib.doCheck else pkgs.lib.id;
  
                      srcFilter = src:
                        let
                          srcIgnored = gitignoreFilter src;

                          dontIgnore = [
                            "config.toml"
                          ];
                        in
                          path: type:
                            srcIgnored path type
                              || builtins.elem (builtins.baseNameOf path) dontIgnore;

                      purefunctor-me-src = pkgs.lib.cleanSourceWith {
                        filter = srcFilter ./.;
                        src = ./.;
                        name = "purefunctor-me-src";
                      };
                    in
                      check (super.callCabal2nix "purefunctor-me" purefunctor-me-src { });

                  # Disable tests and benchmarks for all packages.
                  mkDerivation = args: super.mkDerivation ({
                    doCheck = false;
                    doBenchmark = false;
                    doHoogle = true;
                    doHaddock = true;
                    enableLibraryProfiling = false;
                    enableExecutableProfiling = false;
                  } // args);
                };
              in
                collapseOverrides [ manualOverrides ];
          };
        };
      };
    };
  };
in
  { compiler = compiler;
    nixpkgs = import (fetchTarball sources.nixpkgs.url) { inherit config; };
  }

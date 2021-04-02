# purefunctor.me
My personal portfolio website written in PureScript and Haskell.

## Development Requirements
The project requires the following compilers and build tools to be installed for development:

### Frontend
* purescript (v0.14.0)
* spago
* yarn
* zephyr

### Backend
* ghc (8.10.3)
* cabal

### Optional
* nix
* cachix

### Meta
* haskell-language-server

## Hacking the Project
Once you have these development dependencies installed, you can now start hacking on the project. Alternatively, a `shell.nix` file is also provided for use with Nix and it contains the minimal tools needed for working on the project.

### Frontend
Install dependencies through `yarn` and check `package.json` for possible build scripts.

### Backend
The Haskell backend can be built either through `cabal` or `nix`.

#### Cabal-based Builds
To start, ensure that you have GHC 8.10.3
```sh
λ ghc --version
The Glorious Glasgow Haskell Compilation System, version 8.10.3
```

After which you can then build the packages using `cabal`:
```sh
λ cabal build purefunctor-me
```

Likewise, a `hie.yaml` file is provided for use with `haskell-language-server`.

#### Nix-powered Cabal Builds
To build the project:
```sh
λ nix-build release-backend.nix
```

This should produce the `purefunctor-me` binary in a directory named `result`:
```sh
λ ./result/bin/purefunctor-me
```

Alternatively, you can go into `nix-shell` and use `cabal` as normal:
```sh
your-user:λ nix-shell
...
nix-shell:λ cabal build
```

One can also use `nix-shell` to invoke `haskell-language-server` for development. 

### Cachix Cache
This project uses the `applicative-labs` cache for its dependencies; to use the cache for development:
```sh
λ cachix use applicative-labs
```

## Deployment
The project uses `docker` and `docker-compose` for deployment; make sure you have both installed.

1) Create a directory named `app`.

2) Copy `pf-backend/config-default.toml` into `app/config.toml` and modify the default fields.

3) Copy `pf-backend/migration.sql` into `app/migration.sql`.

4) Create a directory named `ssl` under `app` and add `certificate.pem` and `certkey.pem`.

5) Run `docker-compose up --build`, this should bind the 80 and 443 machine ports to NGINX.

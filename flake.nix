{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    poetry2nix.url = "github:nix-community/poetry2nix";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];
      perSystem = {pkgs, ...}: let
        poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix {inherit pkgs;};

        pypkgs-build-requirements = {
          flexcache = ["setuptools"];
          flexparser = ["setuptools"];
          gflabel = ["setuptools"];
          pint = ["setuptools"];
          trianglesolver = ["setuptools"];
        };
        overrides = poetry2nix.defaultPoetryOverrides.extend (
          final: prev:
            builtins.mapAttrs (
              package: build-requirements:
                (builtins.getAttr package prev).overridePythonAttrs (old: {
                  buildInputs =
                    (old.buildInputs or [])
                    ++ (builtins.map (pkg:
                      if builtins.isString pkg
                      then builtins.getAttr pkg prev
                      else pkg)
                    build-requirements);
                })
            )
            pypkgs-build-requirements
        );
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.python310
            pkgs.poetry
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc
            pkgs.zlib
            pkgs.libGL
            pkgs.xorg.libX11
            pkgs.xorg.libXi
            pkgs.expat
          ];
        };

        packages.default = poetry2nix.mkPoetryApplication {
          inherit overrides;
          projectDir = ./.;
        };
      };
    };
}

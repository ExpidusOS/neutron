{
  description = "Core API for ExpidusOS";

  nixConfig = rec {
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
    substituters = [ "https://cache.nixos.org" "https://cache.garnix.io" ];
    trusted-substituters = substituters;
    fallback = true;
    http2 = false;
  };

  inputs = {
    nixpkgs.url = github:ExpidusOS/nixpkgs;
    expidus-sdk = {
      url = github:ExpidusOS/sdk/feat/refactor-neutron;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, expidus-sdk }:
    with expidus-sdk.lib;
    flake-utils.eachSystem flake-utils.allSystems (system:
      let
        pkgs = expidus-sdk.legacyPackages.${system}.appendOverlays [
          (final: prev: {
            zig = prev.zigpkgs.master;
          })
        ];

        stdenv = pkgs.clang15Stdenv;
        mkShell = pkgs.mkShell.override {
          inherit stdenv;
        };

        mkPackage = pkgs.callPackage "${expidus-sdk.outPath}/pkgs/development/libraries/expidus/neutron/package.nix" {
          inherit stdenv;
          inherit (pkgs) zig;
        };

        packages = {
          default = mkPackage {
            rev = "${self.shortRev or "dirty"}";
            src = cleanSource self;
          };
        };

        mkDevShell = name: mkShell {
          inherit (packages.${name}) pname version name buildFlags;

          packages = packages.${name}.buildInputs ++ packages.${name}.nativeBuildInputs;

          shellHook = ''
            export rootOut=$(dirname $out)
            export devdocs=$rootOut/devdocs
            export src=$(dirname $rootOut)

            function installPhase {
              export NIX_BUILD_TOP=$HOME
              rm -rf $rootOut
              ${packages.${name}.installPhase}
            }
          '';
        };

        devShells = builtins.listToAttrs
          (builtins.map (name: {
            inherit name;
            value = mkDevShell name;
          })
          (builtins.attrNames packages));
      in rec {
        inherit packages devShells;
        legacyPackages = pkgs;
        defaultPackage = packages.default;
      });
}

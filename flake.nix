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

        vendorOverride = {
          "third-party/zig/antiphony" = pkgs.fetchFromGitHub {
            owner = "ExpidusOS";
            repo = "antiphony";
            rev = "43c1c3f87f51b4d472026379e4589ac3c07ecbd4";
            fetchSubmodules = true;
            sha256 = "sha256-VWAPMVPlwBDiOKrzvgGeEzAvGTFy6SjujCsZfjBQiig=";
          };
          "third-party/zig/libxev" = pkgs.fetchFromGitHub {
            owner = "mitchellh";
            repo = "libxev";
            rev = "aab505ffca04117ef8eeeb8dc3c64c87d80dfe6d";
            sha256 = "sha256-a7caowEsonavStCG5qNLDh/Ij6JIYJ9NS1DNFPr2Mrk=";
          };
        };

        packages = {
          default = mkPackage {
            rev = "${self.shortRev or "dirty"}";
            src = cleanSource self;
            inherit vendorOverride;
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

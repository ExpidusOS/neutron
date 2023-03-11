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
      url = github:ExpidusOS/sdk;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zig-overlay = {
      url = github:mitchellh/zig-overlay;
      inputs = {
        flake-utils.follows = "expidus-sdk/flake-utils";
        nixpkgs.follows = "expidus-sdk";
      };
    };
  };

  outputs = { self, nixpkgs, expidus-sdk, zig-overlay }:
    with expidus-sdk.lib;
    flake-utils.eachSystem flake-utils.allSystems (system:
      let
        pkgs = expidus-sdk.legacyPackages.${system}.appendOverlays [
          zig-overlay.overlays.default
          (final: prev: {
            zig = prev.zigpkgs.master;
          })
        ];

        vendor = {
          "third-party/zig/zig-clap" = pkgs.fetchFromGitHub {
            owner = "Hejsil";
            repo = "zig-clap";
            rev = "cb13519431b916c05c6c783cb0ce3b232be5e400";
            sha256 = "sha256-ej4r5LGsTqhQkw490yqjiTOGk+jPMJfUH1b/eUmvt20=";
          };
        };
      in rec {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "expidus-neutron";
          version = "git+${self.shortRev or "dirty"}";

          src = cleanSource self;

          outputs = [ "out" "dev" ];

          nativeBuildInputs = with pkgs.buildPackages; [
            cmake
            ninja
            clang
            zig
            pkg-config
            flutter-engine
            patchelf
          ] ++ optionals (pkgs.wlroots.meta.available) [
            pkgs.buildPackages.wayland-scanner
          ];

          strictDeps = true;
          depsBuildBuild = [ pkgs.buildPackages.pkg-config ];

          buildFlags = [
            "-Dflutter-engine=${pkgs.flutter-engine}/lib/flutter/out/release"
            "-Dtarget=${pkgs.targetPlatform.system}"
          ];

          buildInputs = with pkgs;
            optionals (wayland.meta.available) [ wayland-protocols wayland ]
            ++ optionals (wlroots.meta.available) [ wlroots ];

          postUnpack = ''
            ${concatStrings (attrValues (mapAttrs (path: src: ''
              mkdir -p $NIX_BUILD_TOP/source/vendor/$(dirname ${path})
              ln -s ${src} $NIX_BUILD_TOP/source/vendor/${path}
            '') vendor))}
          '';

          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
            export XDG_CACHE_HOME=$NIX_BUILD_TOP/.cache

            mkdir -p $out/lib $dev/include
            zig build $buildFlags --prefix $out \
              --prefix-lib-dir $out/lib \
              --prefix-include-dir $dev/include \
              --cache-dir $NIX_BUILD_TOP/cache

            patchelf --replace-needed libc.so ${pkgs.stdenv.cc.libc}/lib/libc.so.6 $out/bin/neutron-runner
            patchelf --replace-needed libneutron.so.0 $out/lib/libneutron.so.0 $out/bin/neutron-runner
            patchelf --set-interpreter ${pkgs.stdenv.cc.libc}/lib/ld-linux-${pkgs.targetPlatform.parsed.cpu.name}.so.2 $out/bin/neutron-runner
          '';
        };

        legacyPackages = pkgs;

        devShells.default = pkgs.mkShell {
          inherit (packages.default) pname version name buildFlags;
          packages = packages.default.buildInputs ++ packages.default.nativeBuildInputs ++ [
            pkgs.flutter-engine pkgs.gdb
          ];

          FLUTTER_ENGINE = pkgs.stdenv.mkDerivation {
            pname = "flutter-engine";
            inherit (pkgs.flutter-engine.debug) src version;

            dontUnpack = true;
            dontPatch = true;
            dontConfigure = true;
            dontBuild = true;
            dontFixup = true;

            installPhase = ''
              mkdir -p $out/out
              ln -s $src/src $out/src
              ln -s ${pkgs.flutter-engine.debug}/lib/flutter/out/debug $out/out/host_debug
            '';
          };

          shellHook = ''
            export rootOut=$(dirname $out)
            export dev=$rootOut/dev
            export src=$(dirname $rootOut)

            export LOCAL_ENGINE=$FLUTTER_ENGINE/out/host_debug

            alias flutter="flutter --local-engine $LOCAL_ENGINE"
            alias buildPhase="mkdir -p $out/lib $dev/include && zig build $buildFlags --prefix $out --prefix-lib-dir $out/lib --prefix-include-dir $dev/include"
          '';
        };

        defaultPackage = packages.default;
      });
}

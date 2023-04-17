{
  description = "Core API for ExpidusOS";

  nixConfig = rec {
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
    substituters = [ "https://cache.nixos.org" "https://cache.garnix.io" ];
    trusted-substituters = substituters;
    fallback = true;
    http2 = false;
  };

  inputs.expidus-sdk.url = github:ExpidusOS/sdk/feat/refactor-neutron;

  outputs = { self, expidus-sdk }:
    with expidus-sdk.lib;
    flake-utils.eachSystem flake-utils.allSystems (system:
      let
        pkgs = expidus-sdk.legacyPackages.${system}.appendOverlays [
          (final: prev: {
            zig = prev.zigpkgs.master;

            wlroots = prev.wlroots.overrideAttrs (self: super: {
              version = "0.16.2";

              src = prev.fetchFromGitLab {
                domain = "gitlab.freedesktop.org";
                owner = "wlroots";
                repo = "wlroots";
                rev = super.version;
                sha256 = "sha256-JeDDYinio14BOl6CbzAPnJDOnrk4vgGNMN++rcy2ItQ=";
              };

              nativeBuildInputs = super.nativeBuildInputs ++ [ prev.hwdata ];
            });
          })
        ];

        stdenv = pkgs.clang14Stdenv;
        mkShell = pkgs.mkShell.override {
          inherit stdenv;
        };

        mkPackage = pkgs.callPackage "${expidus-sdk.outPath}/pkgs/development/libraries/expidus/neutron/package.nix" {
          inherit stdenv;
          inherit (pkgs) zig;
        };

        zig = pkgs.writeShellScriptBin "zig" ''
          export PKG_CONFIG_PATH="${pkgs.wayland.dev}/lib/pkgconfig:${pkgs.wayland.bin}/lib/pkgconfig:${pkgs.wayland-protocols}/share/pkgconfig:${pkgs.wlroots}/lib/pkgconfig:${pkgs.pixman}/lib/pkgconfig:${pkgs.libxkbcommon.dev}/lib/pkgconfig:${pkgs.libdrm.dev}/lib/pkgconfig"
          unset NIX_CFLAGS_COMPILE
          exec ${pkgs.buildPackages.zig}/bin/zig $@
        '';

        fhsEnv = pkgs.buildFHSUserEnv {
          name = "expidus-neutron";

          targetPkgs = pkgs:
            (with pkgs.buildPackages; [
              zig
              (python3.withPackages (p: [ p.httplib2 p.six ]))
              ninja
              zlib
              git
              curl
              pkg-config
              wayland-scanner
            ]);

          runScript = "${zig}/bin/zig";
        };

        vendor = {
          "bindings/zig-flutter" = pkgs.fetchFromGitHub {
            owner = "ExpidusOS";
            repo = "zig-flutter";
            rev = "b090d9d37cfb0ccb2cb55fab4208ee6ffe9e3007";
          };
          "third-party/zig/s2s" = pkgs.fetchFromGitHub {
            owner = "ziglibs";
            repo = "s2s";
            rev = "87156727654be52d2ed583919b280ad8a2c84d35";
            sha256 = "sha256-roibYbyxqp3Z7LVUUFxqstYIvSGX3fpVXMZiFOFaj4Y=";
          };
          "third-party/zig/libxev" = pkgs.fetchFromGitHub {
            owner = "mitchellh";
            repo = "libxev";
            rev = "aab505ffca04117ef8eeeb8dc3c64c87d80dfe6d";
            sha256 = "sha256-a7caowEsonavStCG5qNLDh/Ij6JIYJ9NS1DNFPr2Mrk=";
          };
          "third-party/zig/zig-clap" = fetchFromGitHub {
            owner = "Hejsil";
            repo = "zig-clap";
            rev = "cb13519431b916c05c6c783cb0ce3b232be5e400";
            sha256 = "sha256-ej4r5LGsTqhQkw490yqjiTOGk+jPMJfUH1b/eUmvt20=";
          };
        };

        packages = {
          default = pkgs.stdenv.mkDerivation {
            pname = "expidus-neutron";
            version = "git+${self.shortRev or "dirty"}";

            src = cleanSource src;

            strictDeps = true;
            depsBuildBuild = [ pkgs.buildPackages.pkg-config ];

            nativeBuildInputs = with pkgs.buildPackages; [
              pkg-config
              wayland-scanner
            ];

            buildFlags = with pkgs; [
              wayland
              wayland-protocols
              wlroots
              pixman
              libxkbcommon
              libdrm
            ];

            configurePhase = ''
              ${concatStrings (attrValues (mapAttrs (path: src: ''
                echo "Linking ${src} -> $NIX_BUILD_TOP/source/vendor/${path}"
                rm -rf $NIX_BUILD_TOP/source/vendor/${path}
                cp -r -P --no-preserve=ownership,mode ${src} $NIX_BUILD_TOP/source/vendor/${path}
              '') vendor))}
            '';

            buildPhase = ''
              export XDG_CACHE_HOME=$NIX_BUILD_TOP/.cache

              ${fhsEnv}/bin/${fhsEnv.name} build --prefix $out \
                --prefix-lib-dir $out/lib \
                $buildFlags
            '';
          };
        };

        mkDevShell = name: mkShell {
          inherit (packages.${name}) pname version name buildFlags;

          packages = packages.${name}.nativeBuildInputs ++ packages.${name}.buildInputs;

          shellHook = ''
            export rootOut=$(dirname $out)
            export devdocs=$rootOut/devdocs
            export src=$(dirname $rootOut)
            export VK_LAYER_PATH=${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d

            alias zig=${fhsEnv}/bin/${fhsEnv.name}
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

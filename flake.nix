{
  description = "Core API for ExpidusOS";

  inputs.expidus-sdk.url = github:ExpidusOS/sdk/refactor;

  outputs = { self, expidus-sdk }:
    with expidus-sdk.lib;
    flake-utils.eachDefaultSystem (system:
      let
        pkgs = expidus-sdk.legacyPackages.${system};
      in with pkgs; rec {
        packages = flake-utils.flattenTree {
          neutron = clang14Stdenv.mkDerivation {
            pname = "neutron";
            version = self.shortRev or "dirty";

            src = cleanSource self;
            outputs = [ "out" "dev" ];

            nativeBuildInputs = [ meson ninja ];

            mesonFlags = [
              "-Dgit-commit=${self.shortRev or "dirty"}"
              "-Dgit-branch=master"
            ];

            meta = {
              description = "Core API for ExpidusOS";
              homepage = "https://github.com/ExpidusOS/neutron";
              license = licenses.gpl3Only;
              maintainers = with maintainers; [ RossComputerGuy ];
            };
          };
        };
        defaultPackage = packages.neutron;

        devShells.default = mkShell {
          packages = [ meson ninja clang pkg-config ];

          shellHook = ''
            export CC="${clang}/bin/clang"
            export CXX="${clang}/bin/clang++"
            export LD="${clang}/bin/ld.lld"
          '';
        };
      });
}

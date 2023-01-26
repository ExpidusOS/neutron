{ pkgs ? import <nixpkgs> }:
with pkgs; mkShell {
  packages = [ meson ninja clang pkg-config ];

  shellHook = ''
    export CC="${clang}/bin/clang"
    export CXX="${clang}/bin/clang++"
    export LD="${clang}/bin/ld.lld"
  '';
}

{ self }:
{ pkgs ? import <nixpkgs> }:
with pkgs; mkShell rec {
  pname = "neutron";
  version = self.shortRev or "dirty";
  name = "${pname}-${version}";

  packages = [ gdb meson ninja clang pkg-config check flutter-engine ];

  shellHook = ''
    export CC="${clang}/bin/clang"
    export CXX="${clang}/bin/clang++"
    export LD="${clang}/bin/ld.lld"
  '';
}

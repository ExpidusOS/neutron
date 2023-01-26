{ self }:
{ pkgs ? import <nixpkgs> }:
with pkgs; mkShell rec {
  pname = "neutron";
  version = self.shortRev or "dirty";
  name = "${pname}-${version}";

  packages = [ meson ninja clang pkg-config ];

  shellHook = ''
    export CC="${clang}/bin/clang"
    export CXX="${clang}/bin/clang++"
    export LD="${clang}/bin/ld.lld"
  '';
}
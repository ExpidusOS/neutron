{ self }:
{ pkgs ? import <nixpkgs> }:
with pkgs; mkShell rec {
  pname = "neutron";
  version = self.shortRev or "dirty";
  name = "${pname}-${version}";

  packages = [
    gdb valgrind lcov llvmPackages_14.llvm
    meson ninja clang pkg-config expidus.sdk flutter
    gtk-doc libxslt docbook_xsl docbook_xml_dtd_412 docbook_xml_dtd_42 docbook_xml_dtd_43
    check flutter-engine pixman libglvnd
  ];

  shellHook = ''
    export CC="${clang}/bin/clang"
    export CXX="${clang}/bin/clang++"
    export LD="${clang}/bin/ld.lld"
  '';
}

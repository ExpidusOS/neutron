{ self }:
{ pkgs }:
with pkgs;
with lib;
let
  commonBuildInputs = [
    flutter-engine
  ];
in
mkShell rec {
  pname = "neutron";
  version = self.shortRev or "dirty";
  name = "${pname}-${version}";

  packages = with pkgs; [
    emscripten
    gdb valgrind lcov llvmPackages_14.llvm
    meson ninja clang pkg-config dart flutter expidus.sdk
    gtk-doc libxslt docbook_xsl docbook_xml_dtd_412 docbook_xml_dtd_42 docbook_xml_dtd_43
    check pixman libglvnd xorg.libxcb wlroots wayland wayland-protocols udev libxkbcommon
  ] ++ commonBuildInputs;

  mesonFlags = [
    "-Dbootstrap=false"
    "-Dflutter-engine=${flutter-engine}/lib/flutter/out/release"
  ];

  emscriptenCross = pkgs.writeText "emscripten.cross" ''
    [binaries]
    c = '${emscripten}/bin/emcc'
    cpp = '${emscripten}/bin/em++'
    ar = '${emscripten}/bin/emar'
    pkgconfig = ['${emscripten}/bin/emmake', 'env', 'PKG_CONFIG_PATH=${concatMapStringsSep ":" (pkg: "${if "dev" ? pkg then pkg.dev else pkg}/lib/pkgconfig") commonBuildInputs}', '${pkg-config}/bin/pkg-config']
    exec_wrapper = '${nodejs}/bin/node'

    [properties]
    needs_exe_wrapper = true

    [target_machine]
    system = 'emscripten'
    cpu_family = 'wasm32'
    cpu = 'wasm'
    endian = 'little'
  '';

  shellHook = ''
    export CC="${clang}/bin/clang"
    export CXX="${clang}/bin/clang++"
    export LD="${clang}/bin/ld.lld"
  '';
}

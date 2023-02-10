{ self }:
{ pkgs }:
with pkgs;
with lib;
let
  pkg = (import ./overlay.nix { inherit self; } pkgs pkgs).expidus.neutron;
in
mkShell rec {
  pname = "neutron";
  version = self.shortRev or "dirty";
  name = "${pname}-${version}";

  packages = with pkgs; [
    emscripten
    gdb valgrind lcov
  ] ++ pkg.buildInputs ++ pkg.nativeBuildInputs;

  inherit (pkg) mesonFlags;

  emscriptenCross = pkgs.writeText "emscripten.cross" ''
    [binaries]
    c = '${emscripten}/bin/emcc'
    cpp = '${emscripten}/bin/em++'
    ar = '${emscripten}/bin/emar'
    pkgconfig = ['${emscripten}/bin/emmake', 'env', 'PKG_CONFIG_PATH=${concatMapStringsSep ":" (pkg: "${if "dev" ? pkg then pkg.dev else pkg}/lib/pkgconfig") [ flutter-engine ]}', '${pkg-config}/bin/pkg-config']
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

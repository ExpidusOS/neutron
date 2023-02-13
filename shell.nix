{ self }:
{ pkgs }:
with pkgs;
with lib;
let
  overlay = (import ./overlay.nix { inherit self; } pkgs pkgs);
  pkg = overlay.expidus.neutron;
  wasmPkg = overlay.expidus.wasm.neutron;
in
mkShell rec {
  pname = "neutron";
  version = self.shortRev or "dirty";
  name = "${pname}-${version}";

  packages = with pkgs; [
    emscripten
    gdb valgrind lcov
  ] ++ pkg.buildInputs ++ pkg.nativeBuildInputs;

  inherit (pkg) mesonFlags PUB_CACHE;
  wasmMesonFlags = wasmPkg.mesonFlags;

  shellHook = ''
    export CC="${clang}/bin/clang"
    export CXX="${clang}/bin/clang++"
    export LD="${clang}/bin/ld.lld"
  '';
}

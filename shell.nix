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

    export rootOut=$(dirname $out)
    export dev=$rootOut/dev
    export devdoc=$rootOut/devdoc
    export src=$(dirname $rootOut)
    export baseFlags="--prefix=$out --includedir=$dev/include --buildtype=debugoptimized"
    export mesonFlags="$mesonFlags $baseFlags"
    export wasmMesonFlags="$wasmMesonFlags $baseFlags"

    alias configurePhase="rm -rf $src/build && meson $src $src/build $mesonFlags"
    alias buildPhase="ninja -C $src/build"
    alias checkPhase="ninja -C $src/build test"
    alias installPhase="rm -rf $rootOut && ninja -C $src/build install && mkdir -p $dev/lib $devdoc/share && mv $out/lib/neutron $dev/lib/neutron && mv $out/lib/pkgconfig $dev/lib/pkgconfig && mv $out/share/gtk-doc $devdoc/share/gtk-doc && rmdir $out/share"
  '';
}

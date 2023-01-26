{ self }:
final: prev:
with final;
with lib;
let
  mkPackage = mesonBuildType: clang14Stdenv.mkDerivation {
    pname = "neutron${if mesonBuildType == "release" then "" else "-${mesonBuildType}"}";
    version = self.shortRev or "dirty";

    src = cleanSource self;
    outputs = [ "out" "dev" ];
    inherit mesonBuildType;

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
in
rec {
  expidus = prev.expidus.extend (f: p: {
    defaultPackage = f.neutron;
    neutron = mkPackage "release";
    neutron-debug = mkPackage "debugoptimized";
  });
}

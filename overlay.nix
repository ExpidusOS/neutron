{ self }:
final: prev:
with final;
with lib;
rec {
  expidus = prev.expidus.extend (f: p: {
    defaultPackage = f.neutron;
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
  });
}

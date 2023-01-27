{ self }:
final: prev:
with final;
with lib;
rec {
  expidus = prev.expidus.extend (f: p: {
    defaultPackage = f.neutron;

    neutron = (p.neutron.mkPackage {
      rev = self.shortRev or "dirty";
      src = cleanSource self;
      buildType = "release";
    }).overrideAttrs (s: {
      nativeBuildInputs = with buildPackages; [ meson ninja pkg-config ];
      buildInputs = (s.buildInputs or []) ++ [ check flutter-engine ];
      doCheck = true;
    });
  });
}

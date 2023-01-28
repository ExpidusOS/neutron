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
      nativeBuildInputs = (s.nativeBuildInputs or []) ++ (with buildPackages; [ hotdoc llvmPackages_14.libclang ]);
      buildInputs = (s.buildInputs or []) ++ [ flutter-engine ];
      doCheck = true;
    });
  });
}

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
      nativeBuildInputs = s.nativeBuildInputs ++ (with buildPackages; [ flutter ]);
      buildInputs = s.buildInputs ++ [ flutter-engine pixman libglvnd ];
      mesonFlags = (s.mesonFlags or []) ++ [ "-Dbootstrap=false" ];
    });
  });
}

{ self }:
final: prev:
with final;
with lib;
rec {
  expidus = prev.expidus.extend (f: p:
    let
      makeOverride = p: (p.neutron.mkPackage {
        rev = self.shortRev or "dirty";
        src = cleanSource self;
        buildType = "release";
      }).overrideAttrs (s: {
        nativeBuildInputs = s.nativeBuildInputs ++ (with buildPackages; [ flutter dart ]);
        buildInputs = (s.buildInputs or []) ++ [ xorg.libxcb wlroots ];
        mesonFlags = (s.mesonFlags or []) ++ [ "-Dbootstrap=false" "-Dflutter-engine=${flutter-engine}/lib/flutter/out/release" ];
      });
    in {
      defaultPackage = f.neutron;
      neutron = makeOverride p;

      wasm = p.wasm.extend(f: p: {
        neutron = makeOverride p;
      });
    });
}

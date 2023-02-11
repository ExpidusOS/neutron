{ self }:
final: prev:
with final;
with lib;
rec {
  expidus = prev.expidus.extend (f: p:
    let
      makeOverride = p: isWASM: (p.neutron.mkPackage {
        rev = self.shortRev or "dirty";
        src = cleanSource self;
        buildType = "release";
        inherit isWASM;
      }).overrideAttrs (p: {
        nativeBuildInputs = p.nativeBuildInputs ++ (with buildPackages; [ busybox ]);
      });
    in {
      defaultPackage = f.neutron;
      neutron = makeOverride p false;

      wasm = p.wasm.extend(f: p: {
        neutron = makeOverride p true;
      });
    });
}

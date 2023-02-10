{ self }:
final: prev:
with final;
with lib;
rec {
  expidus = prev.expidus.extend (f: p:
    let
      makeOverride = p: p.neutron.mkPackage {
        rev = self.shortRev or "dirty";
        src = cleanSource self;
        buildType = "release";
      };
    in {
      defaultPackage = f.neutron;
      neutron = makeOverride p;

      wasm = p.wasm.extend(f: p: {
        neutron = makeOverride p;
      });
    });
}

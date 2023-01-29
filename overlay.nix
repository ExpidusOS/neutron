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
      nativeBuildInputs = (s.nativeBuildInputs or []) ++ (with buildPackages; [
        gtk-doc libxslt docbook_xsl docbook_xml_dtd_412
        docbook_xml_dtd_42 docbook_xml_dtd_43
      ]);
      buildInputs = (s.buildInputs or []) ++ [ flutter-engine ];
      doCheck = true;
    });
  });
}

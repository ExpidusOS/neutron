{
  description = "A common system library for handling things such as rotation, calls, networking, etc.";

  inputs.expidus-sdk = {
    url = github:ExpidusOS/sdk;
  };

  outputs = { self, expidus-sdk }:
    with expidus-sdk.lib;
    let
      #unsupportedSystems = builtins.map (name: "${name}-cygwin") [ "i686" "x86_64" ];
      unsupportedSystems = [];
      defaultSupported = lists.flatten (builtins.attrValues expidus.system.defaultSupported);
    in
    expidus.flake.makeOverride {
      inherit self;
      name = "neutron";
      sysconfig = expidus.system.make {
        supported = lists.subtractLists unsupportedSystems defaultSupported;
      };
    };
}

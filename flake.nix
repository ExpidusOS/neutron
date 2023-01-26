{
  description = "Core API for ExpidusOS";

  inputs.expidus-sdk.url = github:ExpidusOS/sdk/refactor;

  outputs = { self, expidus-sdk }:
    with expidus-sdk.lib;
    flake-utils.simpleFlake {
      inherit self;
      nixpkgs = expidus-sdk;
      name = "expidus";
      overlay = import ./overlay.nix { inherit self; };
      shell = import ./shell.nix { inherit self; };
    };
}

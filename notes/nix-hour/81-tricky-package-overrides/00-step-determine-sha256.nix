{ system ? builtins.currentSystem }:
let
  nixpkgs = fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/f958e5369ed761df557c362d4de3566084e9eefb.tar.gz";
    sha256 = "";
  };
  pkgs = import nixpkgs {
    config = { };
    overlays = [ ];
    inherit system;
  };
in pkgs.hello

final: prev: let
  inherit (final) lib;
  manifests = import ./mmanifests/mmanifests.nix {
    inherit lib;
  };
in {
}

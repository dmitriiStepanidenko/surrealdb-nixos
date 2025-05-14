{
  lib,
  stdenvNoCC,
  fetchzip,
  autoPatchelfHook,
  glibc,
  gcc-unwrapped,
}: {
  version,
  hash,
}: let
  mkComponent = _:
    stdenvNoCC.mkDerivation rec {
      pname = "surrealdb-bin";
      name = "${pname}-${version}";
      src = fetchzip {
        inherit version hash;
        url = "https://github.com/surrealdb/surrealdb/releases/download/v${version}/surreal-v${version}.linux-amd64.tgz";
        name = "surrealdb.tgz";
      };

      nativeBuildInputs = [autoPatchelfHook];
      buildInputs = [
        glibc
        gcc-unwrapped
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        install -m755 surreal $out/bin
        runHook postInstall
      '';

      meta = with lib; {
        description = "SurrealDB database";
        platforms = platforms.gnu;
      };
    };
  self = mkComponent;
in
  self

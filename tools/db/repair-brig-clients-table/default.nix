# WARNING: GENERATED FILE, DO NOT EDIT.
# This file is generated by running hack/bin/generate-local-nix-packages.sh and
# must be regenerated whenever local packages are added or removed, or
# dependencies are added or removed.
{ mkDerivation
, base
, cassandra-util
, conduit
, gitignoreSource
, imports
, lens
, lib
, optparse-applicative
, time
, tinylog
, types-common
}:
mkDerivation {
  pname = "repair-brig-clients-table";
  version = "1.0.0";
  src = gitignoreSource ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    base
    cassandra-util
    conduit
    imports
    lens
    optparse-applicative
    time
    tinylog
    types-common
  ];
  description = "Removes and reports entries from brig.clients that have been accidentally upserted.";
  license = lib.licenses.agpl3Only;
  mainProgram = "repair-brig-clients-table";
}

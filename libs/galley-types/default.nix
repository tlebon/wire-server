# WARNING: GENERATED FILE, DO NOT EDIT.
# This file is generated by running hack/bin/generate-local-nix-packages.sh and
# must be regenerated whenever local packages are added or removed, or
# dependencies are added or removed.
{ mkDerivation
, aeson
, base
, bytestring
, bytestring-conversion
, containers
, cryptonite
, errors
, gitignoreSource
, imports
, lens
, lib
, memory
, QuickCheck
, schema-profunctor
, tasty
, tasty-hunit
, tasty-quickcheck
, text
, types-common
, uuid
, wire-api
}:
mkDerivation {
  pname = "galley-types";
  version = "0.81.0";
  src = gitignoreSource ./.;
  libraryHaskellDepends = [
    aeson
    base
    bytestring
    bytestring-conversion
    containers
    cryptonite
    errors
    imports
    lens
    memory
    QuickCheck
    schema-profunctor
    text
    types-common
    uuid
    wire-api
  ];
  testHaskellDepends = [
    aeson
    base
    containers
    imports
    lens
    QuickCheck
    tasty
    tasty-hunit
    tasty-quickcheck
    wire-api
  ];
  license = lib.licenses.agpl3Only;
}

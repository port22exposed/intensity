{
  lib,
  stdenv,
  fetchFromGitHub,
  zig_0_13,
}:

let
  zig = zig_0_13;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "intensity";
  version = "0.0.0";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    zig.hook
  ];
})
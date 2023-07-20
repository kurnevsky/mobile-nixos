{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "bootlogd";
  version = "2020-02-02";

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "bootlogd";
    rev = "8ae8710cba23509e72adc37d4d52856953e50193";
    sha256 = "";
  };

  sourceRoot = "source/src";

  makeFlags = [
    "PREFIX=${placeholder "out"}"
  ];

  meta = with lib; {
    license = licenses.gpl2;
  };
}

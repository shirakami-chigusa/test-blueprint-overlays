{ pkgs, ... }:
pkgs.stdenv.mkDerivation {
  name = "my-hello";
  src = ./.;

  buildInputs = [ pkgs.hello ];

  installPhase = ''
    mkdir -p $out/bin
    cp ${pkgs.hello}/bin/* $out/bin/
  '';
}

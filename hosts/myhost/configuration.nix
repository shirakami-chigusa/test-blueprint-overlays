{
  lib,
  pkgs,
  perSystem,
  ...
}:
{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";

  nixpkgs.overlays = [
    (final: prev: {
      hello = final.htop;
    })
  ];

  environment.systemPackages = with pkgs; [
    perSystem.self.my-hello
    # pkgs.hello
  ];

  system.stateVersion = 5;
}

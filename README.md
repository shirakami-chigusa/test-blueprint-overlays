I'm trying to configure `nixpkgs.overlays` per-host, not globally.

I confirmed that if `nixpkgs.overlays` is defined in `configuration.nix` instead of directly under `inputs.blueprint` in `flake.nix`, the overlays are not enabled in `packages/<pname>/default.nix`.

### System Info

- blueprint: 7ae2142c8b5a47bed6d403fdd5f5a1215961e10c
- system: `"aarch64-darwin"`
- host os: `Darwin 24.3.0, macOS 15.3.2`
- multi-user?: `yes`
- sandbox: `no`
- version: `nix-env (Nix) 2.24.12`
- nixpkgs: `/nix/store/bgkmh40ahkw48wxwmwbilnvjdjgcn3n6-source`

### packages/my-hello/default.nix

This package is to test whether `nixpkgs.overlays` is valid in the package definition.
It is simply extracts the `pkgs.hello` as is.
If `pkgs.hello` is overlaid on `pkgs.htop`, the output will be `htop`.

```nix
# packages/my-hello/default.nix
{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  name = "my-hello";
  src = ./.;

  buildInputs = [ pkgs.hello ];

  installPhase = ''
    mkdir -p $out/bin
    cp ${pkgs.hello}/bin/* $out/bin/
  '';
}
```

### 1. overlays in flake.nix + nix build .#my-hello = OK.

set `nixpkgs.overlays` in `flake.nix` (global).

https://github.com/numtide/blueprint/blob/main/docs/configuration.md#nixpkgsoverlays

```nix
# flake.nix
    inputs.blueprint {
      inherit inputs;
      nixpkgs.overlays = [
        (final: prev: {
          hello = prev.htop;
        })
      ];
    };
```

run `nix build .#my-hello`.

result is `./result/bin/htop`. OK.

### 2. overlays in flake.nix + perSystem.self.my-hello = OK.

set `nixpkgs.overlays` in `flake.nix` (global).

```nix
# flake.nix
    inputs.blueprint {
      inherit inputs;
      nixpkgs.overlays = [
        (final: prev: {
          hello = prev.htop;
        })
      ];
    };
```

install the overlaid package `perSystem.self.my-hello`.

```nix
# hosts/myhost/configuration.nix
  environment.systemPackages = with pkgs; [
    perSystem.self.my-hello
  ];
```

run `darwin-rebuild build --flake .#myhost`

result is `./result/sw/bin/htop`. OK.

### 3. overlays in configuration.nix + perSystem.self.my-hello = NG!!!

set `nixpkgs.overlays` in `hosts/myhost/configuration.nix`.

install the overlaid package `perSystem.self.my-hello`.

```nix
# hosts/myhost/configuration.nix
  nixpkgs.overlays = [
    (final: prev: {
      hello = prev.htop;
    })
  ];
  environment.systemPackages = with pkgs; [
    perSystem.self.my-hello
  ];
```

run `darwin-rebuild build --flake .#myhost`

result is `./result/sw/bin/hello`.
`pkgs.hello` in `packages/my-hello` is not overlaid. NG!!!

### 4. overlays in configuration.nix + overlaid pkgs.hello = OK.

set `nixpkgs.overlays` in `hosts/myhost/configuration.nix`.

install the overlaid package `pkgs.hello`.

```nix
# configuration.nix

  nixpkgs.overlays = [
    (final: prev: {
      hello = prev.htop;
    })
  ];

  environment.systemPackages = with pkgs; [
    pkgs.hello
  ];
```

result is `./result/sw/bin/htop`. OK.
`pkgs.hello` is overlaid correctly.

### Conclusion

`nixpkgs.overlays` in `configuration.nix` is not being applied to internal packages.

Is this my fault or a bug?

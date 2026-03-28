# introdus
Based on:
https://codeberg.org/fidgetingbits/introdus

## Package build

```
nix flake show
nix build .#codecrate

```

Update one package manually (example):

```bash
nix run nixpkgs#nix-update -- codecrate --flake --override-filename pkgs/codecrate/package.nix
run codecrate --override-filename pkgs/codecrate/package.nix
run pathspec  --override-filename pkgs/pathspec.nix

```
### nix-update

```
nix run nixpkgs#nix-update -- codecrate --flake --override-filename pkgs/codecrate/package.nix
nix run nixpkgs#nix-update -- pathspec  --flake --override-filename pkgs/pathspec/package.nix



nix run nixpkgs#nix-update -- codecrate --flake --version 0.3.4

```

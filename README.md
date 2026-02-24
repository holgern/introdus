# introdus
Based on:
https://codeberg.org/fidgetingbits/introdus

## Package build

```
nix flake show
nix build .#codecrate

nix build -L .#odoo-lsp
nix build -L .#odoo-ls

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
nix run nixpkgs#nix-update -- odoo-lsp --flake --override-filename pkgs/odoo-lsp/package.nix
nix run nixpkgs#nix-update -- odoo-ls --flake --override-filename pkgs/odoo-ls/package.nix



nix run nixpkgs#nix-update -- codecrate --flake --version 0.3.4
nix run nixpkgs#nix-update -- odoo-lsp --flake --version nightly-20260206

```

### odoo-ls

```
tmp="$(mktemp -d)"
git clone --depth 1 --branch beta https://github.com/odoo/odoo-ls "$tmp/odoo-ls"
cd "$tmp/odoo-ls/server"

# one-off environment
nix shell nixpkgs#cargo nixpkgs#rustc -c cargo generate-lockfile

# copy into your repo
cp Cargo.lock /path/to/your/repo/pkgs/odoo-ls/Cargo.lock

```

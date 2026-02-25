set shell := ["bash", "-euo", "pipefail", "-c"]

[private]
default:
    @just --list

# Run nix flake checks and formatting
[group("building")]
check:
    nix fmt
    NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure --show-trace -L

# Build all packages (compile gate)
[group("building")]
buildall:
  nix build -L .#checks.x86_64-linux.all-packages

# Build a package (compile gate)
[group("building")]
build input:
  nix build --print-build-logs --show-trace .#{{ input }}

# Run bats only
[group("building")]
test:
  nix build -L .#checks.x86_64-linux.bats-test

# List custom packages
[group("building")]
list:
  nix eval --json .#packages.x86_64-linux --apply builtins.attrNames

# Update all the flake inputs
[group('nix')]
up:
  nix flake update --commit-lock-file

# Update specific input
# Usage: just upp nixpkgs
[group('nix')]
upp input:
  nix flake update {{input}} --commit-lock-file

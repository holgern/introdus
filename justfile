[private]
default:
    @just --list

# Run nix flake checks and formatting
[group("building")]
check:
    nix fmt
    NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure --show-trace -L

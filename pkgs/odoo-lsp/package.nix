# pkgs/odoo-lsp.nix
{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "odoo-lsp";
  version = "nightly-20260206";

  src = fetchFromGitHub {
    owner = "Desdaemon";
    repo = "odoo-lsp";
    rev = "${version}";
    hash = "sha256-laGLt9Pw5czRZXzX909ZPVDaNQc+PvpXm0Q1cA9YiQA=";
    fetchSubmodules = true;
  };

  # Replace git_version macros with env-var based consts (no git needed, no .git needed)
  postPatch = ''
    substituteInPlace src/version.rs \
      --replace-fail \
        'git_version::git_version!(args = ["--tags", "--candidates=0"], fallback = "")' \
        'match option_env!("GIT_VERSION") { Some(v) => v, None => "" }' \
      --replace-fail \
        'git_version::git_version!()' \
        'match option_env!("GIT_TAG") { Some(v) => v, None => concat!("v", env!("CARGO_PKG_VERSION")) }'
  '';

  # What the patched code will read at compile time.
  # (GITVER uses GIT_VERSION if non-empty, else GIT_TAG.)
  GIT_VERSION = "v${version}";
  GIT_TAG = "v${version}";

  cargoLock = {
    lockFile = src + "/Cargo.lock";
    outputHashes = {
      "tree-sitter-scheme-0.23.0" = "sha256-FK3F7v2LqAtXZM/CKCijWfXTF6TUhLmiVXScZqt46Io=";
    };
  };

  doCheck = false;

  meta = with lib; {
    description = "Language server for Odoo (Desdaemon/odoo-lsp)";
    homepage = "https://github.com/Desdaemon/odoo-lsp";
    license = licenses.mit;
    mainProgram = "odoo-lsp";
    platforms = platforms.unix;
  };
}

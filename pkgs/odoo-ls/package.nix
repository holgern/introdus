# pkgs/odoo-ls/default.nix
{
  lib,
  stdenv,
  rustPlatform,
  fetchgit,
  fetchurl,
  pkg-config,
  openssl,
  coreutils,

  # allow callers (overlay/flake inputs) to inject locked sources
  src ? null,
  configSchema ? null,
}:

let
  version = "1.2.0";
  rev = "a5e855b2da27485f55082e8ecd023171e81ed7bd";

  src' =
    if src != null then
      src
    else
      fetchgit {
        url = "https://github.com/odoo/odoo-ls.git";
        inherit rev;
        hash = "sha256-4Lruv4Q0JaInh115BW7Dx9Zg8u0EYiHwitR4NOJ7A90=";
        fetchSubmodules = true;
      };

  configSchema' =
    if configSchema != null then
      configSchema
    else
      fetchurl {
        url = "https://github.com/odoo/odoo-ls/releases/download/${version}/config_schema.json";
        hash = "sha256-F6kfyhhrDYNAOXAJ/BgGF8HeisqxpssatZrlwHOlYig=";
      };
in
rustPlatform.buildRustPackage rec {
  pname = "odoo-ls";
  inherit version;
  src = src';

  cargoRoot = "server";
  buildAndTestSubdir = "server";

  postPatch = ''
    install -m644 ${./Cargo.lock} server/Cargo.lock
  '';

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "ruff_python_ast-0.0.0" = "sha256-jRH7OOT03MDomZAJM20+J4y5+xjN1ZAV27Z44O1qCEQ=";
      "lsp-server-0.7.8" = "sha256-M+bLCsYRYA7iudlZkeOf+Azm/1TUvihIq51OKia6KJ8=";
    };
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ openssl ];

  doCheck = false;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/odoo-ls $out/libexec/odoo-ls

    # Locate built server binary
    bin="$(find . -type f -path '*/target/*/release/*' -perm -0100 \
      \( -name odoo_ls_server -o -name odoo-ls -o -name odoo_ls \) | head -n1)"
    if [ -z "$bin" ]; then
      echo "odoo-ls: could not find built server binary" >&2
      find . -type f -path '*/target/*/release/*' -print >&2
      exit 1
    fi

    install -m755 "$bin" $out/libexec/odoo-ls/odoo_ls_server.real

    # typeshed must be populated (submodule)
    if [ ! -d server/typeshed/stdlib ]; then
      echo "odoo-ls: typeshed is missing (server/typeshed/stdlib not found)" >&2
      echo "This means submodules were not fetched. Ensure src uses submodules." >&2
      exit 1
    fi

    cp -a server/typeshed $out/libexec/odoo-ls/typeshed

    install -m644 ${configSchema'} $out/libexec/odoo-ls/config_schema.json
    install -m644 ${configSchema'} $out/share/odoo-ls/config_schema.json

    # Wrapper: copy to a writable runtime dir (works even if HOME=/homeless-shelter)
    cat > $out/bin/odoo_ls_server <<'EOF'
    #!${stdenv.shell}
    set -euo pipefail
    export PATH=${coreutils}/bin:$PATH

    self="$(readlink -f "$0")"
    out="$(cd "$(dirname "$self")/.." && pwd -P)"

    real="$out/libexec/odoo-ls/odoo_ls_server.real"
    assets="$out/libexec/odoo-ls"

    uid="$(id -u)"

    candidates=()

    if [ -n "${"$"}{XDG_RUNTIME_DIR-}" ]; then candidates+=("$XDG_RUNTIME_DIR"); fi
    if [ -n "${"$"}{XDG_STATE_HOME-}" ]; then candidates+=("$XDG_STATE_HOME"); fi
    if [ -n "${"$"}{XDG_CACHE_HOME-}" ]; then candidates+=("$XDG_CACHE_HOME"); fi

    if [ -n "${"$"}{HOME-}" ]; then
      case "$HOME" in
        /homeless-shelter|/homeless-shelter/*) ;;
        *) candidates+=("$HOME/.local/state" "$HOME/.cache") ;;
      esac
    fi

    if [ -n "${"$"}{TMPDIR-}" ]; then candidates+=("$TMPDIR"); fi
    candidates+=("/tmp")

    pick_base() {
      for d in "${"$"}{candidates[@]}"; do
        [ -n "$d" ] || continue
        mkdir -p "$d" 2>/dev/null || continue
        [ -w "$d" ] || continue
        echo "$d"
        return 0
      done
      return 1
    }

    base="$(pick_base || true)"
    if [ -z "$base" ]; then
      echo "odoo_ls_server: could not find a writable runtime directory." >&2
      echo "Set XDG_STATE_HOME or TMPDIR to a writable path." >&2
      exit 1
    fi

    case "$base" in
      /tmp|/tmp/*) runtime="$base/odoo-ls-$uid/runtime-${version}" ;;
      *) runtime="$base/odoo-ls/runtime-${version}" ;;
    esac

    mkdir -p "$runtime"

    need_copy=0
    [ -x "$runtime/odoo_ls_server" ] || need_copy=1
    [ -d "$runtime/typeshed/stdlib" ] || need_copy=1

    cur_real=""
    if [ -r "$runtime/.real" ]; then
      cur_real="$(cat "$runtime/.real" 2>/dev/null || true)"
    fi
    if [ "$cur_real" != "$real" ]; then
      need_copy=1
    fi

    if [ "$need_copy" -eq 1 ]; then
      rm -rf "$runtime"
      mkdir -p "$runtime"
      cp -f "$real" "$runtime/odoo_ls_server"
      chmod +x "$runtime/odoo_ls_server"
      cp -a "$assets/typeshed" "$runtime/typeshed"
      [ -f "$assets/config_schema.json" ] && cp -f "$assets/config_schema.json" "$runtime/config_schema.json"
      printf '%s\n' "$real" > "$runtime/.real"
    fi

    has_stdlib=0
    for a in "$@"; do
      case "$a" in
        --stdlib|--stdlib=*) has_stdlib=1 ;;
      esac
    done
    if [ "$has_stdlib" -eq 0 ]; then
      set -- --stdlib "$runtime/typeshed/stdlib" "$@"
    fi

    exec "$runtime/odoo_ls_server" "$@"
    EOF

    chmod +x $out/bin/odoo_ls_server

    # Optional convenience alias
    ln -sf odoo_ls_server $out/bin/odoo-ls

    runHook postInstall
  '';

  meta = with lib; {
    description = "Odoo Language Server (server component) built from source";
    homepage = "https://github.com/odoo/odoo-ls";
    license = licenses.lgpl3Only;
    mainProgram = "odoo_ls_server";
    platforms = platforms.unix;
  };
}

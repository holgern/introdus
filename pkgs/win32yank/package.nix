{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "win32yank";
  version = "0.1.1";

  src = fetchzip {
    url = "https://github.com/equalsraf/win32yank/releases/download/v${version}/win32yank-x64.zip";
    hash = "sha256-4ivE1cYZhYs4ibx5oiYMOhbse9bdOomk7RjgdVl5lD0=";
    stripRoot = false;
  };

  dontBuild = true;

  installPhase = ''
        install -Dm755 win32yank.exe $out/bin/win32yank.exe

        # optional convenience wrapper (lets you run `win32yank` too)
        cat > $out/bin/win32yank <<'EOF'
    #!/bin/sh
    exec "$(dirname "$0")/win32yank.exe" "$@"
    EOF
        chmod +x $out/bin/win32yank
  '';

  meta = with lib; {
    description = "Windows clipboard tool (useful in WSL)";
    homepage = "https://github.com/equalsraf/win32yank";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}

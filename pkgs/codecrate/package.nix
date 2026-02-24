# pkgs/codecrate.nix
{
  lib,
  python3Packages,
}:
let
  py = python3Packages;
  localPathspec = import ../pathspec/package.nix {
    inherit lib python3Packages;
  };
in
py.buildPythonPackage rec {
  pname = "codecrate";
  version = "0.3.3";

  pyproject = true;

  src = py.fetchPypi {
    inherit pname version;
    hash = "sha256-tPYfgx1NT4bHxxPN29pdHWJMWvvKRBK2kgCNPJwXY38=";
  };

  build-system = with py; [
    setuptools
    wheel
    setuptools-scm
  ];

  dependencies = [
    localPathspec
  ];

  # optional but nice
  pythonImportsCheck = [ "codecrate" ];

  meta = with lib; {
    description = "Pack Python repos into LLM-friendly Markdown and apply/validate patches";
    homepage = "https://pypi.org/project/codecrate/";
    license = licenses.mit;
    mainProgram = "codecrate";
  };
}

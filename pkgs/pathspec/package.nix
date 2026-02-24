# pkgs/pathspec.nix
{
  lib,
  python3Packages,
}:
let
  py = python3Packages;
in
py.buildPythonPackage rec {
  pname = "pathspec";
  version = "1.0.4";

  pyproject = true;

  src = py.fetchPypi {
    inherit pname version;
    hash = "sha256-AhDiroohqRN8DUcFeMsOWVr4ftqm6/Ev8XbxSgLg5kU=";
  };

  # pathspec uses Flit as the PEP517 backend
  build-system = [ py.flit-core ];

  # Avoid the earlier hatchling/pytest recursion issues
  doCheck = false;

  pythonImportsCheck = [ "pathspec" ];

  meta = with lib; {
    description = "Utility library for gitignore-style pattern matching of file paths";
    homepage = "https://github.com/cpburnz/python-pathspec";
    license = licenses.mpl20;
  };
}

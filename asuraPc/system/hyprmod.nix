# Declarative packaging for hyprmod and its PyPI dependencies
{ pkgs, python3Packages }:

let
  hyprland-socket = python3Packages.buildPythonPackage rec {
    pname = "hyprland-socket";
    version = "0.12.1";
    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "2b45b5f01f53bbf691695085d1bc39ae401ac39ab9481c1cc89bcff01a315a85";
    };
    doCheck = false;
    pyproject = true;
    build-system = [ python3Packages.hatchling ];
  };

  hyprland-monitors = python3Packages.buildPythonPackage rec {
    pname = "hyprland-monitors";
    version = "0.7.0";
    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "08b6d881b5d99b865288568ae77a9422eb2ab657f86a939bfc438d66fa70dd14";
    };
    doCheck = false;
    pyproject = true;
    build-system = [ python3Packages.hatchling ];
    dependencies = [ hyprland-socket ];
  };

  hyprland-state = python3Packages.buildPythonPackage rec {
    pname = "hyprland-state";
    version = "0.4.2";
    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "6b3f1553abca10a75f5a5f9d2f53d33704f1cebb557e2138bd41abbd58612e89";
    };
    doCheck = false;
    pyproject = true;
    build-system = [ python3Packages.hatchling ];
    dependencies = [ hyprland-socket ];
  };

  hyprland-schema = python3Packages.buildPythonPackage rec {
    pname = "hyprland-schema";
    version = "0.6.1";
    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "58426d95102684cf382ce71e354b42dcd2f25fa11ec52c3f75859cbbe59c535a";
    };
    doCheck = false;
    pyproject = true;
    build-system = [ python3Packages.hatchling ];
    dependencies = [ hyprland-monitors ];
  };

  hyprland-config = python3Packages.buildPythonPackage rec {
    pname = "hyprland-config";
    version = "0.9.5";
    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "a1836f4b74c370d2cbf37db22e1d906ecb47c3e1d399e1e2c8cbed74fbf9dbc5";
    };
    doCheck = false;
    pyproject = true;
    build-system = [ python3Packages.hatchling ];
    dependencies = [ hyprland-schema ];
  };

in
python3Packages.buildPythonApplication rec {
  pname = "hyprmod";
  version = "0.3.0";

  src = pkgs.fetchFromGitHub {
    owner = "BlueManCZ";
    repo = "hyprmod";
    rev = "v${version}";
    sha256 = "0529c894qp181zgqg5330556j6va5m112l4nha4cws6xny4yvvm0";
  };

  pyproject = true;

  build-system = [
    python3Packages.hatchling
  ];

  dependencies = [
    python3Packages.pygobject3
    hyprland-config
    hyprland-schema
    hyprland-state
    hyprland-monitors
    hyprland-socket
  ];

  nativeBuildInputs = [
    pkgs.gobject-introspection
    pkgs.wrapGAppsHook4
  ];

  buildInputs = [
    pkgs.gtk4
    pkgs.libadwaita
  ];

  doCheck = false;

  meta = with pkgs.lib; {
    description = "A native GTK4/libadwaita settings app for Hyprland";
    homepage = "https://github.com/BlueManCZ/hyprmod";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}

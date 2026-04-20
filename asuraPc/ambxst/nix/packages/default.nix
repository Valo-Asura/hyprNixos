# Main Ambxst package
{ pkgs, lib, self, system, quickshell, ambxstLib }:

let
  quickshellPkg = quickshell.packages.${system}.default;

  # Import sub-packages
  ttf-phosphor-icons = import ./phosphor-icons.nix { inherit pkgs; };

  # Import modular package lists
  corePkgs = import ./core.nix { inherit pkgs quickshellPkg; };
  toolsPkgs = import ./tools.nix { inherit pkgs; };
  mediaPkgs = import ./media.nix { inherit pkgs; };
  appsPkgs = import ./apps.nix { inherit pkgs; };
  fontsPkgs = import ./fonts.nix { inherit pkgs ttf-phosphor-icons; };
  tesseractPkgs = import ./tesseract.nix { inherit pkgs; };

  # Combine all packages (NixOS-specific deps handled by the module)
  baseEnv = corePkgs
    ++ toolsPkgs
    ++ mediaPkgs
    ++ appsPkgs
    ++ fontsPkgs
    ++ tesseractPkgs;

  envAmbxst = pkgs.buildEnv {
    name = "Ambxst-env";
    paths = baseEnv;
  };

  # Create fontconfig configuration to find bundled fonts
  fontconfigConf = pkgs.writeTextDir "etc/fonts/conf.d/99-ambxst-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <dir>${envAmbxst}/share/fonts</dir>
    </fontconfig>
  '';

  # Copy shell sources to the Nix store
  shellSrc = pkgs.stdenv.mkDerivation {
    pname = "ambxst-shell";
    version = "0.1.0";
    src = lib.cleanSource self;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  };

  launcher = pkgs.writeShellScriptBin "ambxst" ''
    export AMBXST_QS="${quickshellPkg}/bin/qs"
    # /run/wrappers/bin first so setuid wrappers (e.g. gpu-screen-recorder) take priority
    export PATH="/run/wrappers/bin:${envAmbxst}/bin:$PATH"

    # Load AI secrets if provided via sops-nix
    for var in OPENCLAW_GATEWAY_TOKEN OPENAI_API_KEY OPENROUTER_API_KEY GEMINI_API_KEY MISTRAL_API_KEY GITHUB_TOKEN; do
      secret_path="/run/secrets/$var"
      if [ -r "$secret_path" ]; then
        export "$var"="$(cat "$secret_path")"
      fi
    done

    # Set QML2_IMPORT_PATH to include modules from envAmbxst (like syntax-highlighting)
    export QML2_IMPORT_PATH="${envAmbxst}/lib/qt-6/qml:$QML2_IMPORT_PATH"
    export QML_IMPORT_PATH="$QML2_IMPORT_PATH"

    # Make bundled fonts available to fontconfig
    export FONTCONFIG_PATH="${fontconfigConf}/etc/fonts:''${FONTCONFIG_PATH:-}"

    # Delegate execution to CLI (now in the Nix store)
    exec ${shellSrc}/cli.sh "$@"
  '';

in pkgs.buildEnv {
  name = "Ambxst";
  paths = [ envAmbxst launcher ];
  meta.mainProgram = "ambxst";
}

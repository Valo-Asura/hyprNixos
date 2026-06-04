{
  bash,
  cairo,
  fontconfig,
  grim,
  hyprlock,
  lib,
  libGL,
  libxkbcommon,
  makeWrapper,
  meson,
  ninja,
  pango,
  pkg-config,
  slurp,
  stdenv,
  wayland,
  wayland-scanner,
  wofi,
}:

stdenv.mkDerivation {
  pname = "vibeshellREzero";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      let
        rel = lib.removePrefix ((toString ./.) + "/") (toString path);
      in
      !(type == "directory" && rel == "build") && !lib.hasPrefix "build/" rel;
  };

  nativeBuildInputs = [
    makeWrapper
    meson
    ninja
    pkg-config
    wayland-scanner
  ];

  buildInputs = [
    cairo
    fontconfig
    libGL
    libxkbcommon
    pango
    wayland
  ];

  postInstall = ''
    makeWrapper "$out/bin/vibeshellREzero" "$out/bin/vibeshell-zero" \
      --set-default VIBESHELLREZERO_CONFIG "$out/share/vibeshellREzero/config/default.toml"

    install -Dm644 "$src/config/default.toml" "$out/share/vibeshellREzero/config/default.toml"

    cat > "$out/bin/vibeshell" <<'EOF'
#!${bash}/bin/bash
set -euo pipefail

bin="@out@/bin/vibeshellREzero"

case "''${1:-}" in
  "")
    exec "$bin" --config "@out@/share/vibeshellREzero/config/default.toml"
    ;;
  msg)
    shift
    exec "$bin" msg "$@"
    ;;
  run)
    shift
    case "''${1:-}" in
      app-launcher|drun|wofi)
        exec ${wofi}/bin/wofi --show drun
        ;;
      screenshot)
        mkdir -p "$HOME/Pictures/Screenshots"
        exec ${grim}/bin/grim "$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png"
        ;;
      screenshot-area)
        mkdir -p "$HOME/Pictures/Screenshots"
        exec ${grim}/bin/grim -g "$(${slurp}/bin/slurp)" "$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png"
        ;;
      launcher|overview|powermenu|dashboard*|tools|config|screenrecord|lens|presets)
        exec "$bin" msg run "''${1:-dashboard}"
        ;;
      lockscreen)
        exec ${hyprlock}/bin/hyprlock
        ;;
      *)
        exec "$bin" msg run "''${1:-dashboard}"
        ;;
    esac
    ;;
  reload|refresh)
    exec "$bin" msg refresh
    ;;
  quit)
    exec "$bin" msg quit
    ;;
  lock)
    exec ${hyprlock}/bin/hyprlock
    ;;
  help|--help|-h)
    exec "$bin" --help
    ;;
  *)
    exec "$bin" msg "$@"
    ;;
esac
EOF
    substituteInPlace "$out/bin/vibeshell" --replace-fail "@out@" "$out"
    chmod +x "$out/bin/vibeshell"
  '';

  meta = {
    description = "Native C++ Wayland/OpenGL ES VibeShell rewrite MVP";
    mainProgram = "vibeshellREzero";
    platforms = lib.platforms.linux;
  };
}

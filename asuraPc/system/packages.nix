# System Packages Configuration
{ lib, pkgs, inputs, ... }:

{
  environment.systemPackages = (with pkgs; [
    # System Info & Terminal
    microfetch
    zsh
    fish

    # System Tools
    polkit
    udisks2
    udiskie

    # Screenshot and Screen Recording
    grimblast
    hyprshot
    swappy # Screenshot editor

    # Polkit Agent
    inputs.hyprpolkitagent.packages.${pkgs.stdenv.hostPlatform.system}.default

    # File Management & NTFS Support
    thunar # Lightweight GTK file manager (replaces nemo + cinnamon-common)
    xarchiver
    gvfs
    ntfs3g
    exfat # Windows filesystem support

    # Desktop Environment
    xdg-utils
    networkmanager
    tuigreet # removed swaylock (using hyprlock)
    xdg-user-dirs # xdg-desktop-portals in services.nix

    # Vibeshell required packages (system-level integration; core deps come from Vibeshell package)
    (writeShellScriptBin "internet-unblock" ''
      set -euo pipefail

      ${systemd}/bin/systemctl stop ollama-model-loader.service >/dev/null 2>&1 || true
      ${procps}/bin/pkill -f 'ollama pull' >/dev/null 2>&1 || true
      ${systemd}/bin/resolvectl flush-caches >/dev/null 2>&1 || true
      ${networkmanager}/bin/nmcli general reload >/dev/null 2>&1 || true

      echo "Network blockers cleared: model downloads stopped and DNS cache flushed."
    '')
    (writeShellScriptBin "vibeshell-safe-lock" ''
      set -euo pipefail

      runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
      lock_file="$runtime_dir/vibeshell-safe-lock.lock"
      exec 9>"$lock_file"
      ${util-linux}/bin/flock -n 9 || exit 0

      user_id="$(${coreutils}/bin/id -u)"
      if ${procps}/bin/pgrep -xu "$user_id" -x hyprlock >/dev/null 2>&1; then
        exit 0
      fi

      if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch dpms on >/dev/null 2>&1 || true
      fi

      exec ${hyprlock}/bin/hyprlock --grace 0 --immediate-render --no-fade-in
    '')
    (writeShellScriptBin "vibeshell-lock-before-sleep" ''
      set -euo pipefail

      user_id="$(${coreutils}/bin/id -u)"
      if ! ${procps}/bin/pgrep -xu "$user_id" -x hyprlock >/dev/null 2>&1; then
        ${coreutils}/bin/mkdir -p "''${XDG_STATE_HOME:-$HOME/.local/state}/Vibeshell"
        nohup /run/current-system/sw/bin/vibeshell-safe-lock \
          >>"''${XDG_STATE_HOME:-$HOME/.local/state}/Vibeshell/hyprlock.log" 2>&1 &
      fi

      for _ in $(${coreutils}/bin/seq 1 30); do
        if ${procps}/bin/pgrep -xu "$user_id" -x hyprlock >/dev/null 2>&1; then
          exit 0
        fi
        ${coreutils}/bin/sleep 0.1
      done
    '')
    dconf
    gtk3
    gtk4
    adwaita-icon-theme
    gsettings-desktop-schemas
    at-spi2-atk
    at-spi2-core
    libgtop

    # Multimedia
    vlc

    # Hyprland Panel Dependencies
    bluez
    hyprsunset
    hypridle

    # Development
    wget
    git
    jq
    eza
    bat
    fd
    ripgrep
    direnv
    nix-direnv
    nixfmt
    nil
    uv
    inter
    sops
    docker
    docker-compose

    # IDE
    antigravity
    vscodium
    zed-editor
    appimage-run
    (writeShellScriptBin "zed" ''
      exec ${zed-editor}/bin/zeditor "$@"
    '')
    (writeShellScriptBin "codex" ''
      set -euo pipefail

      arch="linux-x86_64"
      case "$(${coreutils}/bin/uname -m)" in
        aarch64|arm64)
          arch="linux-arm64"
          ;;
      esac

      for extension_dir in \
        "$HOME"/.vscode/extensions/openai.chatgpt-* \
        "$HOME"/.vscode-oss/extensions/openai.chatgpt-* \
        "$HOME"/.kiro/extensions/openai.chatgpt-* \
        "$HOME"/.windsurf/extensions/openai.chatgpt-*; do
        codex_bin="$extension_dir/bin/$arch/codex"
        if [ -x "$codex_bin" ]; then
          exec "$codex_bin" "$@"
        fi
      done

      echo "Codex CLI was not found in VS Code, VSCodium, Kiro, or Windsurf extensions." >&2
      echo "Install the OpenAI Codex extension (openai.chatgpt), then retry." >&2
      exit 127
    '')
    (writeShellScriptBin "cursor" ''
      set -euo pipefail

      cursor_url="https://downloads.cursor.com/production/806df57ed3b6f1ee0175140d38039a38574ec722/linux/x64/Cursor-3.2.21-x86_64.AppImage"
      cursor_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/cursor"
      cursor_appimage="$cursor_dir/Cursor.AppImage"
      cursor_partial="$cursor_appimage.part"

      mkdir -p "$cursor_dir"
      if [ ! -x "$cursor_appimage" ]; then
        echo "Downloading Cursor AppImage..."
        ${curl}/bin/curl \
          --fail \
          --location \
          --continue-at - \
          --connect-timeout 20 \
          --speed-time 60 \
          --speed-limit 1024 \
          --retry 3 \
          --retry-all-errors \
          --output "$cursor_partial" \
          "$cursor_url"
        mv "$cursor_partial" "$cursor_appimage"
        chmod +x "$cursor_appimage"
      fi

      exec ${appimage-run}/bin/appimage-run "$cursor_appimage" "$@"
    '')
    (writeShellScriptBin "cursor-update" ''
      rm -f "''${XDG_DATA_HOME:-$HOME/.local/share}/cursor/Cursor.AppImage"
      exec cursor "$@"
    '')
    (writeShellScriptBin "openhands" ''
      set -euo pipefail

      openhands_bin="$HOME/.local/bin/openhands"
      if [ ! -x "$openhands_bin" ]; then
        echo "Installing OpenHands CLI with uv..."
        ${uv}/bin/uv tool install openhands --python ${python312}/bin/python3.12
      fi

      exec "$openhands_bin" "$@"
    '')
    (writeShellScriptBin "openhands-gui" ''
      exec openhands serve --mount-cwd "$@"
    '')
    (writeShellScriptBin "openhands-update" ''
      exec ${uv}/bin/uv tool upgrade openhands --python ${python312}/bin/python3.12
    '')

    # Terminal enhancements
    btop
    tree
    fzf
    curl
    yq

    # Python Environment
    (python3.withPackages (
      ps: with ps; [
        pip
        requests
      ]
    ))
  ]) ++ lib.optionals (builtins.hasAttr "windsurf" pkgs) [
    pkgs.windsurf
  ];
}

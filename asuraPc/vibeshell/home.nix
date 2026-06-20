# Vibeshell Home Manager integration
{ lib, pkgs, ... }:

{
  home.activation.seedVibeshellMutableConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        install_mutable_config() {
          local source="$1"
          local target="$2"
          local resolved=""

          mkdir -p "$(dirname "$target")"

          if [ -L "$target" ]; then
            resolved="$(readlink -f "$target" || true)"
            case "$resolved" in
              /nix/store/*)
                rm -f "$target"
                install -m 0644 "$source" "$target"
                return
                ;;
            esac
          fi

          if [ ! -e "$target" ]; then
            install -m 0644 "$source" "$target"
          fi
        }

        install_mutable_config ${./binds.json} "$HOME/.config/Vibeshell/binds.json"
        install_mutable_config ${./system.json} "$HOME/.config/Vibeshell/config/system.json"

        lockscreen_config="$HOME/.config/Vibeshell/config/lockscreen.json"
        if [ -f "$lockscreen_config" ]; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq '
            if .imagePath == "/etc/nixos/asuraPc/hyprland/lock-images/lockscreen.png"
            then .imagePath = ""
            else .
            end
          ' "$lockscreen_config" > "$tmp" \
            && install -m 0644 "$tmp" "$lockscreen_config"
          rm -f "$tmp"
        fi

        binds_config="$HOME/.config/Vibeshell/binds.json"
        if [ -f "$binds_config" ]; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq '
            .vibeshell.dashboard |= del(.assistant)
            |
            .vibeshell.dashboard.clipboard.modifiers = ["SUPER"]
            | .vibeshell.dashboard.clipboard.key = "V"
            | .vibeshell.dashboard.widgets.argument = "vibeshell run notch-launcher"
            | .vibeshell.system.screenshot.modifiers = []
            | .vibeshell.system.screenshot.key = "Print"
          ' "$binds_config" > "$tmp" \
            && install -m 0644 "$tmp" "$binds_config"
          rm -f "$tmp"
        fi

        performance_config="$HOME/.config/Vibeshell/config/performance.json"
        mkdir -p "$(dirname "$performance_config")"
        if [ -f "$performance_config" ]; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq '.wavyLine = false | .blurTransition = false | .windowPreview = false' "$performance_config" > "$tmp" \
            && install -m 0644 "$tmp" "$performance_config"
          rm -f "$tmp"
        else
          install -m 0644 ${./config/defaults/performance.js} "$performance_config.js"
          cat > "$performance_config" <<'EOF'
    {
        "blurTransition": false,
        "windowPreview": false,
        "wavyLine": false
    }
    EOF
          rm -f "$performance_config.js"
        fi

        theme_config="$HOME/.config/Vibeshell/config/theme.json"
        mkdir -p "$(dirname "$theme_config")"
        if [ -f "$theme_config" ]; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq '
            .animDuration = 300
            | .enableCorners = true
            | .shadowBlur = 1
            | .shadowOpacity = 0.5
          ' "$theme_config" > "$tmp" \
            && install -m 0644 "$tmp" "$theme_config"
          rm -f "$tmp"
        fi

        notch_config="$HOME/.config/Vibeshell/config/notch.json"
        mkdir -p "$(dirname "$notch_config")"
        if [ -f "$notch_config" ]; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq '
            .theme = "default"
            | .hoverRegionHeight = 8
          ' "$notch_config" > "$tmp" \
            && install -m 0644 "$tmp" "$notch_config"
          rm -f "$tmp"
        else
          cat > "$notch_config" <<'EOF'
    {
        "theme": "default",
        "hoverRegionHeight": 8
    }
    EOF
        fi

        hyprland_config="$HOME/.config/Vibeshell/config/hyprland.json"
        mkdir -p "$(dirname "$hyprland_config")"
        if [ -f "$hyprland_config" ]; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq '
            .shadowEnabled = false
            | .shadowRange = 4
            | .shadowRenderPower = 2
            | .shadowOpacity = 0.25
            | .blurEnabled = false
            | .blurSize = 2
            | .blurPasses = 1
            | .blurSpecial = false
            | .blurPopups = false
            | .blurInputMethods = false
          ' "$hyprland_config" > "$tmp" \
            && install -m 0644 "$tmp" "$hyprland_config"
          rm -f "$tmp"
        else
          cat > "$hyprland_config" <<'EOF'
    {
        "shadowEnabled": false,
        "shadowRange": 4,
        "shadowRenderPower": 2,
        "shadowOpacity": 0.25,
        "blurEnabled": false,
        "blurSize": 2,
        "blurPasses": 1,
        "blurSpecial": false,
        "blurPopups": false,
        "blurInputMethods": false
    }
    EOF
        fi

        rm -f "$HOME/.config/Vibeshell/config/ai.json"
        rm -rf "$HOME/.config/nanobot"

        wallpaper_state="$HOME/.local/share/Vibeshell/wallpapers.json"
        wallpaper_dir="$HOME/Pictures/wallpaper"
        fallback_wall="$wallpaper_dir/mystical-journey-through-pink-blossom-canyon.jpg"
        mkdir -p "$(dirname "$wallpaper_state")"
        if [ -f "$wallpaper_state" ]; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq --arg dir "$wallpaper_dir" --arg fallback "$fallback_wall" '
            .wallPath = $dir
            | if (
                (.currentWall // "") == ""
                or .currentWall == "/etc/nixos/asuraPc/assets/sans.png"
                or ((.currentWall // "") | test("(?i)\\.(gif|mp4|webm|mov|avi|mkv)$"))
              )
              then .currentWall = $fallback
              else .
              end
          ' "$wallpaper_state" > "$tmp" \
            && install -m 0644 "$tmp" "$wallpaper_state"
          rm -f "$tmp"
        else
          cat > "$wallpaper_state" <<EOF
    {
        "activeColorPreset": "Rose Pine",
        "currentWall": "$fallback_wall",
        "matugenScheme": "scheme-tonal-spot",
        "wallPath": "$wallpaper_dir"
    }
    EOF
        fi
        ${pkgs.procps}/bin/pkill -f '/bin/mpvpaper( |$)' >/dev/null 2>&1 || true

        lockscreen_config="$HOME/.config/Vibeshell/config/lockscreen.json"
        mkdir -p "$(dirname "$lockscreen_config")"
        if [ -f "$lockscreen_config" ]; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq '
            .position = (.position // "bottom")
            | if ((.imagePath // "") | length) == 0
              then .imagePath = "/etc/nixos/asuraPc/hyprland/lock-images/lockscreen.png"
              else .
              end
          ' "$lockscreen_config" > "$tmp" \
            && install -m 0644 "$tmp" "$lockscreen_config"
          rm -f "$tmp"
        else
          cat > "$lockscreen_config" <<'EOF'
    {
        "position": "bottom",
        "imagePath": "/etc/nixos/asuraPc/hyprland/lock-images/lockscreen.png"
    }
    EOF
        fi
  '';
}

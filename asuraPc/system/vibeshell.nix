{ inputs, pkgs, ... }:

let
  # Toggle Switch: set to true to test vibeshellREzero (C++ native rewrite)
  # or false to keep using the standard Vibeshell (Quickshell/QML)
  useREzero = false;

  vibeshellREzeroPkg = pkgs.callPackage ../vibeshellREzero/package.nix { };
  quickshellPkg = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  localVibeshellPkg = import ../vibeshell/nix/packages {
    inherit pkgs;
    lib = pkgs.lib;
    self = ../vibeshell;
    system = pkgs.stdenv.hostPlatform.system;
    quickshell = inputs.quickshell;
    vibeshellLib = import ../vibeshell/nix/lib.nix { inherit (inputs) nixpkgs; };
  };

  vibeshellSafeLock = pkgs.writeShellScriptBin "vibeshell-safe-lock" ''
    set -euo pipefail

    if command -v vibeshell >/dev/null 2>&1; then
      if vibeshell lock; then
        exit 0
      fi
      echo "vibeshell lock failed, falling back to hyprlock" >&2
    fi

    if ${pkgs.procps}/bin/pgrep -x hyprlock >/dev/null 2>&1; then
      exit 0
    fi

    exec ${pkgs.hyprlock}/bin/hyprlock
  '';

  vibeshellLockBeforeSleep = pkgs.writeShellScriptBin "vibeshell-lock-before-sleep" ''
    set -euo pipefail

    ${vibeshellSafeLock}/bin/vibeshell-safe-lock
    sleep 1
  '';

  switchShell = pkgs.writeShellApplication {
    name = "switch-shell";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      findutils
      gawk
      gnugrep
      gnused
      nix
      procps
      python3
      util-linux
      quickshellPkg
      localVibeshellPkg
    ];
    text = ''
      set -euo pipefail

      PROJECTS_ROOT="''${QUICKSHELL_PROJECTS_ROOT:-/home/asura/Downloads/Projects}"
      QT_EXTRA_QML_IMPORTS="${pkgs.kdePackages.qt5compat}/${pkgs.qt6.qtbase.qtQmlPrefix}"
      QT_EXTRA_LIBRARY_PATH="${pkgs.kdePackages.qt5compat}/lib"
      STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-switch"
      PID_FILE="$STATE_DIR/pid"
      NAME_FILE="$STATE_DIR/current"
      SHELL_FILE="$STATE_DIR/shell"
      LOG_FILE="$STATE_DIR/current.log"
      LOCK_FILE="''${XDG_RUNTIME_DIR:-/tmp}/quickshell-switch.lock"

      mkdir -p "$STATE_DIR"

      QS_BIN="''${QUICKSHELL_BIN:-}"
      if [ -z "$QS_BIN" ]; then
        if command -v quickshell >/dev/null 2>&1; then
          QS_BIN="$(command -v quickshell)"
        elif command -v qs >/dev/null 2>&1; then
          QS_BIN="$(command -v qs)"
        else
          echo "No quickshell/qs binary found in PATH" >&2
          exit 1
        fi
      fi

      usage() {
        cat <<'EOF'
      Usage: switch-shell [command] [target]

      Commands:
        list                  List VibeShell plus discovered Projects shells
        current               Show tracked/current shell
        switch <name|num|path> Switch to a discovered shell
        next                  Switch to next shell in list
        prev                  Switch to previous shell in list
        stop                  Stop managed/VibeShell/Projects shell processes
        restore               Switch back to system VibeShell

      Shortcuts:
        switch-shell caelestia
        switch-shell ricelin:pill
        switch-shell 3

      Environment:
        QUICKSHELL_PROJECTS_ROOT=/path/to/projects
        QUICKSHELL_BIN=/path/to/quickshell
        TIDE_ISLAND_BOOTSTRAP=0 disables Tide first-run config seeding
        TIDE_ISLAND_WALLPAPER=/path/to/image overrides Tide bootstrap wallpaper
      EOF
      }

      discover_projects() {
        [ -d "$PROJECTS_ROOT" ] || return 0

        find "$PROJECTS_ROOT" \
          -type f \
          -name shell.qml \
          -not -path '*/.git/*' \
          -not -path '*/node_modules/*' \
          -print \
          | sort \
          | while IFS= read -r shell; do
              dir="$(dirname "$shell")"
              rel="''${dir#"$PROJECTS_ROOT"/}"
              if [ "$rel" = "$dir" ]; then
                rel="$(basename "$dir")"
              fi
              name="$(printf '%s' "$rel" | sed 's#/#:#g')"
              printf '%s\t%s\n' "$name" "$shell"
            done
      }

      entries() {
        printf '%s\t%s\n' "vibeshell" "builtin:vibeshell"
        discover_projects
      }

      shell_pids() {
        ps -eo pid=,args= | awk \
          -v root="$PROJECTS_ROOT" \
          -v runtime="$HOME/.config/Vibeshell/runtime-shell/shell.qml" \
          -v repo="/etc/nixos/asuraPc/vibeshell/shell.qml" '
            /\/(qs|quickshell)( |$)/ && /shell\.qml/ {
              if (index($0, root) > 0 || index($0, runtime) > 0 || index($0, repo) > 0) {
                print $1
              }
            }
          '
      }

      collect_process_tree() {
        queue="$*"
        seen=" "

        while [ -n "$queue" ]; do
          pid="''${queue%% *}"
          if [ "$queue" = "$pid" ]; then
            queue=""
          else
            queue="''${queue#* }"
          fi

          [ -n "$pid" ] || continue
          [ -d "/proc/$pid" ] || continue

          case "$seen" in
            *" $pid "*) continue ;;
          esac

          seen="$seen$pid "
          printf '%s\n' "$pid"

          children="$(pgrep -P "$pid" 2>/dev/null | tr '\n' ' ' || true)"
          [ -z "$children" ] || queue="$queue $children"
        done
      }

      tracked_pid_alive() {
        [ -f "$PID_FILE" ] || return 1
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        [ -n "$pid" ] || return 1
        kill -0 "$pid" 2>/dev/null
      }

      tracked_pid_value() {
        [ -f "$PID_FILE" ] || return 1
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        [ -n "$pid" ] || return 1
        [ -d "/proc/$pid" ] || return 1
        printf '%s\n' "$pid"
      }

      managed_pids() {
        {
          shell_pids
          if pid="$(tracked_pid_value 2>/dev/null)"; then
            collect_process_tree "$pid"
          fi
        } | awk 'NF && !seen[$1]++ { print $1 }'
      }

      regex_escape() {
        printf '%s' "$1" | sed 's/[][(){}.^$*+?|\\]/\\&/g'
      }

      command_contains() {
        pgrep -f -- "$(regex_escape "$1")" >/dev/null 2>&1
      }

      current_name() {
        if tracked_pid_alive && [ -f "$NAME_FILE" ]; then
          cat "$NAME_FILE"
          return 0
        fi

        if command_contains "$HOME/.config/Vibeshell/runtime-shell/shell.qml"; then
          printf '%s\n' "vibeshell"
          return 0
        fi

        while IFS="$(printf '\t')" read -r name shell; do
          [ "$name" != "vibeshell" ] || continue
          if command_contains "$shell"; then
            printf '%s\n' "$name"
            return 0
          fi
        done < <(entries)

        printf '%s\n' "none"
      }

      cleanup_vibeshell_helpers() {
        patterns=(
          "/etc/nixos/asuraPc/vibeshell/scripts/clipboard_watch.sh"
          "/etc/nixos/asuraPc/vibeshell/scripts/sleep_monitor.sh"
          "/etc/nixos/asuraPc/vibeshell/scripts/loginlock.sh"
          "/etc/nixos/asuraPc/vibeshell/scripts/system_monitor.py"
          "/etc/nixos/asuraPc/vibeshell/scripts/weather.sh"
          "vibeshell-shell.*scripts/clipboard_watch.sh"
          "vibeshell-shell.*scripts/sleep_monitor.sh"
          "vibeshell-shell.*scripts/loginlock.sh"
          "vibeshell-shell.*scripts/system_monitor.py"
          "vibeshell-shell.*scripts/weather.sh"
          "dbus-monitor --system.*PrepareForSleep"
          "dbus-monitor --system.*member=.*Lock"
          "wl-paste --watch.*CLIPBOARD_CHANGE"
          "wl-paste --watch.*clipboard_check.sh"
          "tail -f /tmp/vibeshell_ipc.pipe"
          "systemd-inhibit --what=idle:sleep:handle-lid-switch --who=Vibeshell"
        )

        for pattern in "''${patterns[@]}"; do
          pkill -f "$pattern" 2>/dev/null || true
        done
      }

      cleanup_tide_island_setup() {
        pkill -f "Tide Island Setup .*tide-island-setup --wizard" 2>/dev/null || true
        pkill -f "share/tide-island/bin/tide-island-setup --wizard" 2>/dev/null || true

        config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
        rm -f "$config_home/tide-island/setup-wizard.lock"
      }

      cleanup_project_helpers() {
        cleanup_tide_island_setup
      }

      stop_shells() {
        tracked_group_pid="$(tracked_pid_value 2>/dev/null || true)"
        mapfile -t pids < <(managed_pids)
        if [ "''${#pids[@]}" -eq 0 ]; then
          cleanup_vibeshell_helpers
          cleanup_project_helpers
          rm -f "$PID_FILE" "$NAME_FILE" "$SHELL_FILE"
          return 0
        fi

        printf 'Stopping shell PIDs: %s\n' "''${pids[*]}"
        if [ -n "$tracked_group_pid" ]; then
          kill -TERM "-$tracked_group_pid" 2>/dev/null || true
        fi

        for pid in "''${pids[@]}"; do
          kill -TERM "$pid" 2>/dev/null || true
        done

        for _ in $(seq 1 30); do
          alive=0
          for pid in "''${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
              alive=1
              break
            fi
          done
          [ "$alive" -eq 0 ] && break
          sleep 0.1
        done

        if [ -n "$tracked_group_pid" ]; then
          kill -KILL "-$tracked_group_pid" 2>/dev/null || true
        fi

        for pid in "''${pids[@]}"; do
          kill -KILL "$pid" 2>/dev/null || true
        done

        cleanup_vibeshell_helpers
        cleanup_project_helpers
        rm -f "$PID_FILE" "$NAME_FILE" "$SHELL_FILE"
      }

      resolve_target() {
        target="$1"

        if [ -f "$target" ]; then
          printf '%s\t%s\n' "custom" "$(readlink -f "$target")"
          return 0
        fi

        if printf '%s' "$target" | grep -Eq '^[0-9]+$'; then
          entries | sed -n "''${target}p"
          return 0
        fi

        entries | awk -F '\t' -v target="$target" '
          BEGIN { wanted = tolower(target) }
          tolower($1) == wanted {
            print
            found = 1
            exit
          }
          END { exit found ? 0 : 1 }
        '
      }

      start_vibeshell() {
        stop_shells
        printf 'Starting system VibeShell\n'
        : >"$LOG_FILE"
        setsid vibeshell 9>&- >>"$LOG_FILE" 2>&1 &
        pid="$!"
        printf '%s\n' "$pid" >"$PID_FILE"
        printf '%s\n' "vibeshell" >"$NAME_FILE"
        printf '%s\n' "builtin:vibeshell" >"$SHELL_FILE"
        printf 'Started vibeshell (PID %s). Log: %s\n' "$pid" "$LOG_FILE"
      }

      project_dir_for_shell() {
        dirname "$1"
      }

      launcher_for_project() {
        name="$1"
        shell="$2"
        dir="$(project_dir_for_shell "$shell")"

        case "$name" in
          caelestia)
            if [ -f "$PROJECTS_ROOT/caelestia/flake.nix" ]; then
              printf '%s\n' "flake:path:$PROJECTS_ROOT/caelestia#caelestia-shell"
              return 0
            fi
            ;;
          tide-island)
            if [ -f "$PROJECTS_ROOT/tide-island/flake.nix" ]; then
              printf '%s\n' "flake:path:$PROJECTS_ROOT/tide-island"
              return 0
            fi
            ;;
        esac

        if [ -x "$dir/quickshell-switch-launch" ]; then
          printf '%s\n' "exec:$dir/quickshell-switch-launch"
          return 0
        fi

        printf '%s\n' "raw:$shell"
      }

      export_raw_qml_runtime() {
        export QML2_IMPORT_PATH="$QT_EXTRA_QML_IMPORTS''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
        export QML_IMPORT_PATH="$QT_EXTRA_QML_IMPORTS''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
        export LD_LIBRARY_PATH="$QT_EXTRA_LIBRARY_PATH''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        export QT_QPA_PLATFORMTHEME="''${QT_QPA_PLATFORMTHEME:-qt6ct}"
      }

      is_tide_image_file() {
        path="$1"
        [ -n "$path" ] || return 1
        [ -r "$path" ] || return 1

        lower="$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')"
        case "$lower" in
          *.jpg | *.jpeg | *.png | *.webp) return 0 ;;
        esac

        return 1
      }

      json_string_value() {
        file="$1"
        key="$2"

        [ -f "$file" ] || return 1
        sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$file" | head -n 1
      }

      tide_wallpaper_path() {
        if is_tide_image_file "''${TIDE_ISLAND_WALLPAPER:-}"; then
          printf '%s\n' "$TIDE_ISLAND_WALLPAPER"
          return 0
        fi

        for source in \
          "$HOME/.cache/skwd-wall/last-wallpaper.json:path" \
          "$HOME/.cache/skwd-wall/outputs.json:path" \
          "$HOME/.local/share/Vibeshell/wallpapers.json:currentWall"; do
          file="''${source%:*}"
          key="''${source#*:}"
          candidate="$(json_string_value "$file" "$key" || true)"
          if is_tide_image_file "$candidate"; then
            printf '%s\n' "$candidate"
            return 0
          fi
        done

        for candidate in \
          "$HOME/Pictures/Wallpapers/example_wallpaper.webp" \
          "$HOME/Pictures/Wallpapers/mystical-journey-through-pink-blossom-canyon.webp" \
          "$HOME/Pictures/Wallpapers/wallhaven-ly2yg2.webp" \
          "$HOME/Pictures/Wallpapers/lord-shiva-dark-7680x4320-25582.webp" \
          "/etc/nixos/asuraPc/assets/she.jpg" \
          "/etc/nixos/asuraPc/hyprland/lock-images/lockscreen.png"; do
          if is_tide_image_file "$candidate"; then
            printf '%s\n' "$candidate"
            return 0
          fi
        done

        return 1
      }

      bootstrap_tide_island_config() {
        [ "''${TIDE_ISLAND_BOOTSTRAP:-1}" != "0" ] || return 0

        wallpaper="$(tide_wallpaper_path || true)"
        if [ -z "$wallpaper" ]; then
          echo "No readable image wallpaper found for Tide Island bootstrap; setup wizard may open." >&2
          return 0
        fi

        config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
        config_dir="$config_home/tide-island"
        config_file="$config_dir/userconfig.json"
        mkdir -p "$config_dir"
        chmod 700 "$config_dir" 2>/dev/null || true

        python3 - "$config_file" "$wallpaper" <<'PY'
      import json
      import os
      import re
      import shutil
      import sys
      import time

      config_file = sys.argv[1]
      wallpaper = sys.argv[2]

      defaults = {
          "islandWidth": 140,
          "islandHeight": 38,
          "islandPositionX": 50,
          "iconFontFamily": "JetBrainsMono Nerd Font",
          "textFontFamily": "Inter Display",
          "heroFontFamily": "Inter Display",
          "timeFontFamily": "Inter Display",
          "bodyFontSize": 16,
          "titleFontSize": 20,
          "iconFontSize": 18,
          "dynamicIslandPrimaryButton": 1,
          "dynamicIslandPrimaryAction": "toggleExpandedPlayer",
          "dynamicIslandSecondaryButton": 3,
          "dynamicIslandSecondaryAction": "toggleControlCenter",
          "dynamicIslandLeftSwipeItems": ["cava", "battery"],
          "overviewGlobalShortcutAppid": "quickshell",
          "overviewGlobalShortcutName": "dynamic-island-overview",
          "workspaceOverviewWindowDragButton": 1,
          "tlpSudoPassword": "",
          "disableAutoExpandOnTrackChange": False,
          "enableHoverExpand": False,
          "hoverExpandAction": 1,
      }

      def strip_json_comments(text: str) -> str:
          text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
          stripped: list[str] = []
          for line in text.splitlines():
              out: list[str] = []
              in_string = False
              escaped = False
              i = 0
              while i < len(line):
                  ch = line[i]
                  nxt = line[i + 1] if i + 1 < len(line) else ""
                  if not in_string and ch == "/" and nxt == "/":
                      break
                  out.append(ch)
                  if ch == '"' and not escaped:
                      in_string = not in_string
                  escaped = ch == "\\" and not escaped
                  if ch != "\\":
                      escaped = False
                  i += 1
              stripped.append("".join(out))
          return "\n".join(stripped)

      def load_config() -> dict:
          if not os.path.exists(config_file):
              return {}
          with open(config_file, "r", encoding="utf-8") as handle:
              raw = handle.read()
          if not raw.strip():
              return {}
          try:
              parsed = json.loads(strip_json_comments(raw))
          except Exception:
              backup = f"{config_file}.invalid-{int(time.time())}"
              shutil.copy2(config_file, backup)
              return {}
          return parsed if isinstance(parsed, dict) else {}

      data = load_config()
      for key, value in defaults.items():
          data.setdefault(key, value)

      current_wallpaper = data.get("wallpaperPath")
      if not isinstance(current_wallpaper, str) or not os.path.isfile(os.path.expanduser(current_wallpaper)):
          data["wallpaperPath"] = wallpaper

      tlp_mode = data.get("tlpPermissionMode")
      tlp_password = data.get("tlpSudoPassword")
      if tlp_mode not in {"skip", "ask", "password"} or (tlp_mode == "password" and not tlp_password):
          data["tlpPermissionMode"] = "skip"
          data["tlpSudoPassword"] = ""

      if not isinstance(data.get("hyprlandBindMode"), str) or not data["hyprlandBindMode"]:
          data["hyprlandBindMode"] = "manual"

      temp_file = f"{config_file}.tmp"
      with open(temp_file, "w", encoding="utf-8") as handle:
          json.dump(data, handle, indent=4)
          handle.write("\n")
      os.chmod(temp_file, 0o600)
      os.replace(temp_file, config_file)
      PY

        rm -f "$config_dir/setup-wizard.lock"
      }

      start_project_shell() {
        name="$1"
        shell="$2"

        [ -f "$shell" ] || {
          echo "Shell file not found: $shell" >&2
          exit 1
        }

        stop_shells
        if [ "$name" = "tide-island" ]; then
          bootstrap_tide_island_config
        fi

        safe_name="$(printf '%s' "$name" | tr -c 'A-Za-z0-9_' '_')"
        launcher="$(launcher_for_project "$name" "$shell")"
        printf 'Starting %s: %s\n' "$name" "$shell"
        printf 'Launcher: %s\n' "$launcher"
        : >"$LOG_FILE"

        case "$launcher" in
          flake:*)
            flake_ref="''${launcher#flake:}"
            # shellcheck disable=SC2016
            setsid bash -c '
              exec 9>&-
              export QS_APP_ID="switch_shell_$1"
              export QT_QPA_PLATFORMTHEME="''${QT_QPA_PLATFORMTHEME:-qt6ct}"
              exec nix run "$2"
            ' _ "$safe_name" "$flake_ref" >>"$LOG_FILE" 2>&1 &
            ;;
          exec:*)
            launch_exec="''${launcher#exec:}"
            # shellcheck disable=SC2016
            setsid bash -c '
              exec 9>&-
              export QS_APP_ID="switch_shell_$1"
              export QT_QPA_PLATFORMTHEME="''${QT_QPA_PLATFORMTHEME:-qt6ct}"
              exec "$2"
            ' _ "$safe_name" "$launch_exec" >>"$LOG_FILE" 2>&1 &
            ;;
          raw:*)
            raw_shell="''${launcher#raw:}"
            # shellcheck disable=SC2016
            setsid bash -c '
              exec 9>&-
              export QS_APP_ID="switch_shell_$1"
              export QML2_IMPORT_PATH="$2''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
              export QML_IMPORT_PATH="$2''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
              export LD_LIBRARY_PATH="$3''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
              export QT_QPA_PLATFORMTHEME="''${QT_QPA_PLATFORMTHEME:-qt6ct}"
              exec "$4" -p "$5"
            ' _ "$safe_name" "$QT_EXTRA_QML_IMPORTS" "$QT_EXTRA_LIBRARY_PATH" "$QS_BIN" "$raw_shell" >>"$LOG_FILE" 2>&1 &
            ;;
          *)
            echo "Unsupported launcher: $launcher" >&2
            exit 1
            ;;
        esac

        pid="$!"
        sleep 0.3
        if ! kill -0 "$pid" 2>/dev/null; then
          echo "Shell exited immediately. Log: $LOG_FILE" >&2
          exit 1
        fi

        printf '%s\n' "$pid" >"$PID_FILE"
        printf '%s\n' "$name" >"$NAME_FILE"
        printf '%s\n' "$shell" >"$SHELL_FILE"
        printf 'Started %s (PID %s). Log: %s\n' "$name" "$pid" "$LOG_FILE"
      }

      switch_to() {
        target="$1"
        if [ -z "$target" ]; then
          echo "Missing target" >&2
          usage
          exit 1
        fi

        line="$(resolve_target "$target" || true)"
        if [ -z "$line" ]; then
          echo "Unknown shell target: $target" >&2
          echo "Run: switch-shell list" >&2
          exit 1
        fi

        IFS="$(printf '\t')" read -r name shell <<<"$line"
        if [ "$name" = "vibeshell" ]; then
          start_vibeshell
        else
          start_project_shell "$name" "$shell"
        fi
      }

      switch_relative() {
        direction="$1"
        mapfile -t lines < <(entries)
        [ "''${#lines[@]}" -gt 0 ] || {
          echo "No shells discovered" >&2
          exit 1
        }

        current="$(current_name)"
        index=0
        for i in "''${!lines[@]}"; do
          IFS="$(printf '\t')" read -r name _ <<<"''${lines[$i]}"
          if [ "$name" = "$current" ]; then
            index="$i"
            break
          fi
        done

        if [ "$direction" = "next" ]; then
          index=$(( (index + 1) % ''${#lines[@]} ))
        else
          index=$(( (index - 1 + ''${#lines[@]}) % ''${#lines[@]} ))
        fi

        IFS="$(printf '\t')" read -r name shell <<<"''${lines[$index]}"
        if [ "$name" = "vibeshell" ]; then
          start_vibeshell
        else
          start_project_shell "$name" "$shell"
        fi
      }

      list_shells() {
        current="$(current_name)"
        i=1
        entries | while IFS="$(printf '\t')" read -r name shell; do
          marker=" "
          [ "$name" = "$current" ] && marker="*"
          printf '%s %2d  %-24s %s\n' "$marker" "$i" "$name" "$shell"
          i=$((i + 1))
        done
      }

      show_current() {
        name="$(current_name)"
        printf 'current: %s\n' "$name"
        [ -f "$SHELL_FILE" ] && printf 'shell: %s\n' "$(cat "$SHELL_FILE")"
        [ -f "$PID_FILE" ] && printf 'pid: %s\n' "$(cat "$PID_FILE")"
        printf 'log: %s\n' "$LOG_FILE"
      }

      with_lock() {
        exec 9>"$LOCK_FILE"
        flock -n 9 || {
          echo "Another switch-shell operation is already running" >&2
          exit 1
        }
        "$@"
      }

      command="''${1:-list}"
      case "$command" in
        list | ls)
          list_shells
          ;;
        current | status)
          show_current
          ;;
        switch)
          with_lock switch_to "''${2:-}"
          ;;
        next)
          with_lock switch_relative next
          ;;
        prev | previous)
          with_lock switch_relative prev
          ;;
        stop)
          with_lock stop_shells
          ;;
        restore | default | vibeshell)
          with_lock start_vibeshell
          ;;
        help | --help | -h)
          usage
          ;;
        *)
          with_lock switch_to "$command"
          ;;
      esac
    '';
  };

  quickshellSwitch = pkgs.writeShellScriptBin "quickshell-switch" ''
    exec ${switchShell}/bin/switch-shell "$@"
  '';

  quickshellLauncher = pkgs.writeShellApplication {
    name = "quickshell-launcher";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      gawk
      gnugrep
      procps
      wofi
      quickshellPkg
      localVibeshellPkg
    ];
    text = ''
      set -euo pipefail

      PROJECTS_ROOT="''${QUICKSHELL_PROJECTS_ROOT:-/home/asura/Downloads/Projects}"
      QT_EXTRA_QML_IMPORTS="${pkgs.kdePackages.qt5compat}/${pkgs.qt6.qtbase.qtQmlPrefix}"
      QT_EXTRA_LIBRARY_PATH="${pkgs.kdePackages.qt5compat}/lib"
      STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-switch"
      PID_FILE="$STATE_DIR/pid"
      NAME_FILE="$STATE_DIR/current"
      SHELL_FILE="$STATE_DIR/shell"
      AUX_PID_FILE="$STATE_DIR/launcher-pid"
      AUX_LOG_FILE="$STATE_DIR/launcher.log"

      mkdir -p "$STATE_DIR"

      QS_BIN="''${QUICKSHELL_BIN:-}"
      if [ -z "$QS_BIN" ]; then
        if command -v quickshell >/dev/null 2>&1; then
          QS_BIN="$(command -v quickshell)"
        elif command -v qs >/dev/null 2>&1; then
          QS_BIN="$(command -v qs)"
        else
          echo "No quickshell/qs binary found in PATH" >&2
          exec wofi --show drun
        fi
      fi

      pid_alive() {
        pid="''${1:-}"
        [ -n "$pid" ] || return 1
        kill -0 "$pid" 2>/dev/null
      }

      tracked_pid() {
        [ -f "$PID_FILE" ] || return 1
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        pid_alive "$pid" || return 1
        printf '%s\n' "$pid"
      }

      tracked_quickshell_pid() {
        group_pid="$(tracked_pid 2>/dev/null || true)"
        [ -n "$group_pid" ] || return 1

        if ps -p "$group_pid" -o args= 2>/dev/null | grep -Eq '/(qs|quickshell)( |$)'; then
          printf '%s\n' "$group_pid"
          return 0
        fi

        ps -eo pid=,pgid=,args= | awk -v pgid="$group_pid" '
          $2 == pgid && $0 ~ /\/(qs|quickshell)( |$)/ {
            print $1
            exit
          }
        '
      }

      current_name() {
        if [ -f "$NAME_FILE" ] && tracked_pid >/dev/null 2>&1; then
          cat "$NAME_FILE"
          return 0
        fi
        printf '%s\n' "none"
      }

      current_shell() {
        [ -f "$SHELL_FILE" ] || return 1
        cat "$SHELL_FILE"
      }

      focused_monitor() {
        if command -v hyprctl >/dev/null 2>&1; then
          hyprctl monitors 2>/dev/null | awk '
            /^Monitor / { monitor = $2 }
            /focused: yes/ { print monitor; exit }
          '
        fi
      }

      call_active_ipc() {
        target="$1"
        func="$2"
        shift 2

        qs_pid="$(tracked_quickshell_pid || true)"
        [ -n "$qs_pid" ] || return 1
        "$QS_BIN" ipc --pid "$qs_pid" call "$target" "$func" "$@"
      }

      find_aux_launcher_pid() {
        launcher_shell="$PROJECTS_ROOT/ricelin/launcher/shell.qml"

        if [ -f "$AUX_PID_FILE" ]; then
          pid="$(cat "$AUX_PID_FILE" 2>/dev/null || true)"
          if pid_alive "$pid" && ps -p "$pid" -o args= 2>/dev/null | grep -Fq "$launcher_shell"; then
            printf '%s\n' "$pid"
            return 0
          fi
        fi

        ps -eo pid=,args= | awk -v shell="$launcher_shell" '
          /\/(qs|quickshell)( |$)/ && index($0, shell) > 0 {
            print $1
            exit
          }
        '
      }

      ensure_aux_launcher() {
        launcher_shell="$PROJECTS_ROOT/ricelin/launcher/shell.qml"
        [ -f "$launcher_shell" ] || return 1

        pid="$(find_aux_launcher_pid || true)"
        if [ -n "$pid" ]; then
          printf '%s\n' "$pid" >"$AUX_PID_FILE"
          printf '%s\n' "$pid"
          return 0
        fi

        : >"$AUX_LOG_FILE"
        # shellcheck disable=SC2016
        setsid bash -c '
          exec 9>&-
          export QS_APP_ID="switch_shell_ricelin_launcher_overlay"
          export QML2_IMPORT_PATH="$1''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
          export QML_IMPORT_PATH="$1''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
          export LD_LIBRARY_PATH="$2''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          export QT_QPA_PLATFORMTHEME="''${QT_QPA_PLATFORMTHEME:-qt6ct}"
          exec "$3" -p "$4"
        ' _ "$QT_EXTRA_QML_IMPORTS" "$QT_EXTRA_LIBRARY_PATH" "$QS_BIN" "$launcher_shell" >>"$AUX_LOG_FILE" 2>&1 &

        pid="$!"
        printf '%s\n' "$pid" >"$AUX_PID_FILE"
        sleep 0.2
        pid_alive "$pid" || return 1
        printf '%s\n' "$pid"
      }

      open_aux_launcher() {
        monitor="$(focused_monitor || true)"
        [ -n "$monitor" ] || monitor="''${QUICKSHELL_LAUNCHER_MONITOR:-}"

        pid="$(ensure_aux_launcher || true)"
        [ -n "$pid" ] || return 1

        "$QS_BIN" ipc --pid "$pid" call launcher toggle "$monitor"
      }

      open_launcher() {
        name="$(current_name)"
        shell_path="$(current_shell || true)"
        monitor="$(focused_monitor || true)"

        case "$name" in
          vibeshell)
            vibeshell run dashboard-widgets && return 0
            call_active_ipc vibeshell run dashboard-widgets && return 0
            ;;
          caelestia)
            call_active_ipc drawers toggle launcher && return 0
            ;;
          ricelin:launcher)
            call_active_ipc launcher toggle "$monitor" && return 0
            ;;
          ricelin:pill)
            call_active_ipc pill launcher "$monitor" && return 0
            ;;
          tide-island)
            # Tide has workspace overview/control-center IPC, but no app launcher.
            open_aux_launcher && return 0
            ;;
          *)
            if [ "$shell_path" = "builtin:vibeshell" ]; then
              vibeshell run dashboard-widgets && return 0
            fi
            ;;
        esac

        open_aux_launcher && return 0
        exec wofi --show drun
      }

      open_launcher
    '';
  };

in
{
  imports = [ ../vibeshell/nix/modules ];

  programs.vibeshell = {
    enable = !useREzero;
    package = localVibeshellPkg;
    fonts.enable = true;
  };

  programs.skwd-wall.enable = true;

  systemd.user.targets.graphical-session.wants = [ "skwd-daemon.service" ];

  environment.systemPackages = [
    vibeshellSafeLock
    vibeshellLockBeforeSleep
    switchShell
    quickshellSwitch
    quickshellLauncher
    pkgs.material-symbols
    pkgs.google-fonts
    pkgs.papirus-icon-theme
    pkgs.hicolor-icon-theme
  ]
  ++ (if useREzero then [ vibeshellREzeroPkg ] else [ ]);
}

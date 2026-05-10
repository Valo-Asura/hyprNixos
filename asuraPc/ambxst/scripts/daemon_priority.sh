#!/usr/bin/env bash

# Kill notification daemons that may conflict
for daemon in dunst mako swaync; do
	if pgrep -x "$daemon" >/dev/null; then
		echo "Stopping $daemon..."
		pkill -x "$daemon"
	fi
done

# LiteLLM Proxy. Ambxst talks to Ollama directly by default; keep LiteLLM
# opt-in so boot stays fast and stale cloud keys cannot break local chat.
if [ "${AMBXST_ENABLE_LITELLM:-0}" != "1" ]; then
	echo "LiteLLM disabled by default; set AMBXST_ENABLE_LITELLM=1 to start it"
elif pgrep -f "litellm.*--port 4000" >/dev/null; then
	echo "LiteLLM already running on port 4000"
elif command -v litellm >/dev/null; then
	echo "Starting litellm..."

	# Resolve config path relative to script location
	SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
	REPO_ROOT=$(dirname "$SCRIPT_DIR")
	CONFIG_PATH="$REPO_ROOT/modules/services/ai/litellm_config.yaml"

	if [ -f "$CONFIG_PATH" ]; then
		LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ambxst"
		mkdir -p "$LOG_DIR"
		chmod 700 "$LOG_DIR"
		( umask 077; nohup litellm --config "$CONFIG_PATH" --port 4000 >"$LOG_DIR/litellm.log" 2>&1 & )
		echo "LiteLLM started on port 4000"

		# Optional: wait for LiteLLM to accept connections before continuing
		if [ -n "${AMBXST_WAIT_LITELLM:-}" ] && command -v curl >/dev/null 2>&1; then
			for _ in $(seq 1 20); do
				if curl -s --max-time 1 http://127.0.0.1:4000/health >/dev/null 2>&1; then
					break
				fi
				sleep 0.3
			done
		fi
	else
		echo "Warning: litellm_config.yaml not found at $CONFIG_PATH"
	fi
else
	echo "Warning: litellm not found in PATH"
fi

# EasyEffects
if command -v easyeffects >/dev/null; then
	echo "Starting EasyEffects..."
	pkill -x easyeffects 2>/dev/null || true
	nohup env LANG=C.UTF-8 LC_ALL=C.UTF-8 easyeffects --gapplication-service >/dev/null 2>&1 &
else
	echo "Warning: easyeffects not found in PATH"
fi

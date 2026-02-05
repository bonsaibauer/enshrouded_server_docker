#!/usr/bin/env bash

# Server lifecycle helpers.

ENSHROUDED_BINARY="${ENSHROUDED_BINARY:-$INSTALL_PATH/enshrouded_server.exe}"
STOP_TIMEOUT="${STOP_TIMEOUT:-60}"

read_server_pid() {
  if [[ -f "$PID_SERVER_FILE" ]]; then
    cat "$PID_SERVER_FILE" 2>/dev/null || true
  fi
}

find_server_pids() {
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -f '[e]nshrouded_server'
  else
    ps axww | grep '[e]nshrouded_server' | awk '{print $1}'
  fi
}

is_server_running() {
  local pid
  pid="$(read_server_pid)"
  if pid_alive "$pid"; then
    return 0
  fi
  if [[ -n "$(find_server_pids)" ]]; then
    return 0
  fi
  return 1
}

server_uptime() {
  local pid
  pid="$(read_server_pid)"
  if ! pid_alive "$pid"; then
    echo "n/a"
    return
  fi
  if [[ -f "/proc/$pid/stat" ]]; then
    local start_ticks hertz uptime_sec
    start_ticks="$(awk '{print $22}' "/proc/$pid/stat")"
    hertz="$(getconf CLK_TCK)"
    uptime_sec="$(awk -v st="$start_ticks" -v hz="$hertz" '{print int(($1*hz-st)/hz)}' /proc/uptime 2>/dev/null || echo 0)"
    printf "%s" "${uptime_sec}s"
  else
    echo "n/a"
  fi
}

get_query_port() {
  if [[ -n "${ENSHROUDED_QUERY_PORT:-}" ]]; then
    echo "$ENSHROUDED_QUERY_PORT"
    return
  fi
  if command -v jq >/dev/null 2>&1 && [[ -f "$CONFIG_FILE" ]]; then
    jq -r '.queryPort // 15637' "$CONFIG_FILE" 2>/dev/null || echo 15637
    return
  fi
  echo 15637
}

query_player_count() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "unknown"
    return
  fi
  local result
  result="$(python3 - <<PY 2>/dev/null || true
try:
    import a2s
    port = int("${QUERY_PORT}")
    players = a2s.players(("127.0.0.1", port))
    print(len(players))
except Exception:
    print("unknown")
PY
)"
  if [[ -z "$result" ]]; then
    echo "unknown"
  else
    echo "$result"
  fi
}

check_server_empty() {
  local mode flag count
  mode="${1:-update}"
  if [[ "$mode" == "restart" ]]; then
    flag="$RESTART_CHECK_PLAYERS"
  else
    flag="$UPDATE_CHECK_PLAYERS"
  fi

  if [[ "$flag" == "false" ]]; then
    return 0
  fi

  QUERY_PORT="$(get_query_port)"
  count="$(query_player_count)"
  debug "player_count=$count"
  if [[ "$count" == "unknown" ]]; then
    if is_true "$SAFE_MODE"; then
      warn "Player count unknown, skipping $mode in safe mode"
      return 1
    fi
    return 0
  fi

  if [[ "$count" -gt 0 ]]; then
    return 1
  fi
  return 0
}

wait_for_server_download() {
  if [[ -f "$ENSHROUDED_BINARY" ]]; then
    return 0
  fi
  warn "Server binary missing. Downloading..."
  if command -v download_enshrouded >/dev/null 2>&1; then
    download_enshrouded
  fi

  local retry=0
  while [[ ! -f "$ENSHROUDED_BINARY" ]]; do
    retry=$((retry + 1))
    if [[ "$retry" -gt 30 ]]; then
      fatal "Server binary still missing after waiting"
    fi
    sleep 3
  done
}

start_server() {
  if is_server_running; then
    warn "Server already running"
    return 0
  fi

  wait_for_server_download
  cd "$INSTALL_PATH" || fatal "Could not cd $INSTALL_PATH"

  chmod +x "$ENSHROUDED_BINARY" || true

  export WINEDEBUG="${WINEDEBUG:--all}"
  export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH"
  export STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH"
  export WINEPREFIX="$WINEPREFIX"
  export WINETRICKS="${WINETRICKS:-/usr/local/bin/winetricks}"

  info "Starting enshrouded server"
  "$PROTON_CMD" runinprefix "$ENSHROUDED_BINARY" &
  local pid=$!
  echo "$pid" >"$PID_SERVER_FILE"
  info "Server PID: $pid"
}

stop_server() {
  if ! is_server_running; then
    warn "Server is not running"
    return 0
  fi

  local pid kill_signal deadline
  pid="$(read_server_pid)"
  kill_signal="INT"
  deadline=$(( $(date +%s) + STOP_TIMEOUT ))

  info "Stopping enshrouded server"
  while is_server_running; do
    local pids
    pids="$(find_server_pids)"
    if [[ -n "$pids" ]]; then
      kill -"$kill_signal" $pids 2>/dev/null || true
    elif [[ -n "$pid" ]]; then
      kill -"$kill_signal" "$pid" 2>/dev/null || true
    fi

    if [[ "$(date +%s)" -gt "$deadline" ]]; then
      warn "Timeout waiting for shutdown, escalating from SIG$kill_signal"
      deadline=$(( $(date +%s) + STOP_TIMEOUT ))
      case "$kill_signal" in
        INT) kill_signal="TERM" ;;
        TERM) kill_signal="KILL" ;;
        *) break ;;
      esac
    fi
    sleep 3
  done

  cleanup_wine
  clear_pid "$PID_SERVER_FILE"
  info "Server stopped"
}

restart_server() {
  if ! check_server_empty restart; then
    warn "Server not empty, restart skipped"
    return 0
  fi
  restart_pre_hook
  stop_server
  start_server
  start_log_streamer || true
  restart_post_hook
}

cleanup_wine() {
  if [[ -x "$WINESERVER_PATH" ]]; then
    WINEPREFIX="$WINEPREFIX" "$WINESERVER_PATH" -k >/dev/null 2>&1 || true
  fi
}

restart_pre_hook() {
  if [[ -n "${RESTART_PRE_HOOK:-}" ]]; then
    info "Running restart pre hook: $RESTART_PRE_HOOK"
    eval "$RESTART_PRE_HOOK"
  fi
}

restart_post_hook() {
  if [[ -n "${RESTART_POST_HOOK:-}" ]]; then
    info "Running restart post hook: $RESTART_POST_HOOK"
    eval "$RESTART_POST_HOOK"
  fi
}

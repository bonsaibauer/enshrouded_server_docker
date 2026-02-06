#!/usr/bin/env bash

# Server lifecycle helpers.

ENSHROUDED_BINARY="${ENSHROUDED_BINARY:-$INSTALL_PATH/enshrouded_server.exe}"
STOP_TIMEOUT="${STOP_TIMEOUT:-60}"

SUPERVISOR_CONF="${SUPERVISOR_CONF:-${MANAGER_ROOT:-/opt/enshrouded/manager}/supervisord.conf}"
SUPERVISOR_PID_FILE="$RUN_DIR/server-manager-supervisord.pid"
SUPERVISOR_SOCKET="$RUN_DIR/server-manager-supervisor.sock"
SUPERVISOR_LOG_DIR="$RUN_DIR"
SUPERVISOR_LOG_FILE="$RUN_DIR/server-manager-supervisord.log"
SUPERVISOR_LOG_STREAM_PID_FILE="$RUN_DIR/server-manager-supervisord-logstream.pid"

supervisor_available() {
  command -v supervisord >/dev/null 2>&1 && command -v supervisorctl >/dev/null 2>&1
}

supervisor_program_name() {
  case "$1" in
    server) echo "server-manager" ;;
    *) echo "" ;;
  esac
}

supervisor_running() {
  if [[ -S "$SUPERVISOR_SOCKET" ]]; then
    return 0
  fi
  if [[ -f "$SUPERVISOR_PID_FILE" ]]; then
    local pid
    pid="$(cat "$SUPERVISOR_PID_FILE" 2>/dev/null || true)"
    if pid_alive "$pid"; then
      return 0
    fi
  fi
  return 1
}

supervisor_ctl() {
  supervisorctl -c "$SUPERVISOR_CONF" "$@"
}

supervisor_start() {
  if ! supervisor_available; then
    return 1
  fi
  mkdir -p "$RUN_DIR" "$SUPERVISOR_LOG_DIR" 2>/dev/null || true
  if supervisor_running; then
    return 0
  fi
  if [[ ! -f "$SUPERVISOR_CONF" ]]; then
    fatal "Start failed: backend config missing: $SUPERVISOR_CONF"
  fi
  info "Start backend"
  touch "$SUPERVISOR_LOG_FILE" 2>/dev/null || true
  supervisord -c "$SUPERVISOR_CONF" >/dev/null 2>&1 || fatal "Start failed: backend"
  local attempt=0
  while [[ "$attempt" -lt 20 ]]; do
    if supervisor_running; then
      supervisor_log_streamer_start
      ok "Start complete: backend online"
      return 0
    fi
    sleep 0.1
    attempt=$((attempt + 1))
  done
  fatal "Start failed: backend did not start"
}

supervisor_shutdown() {
  if ! supervisor_running; then
    return 0
  fi
  supervisor_ctl shutdown >/dev/null 2>&1 || true
  supervisor_log_streamer_stop
}

supervisor_program_running() {
  local name status
  name="$1"
  status="$(supervisor_ctl status "$name" 2>/dev/null || true)"
  case "$status" in
    *"RUNNING"*|*"STARTING"*|*"STOPPING"*) return 0 ;;
    *) return 1 ;;
  esac
}

supervisor_program_start() {
  local name
  name="$1"
  supervisor_start || return 1
  if supervisor_program_running "$name"; then
    return 0
  fi
  if ! supervisor_ctl start "$name" >/dev/null 2>&1; then
    warn "Start failed: $name"
    return 1
  fi
  return 0
}

supervisor_program_stop() {
  local name
  name="$1"
  if ! supervisor_running; then
    return 0
  fi
  supervisor_ctl stop "$name" >/dev/null 2>&1 || true
}

line_has_timestamp() {
  local line
  line="$1"
  case "$line" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T*Z* ) return 0 ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\ * ) return 0 ;;
    [0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]\ * ) return 0 ;;
    [0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]\ * ) return 0 ;;
    [0-9][0-9]:[0-9][0-9]:[0-9][0-9]* ) return 0 ;;
    * ) return 1 ;;
  esac
}

supervisor_log_streamer_start() {
  if ! is_true "$LOG_TO_STDOUT"; then
    return 0
  fi
  if [[ -f "$SUPERVISOR_LOG_STREAM_PID_FILE" ]]; then
    local pid
    pid="$(cat "$SUPERVISOR_LOG_STREAM_PID_FILE" 2>/dev/null || true)"
    if pid_alive "$pid"; then
      return 0
    fi
  fi
  if [[ ! -f "$SUPERVISOR_LOG_FILE" ]]; then
    return 0
  fi

  tail -n 200 -F "$SUPERVISOR_LOG_FILE" 2>/dev/null | while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      continue
    fi
    log_context_push "supervisor"
    local msg
    msg="supervisord: $line"
    case "$line" in
      *" ERROR "*)
        log_no_ts_force error "$msg"
        ;;
      *" WARN "*|*" WARNING "*)
        log_no_ts_force warn "$msg"
        ;;
      *)
        log_no_ts_force info "$msg"
        ;;
    esac
    log_context_pop
  done &
  echo "$!" >"$SUPERVISOR_LOG_STREAM_PID_FILE"
}

supervisor_log_streamer_stop() {
  if [[ -f "$SUPERVISOR_LOG_STREAM_PID_FILE" ]]; then
    local pid
    pid="$(cat "$SUPERVISOR_LOG_STREAM_PID_FILE" 2>/dev/null || true)"
    if pid_alive "$pid"; then
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$SUPERVISOR_LOG_STREAM_PID_FILE" 2>/dev/null || true
  fi
}

read_server_pid() {
  if [[ -f "$PID_SERVER_FILE" ]]; then
    cat "$PID_SERVER_FILE" 2>/dev/null || true
  fi
}

find_server_pids() {
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -f '[e]nshrouded_server\.exe'
  else
    ps axww | grep '[e]nshrouded_server\.exe' | awk '{print $1}'
  fi
}

pid_matches_server() {
  local pid cmd
  pid="$1"
  if [[ -z "$pid" || ! -r "/proc/$pid/cmdline" ]]; then
    return 1
  fi
  cmd="$(tr '\0' ' ' </proc/"$pid"/cmdline 2>/dev/null || true)"
  case "$cmd" in
    *"enshrouded_server.exe"*)
      return 0
      ;;
  esac
  return 1
}

is_server_running() {
  if supervisor_available && supervisor_running; then
    local name
    name="$(supervisor_program_name server)"
    if [[ -n "$name" ]] && supervisor_program_running "$name"; then
      return 0
    fi
  fi

  local pid
  pid="$(read_server_pid)"
  if pid_alive "$pid" && pid_matches_server "$pid"; then
    return 0
  fi
  if [[ -n "$pid" ]]; then
    clear_pid "$PID_SERVER_FILE"
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
  result="$(QUERY_PORT="$QUERY_PORT" A2S_TIMEOUT="$A2S_TIMEOUT" A2S_RETRIES="$A2S_RETRIES" A2S_RETRY_DELAY="$A2S_RETRY_DELAY" python3 - <<'PY' 2>/dev/null || true
import os
import time
try:
    import a2s
    port = int(os.environ.get("QUERY_PORT", "15637"))
    timeout = float(os.environ.get("A2S_TIMEOUT", "2"))
    retries = int(os.environ.get("A2S_RETRIES", "2"))
    delay = float(os.environ.get("A2S_RETRY_DELAY", "1"))

    for attempt in range(1, retries + 1):
        try:
            try:
                players = a2s.players(("127.0.0.1", port), timeout=timeout)
            except TypeError:
                # Older versions might not support timeout parameter
                players = a2s.players(("127.0.0.1", port))
            print(len(players))
            raise SystemExit(0)
        except Exception:
            if attempt < retries:
                time.sleep(delay)
    print("unknown")
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

health_check() {
  log_context_push "health"
  local port players
  port="$(get_query_port)"
  if ! is_server_running; then
    warn "Health: server not running"
    log_context_pop
    return 1
  fi

  QUERY_PORT="$port"
  players="$(query_player_count)"
  if [[ "$players" == "unknown" ]]; then
    warn "Health: server running, no A2S response on port $port"
    log_context_pop
    return 1
  fi

  info "Health: server running, players=$players, port=$port"
  log_context_pop
  return 0
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
      if [[ "$mode" == "restart" ]]; then
        warn "Stop skipped: player count unknown (safe mode)"
      else
        warn "Update skipped: player count unknown (safe mode)"
      fi
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
  warn "Update: server binary missing, downloading"
  if command -v download_enshrouded >/dev/null 2>&1; then
    download_enshrouded
  fi

  local retry=0
  while [[ ! -f "$ENSHROUDED_BINARY" ]]; do
    retry=$((retry + 1))
    if [[ "$retry" -gt 30 ]]; then
      fatal "Start failed: server binary still missing after waiting"
    fi
    sleep 3
  done
}

server_shutdown() {
  local pid kill_signal deadline
  pid="$1"
  kill_signal="INT"
  deadline=$(( $(date +%s) + STOP_TIMEOUT ))

  info "Stop server"
  while true; do
    local pids
    pids="$(find_server_pids)"
    if [[ -n "$pids" ]]; then
      kill -"$kill_signal" $pids 2>/dev/null || true
    elif [[ -n "$pid" ]]; then
      kill -"$kill_signal" "$pid" 2>/dev/null || true
    fi

    if [[ -z "$(find_server_pids)" ]] && ! pid_alive "$pid"; then
      break
    fi

    if [[ "$(date +%s)" -gt "$deadline" ]]; then
      warn "Stop timeout: escalating from SIG$kill_signal"
      deadline=$(( $(date +%s) + STOP_TIMEOUT ))
      case "$kill_signal" in
        INT) kill_signal="TERM" ;;
        TERM) kill_signal="KILL" ;;
        *) break ;;
      esac
    fi
    sleep 3
  done
}

run_server_foreground() {
  log_context_push "server"
  wait_for_server_download
  cd "$INSTALL_PATH" || fatal "Could not cd $INSTALL_PATH"

  chmod +x "$ENSHROUDED_BINARY" || true

  export WINEDEBUG="${WINEDEBUG:--all}"
  export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH"
  export STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH"
  export WINEPREFIX="$WINEPREFIX"
  export WINETRICKS="${WINETRICKS:-/usr/local/bin/winetricks}"

  info "Start server"
  "$PROTON_CMD" runinprefix "$ENSHROUDED_BINARY" &
  local pid=$!
  echo "$pid" >"$PID_SERVER_FILE"

  trap 'server_shutdown "$pid"' SIGINT SIGTERM

  ok "Start complete: server online"

  local rc=0
  if ! wait "$pid"; then
    rc=$?
  fi

  cleanup_wine
  clear_pid "$PID_SERVER_FILE"
  ok "Stop complete"
  log_context_pop
  return $rc
}

start_server() {
  log_context_push "server"
  if is_server_running; then
    warn "Start skipped: server already running"
    log_context_pop
    return 0
  fi

  if supervisor_available; then
    local name
    name="$(supervisor_program_name server)"
    if [[ -n "$name" ]]; then
      supervisor_program_start "$name"
      ok "Start complete: server online"
      log_context_pop
      return 0
    fi
  fi

  wait_for_server_download
  cd "$INSTALL_PATH" || fatal "Could not cd $INSTALL_PATH"

  chmod +x "$ENSHROUDED_BINARY" || true

  export WINEDEBUG="${WINEDEBUG:--all}"
  export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH"
  export STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH"
  export WINEPREFIX="$WINEPREFIX"
  export WINETRICKS="${WINETRICKS:-/usr/local/bin/winetricks}"

  info "Start server"
  "$PROTON_CMD" runinprefix "$ENSHROUDED_BINARY" &
  local pid=$!
  echo "$pid" >"$PID_SERVER_FILE"
  info "Server PID: $pid"
  ok "Start complete: server online"
  log_context_pop
}

stop_server() {
  log_context_push "server"
  if ! is_server_running; then
    warn "Stop skipped: server not running"
    log_context_pop
    return 0
  fi

  if supervisor_available && supervisor_running; then
    local name deadline
    name="$(supervisor_program_name server)"
    if [[ -n "$name" ]]; then
      info "Stop server"
      supervisor_program_stop "$name"
      deadline=$(( $(date +%s) + STOP_TIMEOUT ))
      while supervisor_program_running "$name"; do
        if [[ "$(date +%s)" -gt "$deadline" ]]; then
          warn "Stop timeout: waiting for shutdown"
          break
        fi
        sleep 1
      done
      if ! is_server_running; then
        ok "Stop complete"
        log_context_pop
        return 0
      fi
      warn "Stop incomplete: backend, falling back to direct shutdown"
    fi
  fi

  local pid kill_signal deadline
  pid="$(read_server_pid)"
  kill_signal="INT"
  deadline=$(( $(date +%s) + STOP_TIMEOUT ))

  info "Stop server"
  while is_server_running; do
    local pids
    pids="$(find_server_pids)"
    if [[ -n "$pids" ]]; then
      kill -"$kill_signal" $pids 2>/dev/null || true
    elif [[ -n "$pid" ]]; then
      kill -"$kill_signal" "$pid" 2>/dev/null || true
    fi

    if [[ "$(date +%s)" -gt "$deadline" ]]; then
      warn "Stop timeout: escalating from SIG$kill_signal"
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
  ok "Stop complete"
  log_context_pop
}

restart_server() {
  log_context_push "restart"
  if ! check_server_empty restart; then
    warn "Stop skipped: server not empty, restart skipped"
    log_context_pop
    return 0
  fi
  restart_pre_hook
  stop_server
  start_server
  start_log_streamer || true
  restart_post_hook
  log_context_pop
}

cleanup_wine() {
  if [[ -x "$WINESERVER_PATH" ]]; then
    WINEPREFIX="$WINEPREFIX" "$WINESERVER_PATH" -k >/dev/null 2>&1 || true
  fi
}

restart_pre_hook() {
  if [[ -n "${RESTART_PRE_HOOK:-}" ]]; then
    info "Start restart pre hook: $RESTART_PRE_HOOK"
    eval "$RESTART_PRE_HOOK"
  fi
}

restart_post_hook() {
  if [[ -n "${RESTART_POST_HOOK:-}" ]]; then
    info "Start restart post hook: $RESTART_POST_HOOK"
    eval "$RESTART_POST_HOOK"
  fi
}

LOG_STREAM_PID_FILE="$RUN_DIR/enshrouded-logstream.pid"
LOG_STREAM_TAIL_PID_FILE="$RUN_DIR/enshrouded-logtail.pid"

get_log_dir() {
  if [[ -n "${ENSHROUDED_LOG_DIR:-}" ]]; then
    abs_path "$ENSHROUDED_LOG_DIR"
    return
  fi
  if command -v jq >/dev/null 2>&1 && [[ -f "$CONFIG_FILE" ]]; then
    local ld
    ld="$(jq -r '.logDirectory // "./logs"' "$CONFIG_FILE" 2>/dev/null || echo "./logs")"
    abs_path "$ld"
    return
  fi
  abs_path "./logs"
}

latest_log_file() {
  local log_dir
  log_dir="$(get_log_dir)"
  if [[ ! -d "$log_dir" ]]; then
    echo ""
    return
  fi
  find "$log_dir" -maxdepth 1 -type f -name "$LOG_FILE_PATTERN" -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr | head -n1 | cut -d' ' -f2-
}

log_streamer_loop() {
  local current_file tail_pid latest
  current_file=""
  tail_pid=""

  while true; do
    latest="$(latest_log_file)"
    if [[ -n "$latest" && "$latest" != "$current_file" ]]; then
      if pid_alive "$tail_pid"; then
        kill "$tail_pid" 2>/dev/null || true
      fi
      info "Start log stream: $latest"
      tail -n "$LOG_TAIL_LINES" -F "$latest" 2>/dev/null | while IFS= read -r line; do
        if [[ -z "$line" ]]; then
          continue
        fi
        log_context_push "server-log"
        log_no_ts_force info "$line"
        log_context_pop
      done &
      tail_pid=$!
      echo "$tail_pid" >"$LOG_STREAM_TAIL_PID_FILE"
      current_file="$latest"
    fi
    sleep "$LOG_POLL_INTERVAL"
  done
}

start_log_streamer() {
  if ! is_true "$LOG_TO_STDOUT"; then
    return 0
  fi
  if [[ -f "$LOG_STREAM_PID_FILE" ]]; then
    local pid
    pid="$(cat "$LOG_STREAM_PID_FILE" 2>/dev/null || true)"
    if pid_alive "$pid"; then
      return 0
    fi
  fi

  log_context_push "logs"
  log_streamer_loop &
  local pid=$!
  log_context_pop
  echo "$pid" >"$LOG_STREAM_PID_FILE"
}

stop_log_streamer() {
  if [[ -f "$LOG_STREAM_PID_FILE" ]]; then
    local pid
    pid="$(cat "$LOG_STREAM_PID_FILE" 2>/dev/null || true)"
    if pid_alive "$pid"; then
      kill "$pid" 2>/dev/null || true
    fi
  fi
  if [[ -f "$LOG_STREAM_TAIL_PID_FILE" ]]; then
    local tpid
    tpid="$(cat "$LOG_STREAM_TAIL_PID_FILE" 2>/dev/null || true)"
    if pid_alive "$tpid"; then
      kill "$tpid" 2>/dev/null || true
    fi
  fi
  rm -f "$LOG_STREAM_PID_FILE" "$LOG_STREAM_TAIL_PID_FILE" 2>/dev/null || true
}

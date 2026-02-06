#!/usr/bin/env bash
set -Eeuo pipefail

MANAGER_ENV_SNAPSHOT="$(env | cut -d= -f1 | tr '\n' ' ')"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANAGER_BIN="${MANAGER_BIN:-$ROOT_DIR/manager.sh}"
MANAGER_ROOT="$ROOT_DIR"
export MANAGER_BIN
export MANAGER_ROOT

. "$ROOT_DIR/lib/common.sh"
. "$ROOT_DIR/lib/config.sh"
. "$ROOT_DIR/lib/server.sh"
. "$ROOT_DIR/lib/update.sh"
. "$ROOT_DIR/lib/backup.sh"

on_error() {
  error "Unexpected error at line $1"
}
trap 'on_error $LINENO' ERR

print_help() {
  ui_banner
  cat <<EOF
Usage: $MANAGER_BIN <command>

Commands:
  run             Start Server Manager (PID1 mode, handles signals)
  setup           Setup Server Manager (config, directories, a2s)
  start           Start server
  stop            Stop server (or Server Manager if running)
  restart         Restart server (safe check optional)
  update          Update server (check + apply)
  backup          Backup now
  status          Show status (Server Manager + Server)
  logs            Tail latest log file
  help            Show this help

Notes:
  - Use UPDATE_CRON/BACKUP_CRON/RESTART_CRON for schedules.
  - Use AUTO_UPDATE=true to enable periodic update checks.
EOF
}

startup_summary() {
  local name ip qport slots save_dir log_dir preset
  if command -v jq >/dev/null 2>&1 && [[ -f "$CONFIG_FILE" ]]; then
    name="$(jq -r '.name // "n/a"' "$CONFIG_FILE" 2>/dev/null || echo "n/a")"
    ip="$(jq -r '.ip // "n/a"' "$CONFIG_FILE" 2>/dev/null || echo "n/a")"
    qport="$(jq -r '.queryPort // "n/a"' "$CONFIG_FILE" 2>/dev/null || echo "n/a")"
    slots="$(jq -r '.slotCount // "n/a"' "$CONFIG_FILE" 2>/dev/null || echo "n/a")"
    save_dir="$(jq -r '.saveDirectory // "./savegame"' "$CONFIG_FILE" 2>/dev/null || echo "./savegame")"
    log_dir="$(jq -r '.logDirectory // "./logs"' "$CONFIG_FILE" 2>/dev/null || echo "./logs")"
    preset="$(jq -r '.gameSettingsPreset // "n/a"' "$CONFIG_FILE" 2>/dev/null || echo "n/a")"
  else
    name="n/a"
    ip="n/a"
    qport="n/a"
    slots="n/a"
    save_dir="./savegame"
    log_dir="./logs"
    preset="n/a"
  fi

  ui_hr
  ui_kv "Server Name" "$name"
  ui_kv "Bind IP" "$ip"
  ui_kv "Query Port" "$qport"
  ui_kv "Slots" "$slots"
  ui_kv "Save Dir" "$(abs_path "$save_dir")"
  ui_kv "Log Dir" "$(abs_path "$log_dir")"
  ui_kv "Preset" "$preset"
  ui_kv "Auto Update" "$AUTO_UPDATE"
  ui_kv "Update Interval" "${AUTO_UPDATE_INTERVAL}s"
  ui_kv "Auto Restart" "$AUTO_RESTART"
  ui_kv "Health Check" "${HEALTH_CHECK_INTERVAL}s"
  ui_kv "Safe Mode" "$SAFE_MODE"
  ui_kv "Log To Stdout" "$LOG_TO_STDOUT"
  ui_hr
}

ensure_root_and_map_user() {
  if [[ "$(id -u)" -ne 0 ]]; then
    fatal "Server Manager must run as root to apply PUID/PGID mapping"
  fi

  if [[ -z "${PUID:-}" || -z "${PGID:-}" || ! "$PUID" =~ ^[0-9]+$ || ! "$PGID" =~ ^[0-9]+$ || "$PUID" -eq 0 || "$PGID" -eq 0 ]]; then
    local detect_path detected_uid detected_gid
    for detect_path in "$INSTALL_PATH" "$(dirname "$CONFIG_FILE")" "$HOME"; do
      if [[ -e "$detect_path" ]]; then
        detected_uid="$(stat -c '%u' "$detect_path" 2>/dev/null || true)"
        detected_gid="$(stat -c '%g' "$detect_path" 2>/dev/null || true)"
        if [[ -n "$detected_uid" && -n "$detected_gid" && "$detected_uid" =~ ^[0-9]+$ && "$detected_gid" =~ ^[0-9]+$ && "$detected_uid" -ne 0 && "$detected_gid" -ne 0 ]]; then
          PUID="$detected_uid"
          PGID="$detected_gid"
          export PUID PGID
          info "Detected PUID/PGID from $detect_path: $PUID/$PGID"
          break
        fi
      fi
    done
  fi

  if [[ -z "${PUID:-}" || -z "${PGID:-}" ]]; then
    fatal "PUID and PGID are required"
  fi
  if ! [[ "$PUID" =~ ^[0-9]+$ ]] || ! [[ "$PGID" =~ ^[0-9]+$ ]]; then
    fatal "PUID/PGID must be numeric"
  fi
  if [[ "$PUID" -eq 0 || "$PGID" -eq 0 ]]; then
    fatal "PUID/PGID must not be 0"
  fi
  require_cmd runuser

  mkdir -p "$INSTALL_PATH" "$RUN_DIR"
  groupmod -o -g "$PGID" steam
  usermod -o -u "$PUID" -g "$PGID" steam
  chown -R "$PUID:$PGID" "$HOME" 2>/dev/null || true
  chown -R "$PUID:$PGID" "$INSTALL_PATH" 2>/dev/null || true
  chown -R "$PUID:$PGID" "$RUN_DIR" 2>/dev/null || true
}

setup_environment() {
  update_or_create_manager_config
  init_colors
  set_umask
  verify_variables
  ensure_base_dirs
  ensure_steam_paths
  if [[ ! -x "$PROTON_CMD" ]]; then
    fatal "Proton not found or not executable at $PROTON_CMD"
  fi
  if [[ ! -x "$STEAMCMD_PATH" ]]; then
    warn "steamcmd not found at $STEAMCMD_PATH (updates may fail)"
  fi
  create_folders
  update_or_create_config
  init_crontab
  bootstrap_hook
  prepare_a2s_library
}

RSYSLOG_CONF="/etc/rsyslog.d/server_manager_stdout.conf"
RSYSLOG_PID_FILE="$RUN_DIR/server-manager-rsyslogd.pid"
RSYSLOG_STATE_DIR="/var/spool/rsyslog"

syslog_running() {
  if [[ -f "$RSYSLOG_PID_FILE" ]]; then
    local pid
    pid="$(cat "$RSYSLOG_PID_FILE" 2>/dev/null || true)"
    if pid_alive "$pid"; then
      return 0
    fi
    rm -f "$RSYSLOG_PID_FILE" 2>/dev/null || true
  fi
  if pgrep -x rsyslogd >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

setup_syslog() {
  if ! command -v rsyslogd >/dev/null 2>&1; then
    warn "Syslog unavailable, skipping"
    return 1
  fi
  mkdir -p "$(dirname "$RSYSLOG_CONF")" 2>/dev/null || true
  mkdir -p "$RSYSLOG_STATE_DIR" 2>/dev/null || true
  cat >"$RSYSLOG_CONF" <<'EOF'
$FileOwner root
$FileGroup root
$PrivDropToUser root
$PrivDropToGroup root
$WorkDirectory /var/spool/rsyslog
module(load="imuxsock")
$IMUXSockRateLimitInterval 0
$template server_manager,"%timegenerated:::date-rfc3339% [SYSLOG] [server_manager] %syslogtag%%msg:::sp-if-no-1st-sp%%msg:::drop-last-lf%\n"
$ActionFileDefaultTemplate server_manager

:msg, contains, "[session] Pending packets list is full" stop
*.* /proc/self/fd/1
EOF
}

start_syslog_daemon() {
  if ! is_true "$LOG_TO_STDOUT"; then
    return 0
  fi
  if syslog_running; then
    return 0
  fi
  setup_syslog || return 1
  mkdir -p "$RUN_DIR" 2>/dev/null || true
  info "Start syslog"
  rsyslogd -n -f "$RSYSLOG_CONF" &
  echo "$!" >"$RSYSLOG_PID_FILE"
}

stop_syslog_daemon() {
  if [[ -f "$RSYSLOG_PID_FILE" ]]; then
    local pid
    pid="$(cat "$RSYSLOG_PID_FILE" 2>/dev/null || true)"
    if pid_alive "$pid"; then
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$RSYSLOG_PID_FILE" 2>/dev/null || true
  fi
}

start_cron_daemon() {
  if ! is_true "$ENABLE_CRON"; then
    return 0
  fi
  if [[ -n "${UPDATE_CRON:-}" || -n "${BACKUP_CRON:-}" || -n "${RESTART_CRON:-}" ]]; then
    if command -v cron >/dev/null 2>&1; then
      if pgrep -x cron >/dev/null 2>&1; then
        return 0
      fi
      info "Start cron daemon"
      cron
    elif command -v crond >/dev/null 2>&1; then
      if pgrep -x crond >/dev/null 2>&1; then
        return 0
      fi
      info "Start crond daemon"
      crond
    else
      warn "Cron not available, skipping scheduled jobs"
    fi
  fi
}

init_crontab() {
  if ! is_true "$ENABLE_CRON"; then
    return 0
  fi
  if [[ -z "${UPDATE_CRON:-}" && -z "${BACKUP_CRON:-}" && -z "${RESTART_CRON:-}" ]]; then
    return 0
  fi

  require_cmd crontab

  local cron_file
  cron_file="$(mktemp)"
  {
    echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    if [[ -n "${UPDATE_CRON:-}" ]]; then
      echo "$UPDATE_CRON $MANAGER_BIN update >>/proc/1/fd/1 2>>/proc/1/fd/2"
    fi
    if [[ -n "${BACKUP_CRON:-}" ]]; then
      echo "$BACKUP_CRON $MANAGER_BIN backup >>/proc/1/fd/1 2>>/proc/1/fd/2"
    fi
    if [[ -n "${RESTART_CRON:-}" ]]; then
      echo "$RESTART_CRON $MANAGER_BIN restart >>/proc/1/fd/1 2>>/proc/1/fd/2"
    fi
  } >"$cron_file"

  crontab "$cron_file"
  rm -f "$cron_file"
  info "Crontab updated"
}

handle_requests() {
  if [[ -f "$RUN_DIR/update" ]]; then
    rm -f "$RUN_DIR/update"
    info "Update request received"
    update_now || true
  fi

  if [[ -f "$RUN_DIR/backup" ]]; then
    rm -f "$RUN_DIR/backup"
    info "Backup request received"
    backup_now || true
  fi

  if [[ -f "$RUN_DIR/restart" ]]; then
    rm -f "$RUN_DIR/restart"
    info "Start restart request"
    restart_server || true
  fi
}

manager_cleanup() {
  stop_log_streamer
  stop_syslog_daemon || true
  supervisor_shutdown
  clear_pid "$PID_MANAGER_FILE"
  rm -f "$RUN_DIR/update" "$RUN_DIR/backup" "$RUN_DIR/restart" 2>/dev/null || true
}

handle_shutdown() {
  warn "Stop signal received"
  stop_server
  exit 0
}

status_summary() {
  local server_state pid version players
  if is_server_running; then
    server_state="running"
  else
    server_state="stopped"
  fi
  pid="$(read_server_pid)"
  version="$(cat "$VERSION_FILE_PATH" 2>/dev/null || echo "unknown")"
  QUERY_PORT="$(get_query_port)"
  players="$(query_player_count)"

  ui_hr
  ui_kv "Server Manager" "$(manager_running && echo "running" || echo "stopped")"
  ui_kv "Server" "$server_state"
  ui_kv "Server PID" "${pid:-n/a}"
  ui_kv "Uptime" "$(server_uptime)"
  ui_kv "Players" "$players"
  ui_kv "Version" "$version"
  ui_kv "Install Path" "$INSTALL_PATH"
  ui_hr
}

tail_logs() {
  local log_dir latest
  log_dir="$(abs_path "${ENSHROUDED_LOG_DIR:-./logs}")"
  if [[ ! -d "$log_dir" ]]; then
    warn "Log directory missing: $log_dir"
    return 1
  fi
  latest="$(ls -t "$log_dir" 2>/dev/null | head -n1 || true)"
  if [[ -z "$latest" ]]; then
    warn "No log files found in $log_dir"
    return 1
  fi
  info "Start log tail: $log_dir/$latest"
  tail -n "${LOG_TAIL_LINES:-200}" -F "$log_dir/$latest"
}

manager_loop() {
  local next_update_check now
  local restart_attempts
  local next_health_check
  next_update_check=$(( $(date +%s) + AUTO_UPDATE_INTERVAL ))
  next_health_check=$(( $(date +%s) + HEALTH_CHECK_INTERVAL ))
  restart_attempts=0

  while true; do
    handle_requests

    now="$(date +%s)"
    if is_true "$AUTO_UPDATE" && [[ "$now" -ge "$next_update_check" ]]; then
      info "Update check (auto)"
      update_now || true
      next_update_check=$(( now + AUTO_UPDATE_INTERVAL ))
    fi

    if [[ "$HEALTH_CHECK_INTERVAL" -gt 0 ]] && [[ "$now" -ge "$next_health_check" ]]; then
      health_check || true
      next_health_check=$(( now + HEALTH_CHECK_INTERVAL ))
    fi

    if ! is_server_running; then
      warn "Stop detected: server process exited"
      if is_true "$AUTO_RESTART"; then
        restart_attempts=$((restart_attempts + 1))
        if [[ "$AUTO_RESTART_MAX_ATTEMPTS" -gt 0 && "$restart_attempts" -gt "$AUTO_RESTART_MAX_ATTEMPTS" ]]; then
          warn "Stop Server Manager loop: auto restart limit reached"
          return 1
        fi
        warn "Start restart in ${AUTO_RESTART_DELAY}s (attempt ${restart_attempts})"
        sleep "$AUTO_RESTART_DELAY"
        start_server || true
        start_log_streamer || true
        continue
      fi
      return 0
    else
      restart_attempts=0
    fi

    sleep 2
  done
}

manager_run() {
  if [[ "${1:-}" != "--as-steam" ]]; then
    update_or_create_manager_config
    init_colors
    start_syslog_daemon || true
    ensure_root_and_map_user
    preflight_permissions
    start_cron_daemon
    local runtime_home
    runtime_home="${HOME:-/home/steam}"
    exec runuser -u steam -p -- env \
      HOME="$runtime_home" \
      INSTALL_PATH="$INSTALL_PATH" \
      CONFIG_FILE="$CONFIG_FILE" \
      STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH" \
      STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH" \
      WINEPREFIX="$WINEPREFIX" \
      "$MANAGER_BIN" run --as-steam "$@"
  fi

  shift || true

  ui_banner
  ui_kv "Server Manager Version" "$MANAGER_VERSION"
  ui_kv "Install Path" "$INSTALL_PATH"
  ui_kv "Config" "$CONFIG_FILE"
  ui_hr

  ensure_run_dirs
  write_pid "$PID_MANAGER_FILE"
  trap manager_cleanup EXIT
  trap handle_shutdown SIGINT SIGTERM

  setup_environment

  startup_summary

  if is_true "$AUTO_UPDATE_ON_BOOT"; then
    update_now || true
  fi

  if ! is_server_running; then
    start_server
  fi

  start_log_streamer

  if is_true "$HEALTH_CHECK_ON_START"; then
    health_check || true
  fi

  info "Start complete: Server Manager online"

  manager_loop
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  _server)
    run_server_foreground
    ;;
  run)
    manager_run "$@"
    ;;
  setup)
    setup_environment
    ;;
  start)
    if manager_running; then
      warn "Start skipped: Server Manager is running"
    else
      start_server
    fi
    ;;
  stop)
    if manager_running; then
      info "Stop Server Manager"
      kill -TERM "$(cat "$PID_MANAGER_FILE")" 2>/dev/null || true
    else
      stop_server
    fi
    ;;
  restart)
    if manager_running; then
      request_action restart
    else
      restart_server
    fi
    ;;
  update)
    if manager_running; then
      request_action update
    else
      update_now
    fi
    ;;
  backup)
    if manager_running; then
      request_action backup
    else
      backup_now
    fi
    ;;
  status)
    ui_banner
    status_summary
    ;;
  logs)
    tail_logs
    ;;
  help|--help|-h)
    print_help
    ;;
  *)
    error "Unknown command: $cmd"
    print_help
    exit 1
    ;;
esac

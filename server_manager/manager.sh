#!/usr/bin/env bash
set -Eeuo pipefail

MANAGER_ENV_SNAPSHOT="$(env | cut -d= -f1 | tr '\n' ' ')"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANAGER_BIN="$ROOT_DIR/manager.sh"
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

reap_children() {
  while true; do
    wait -n 2>/dev/null || break
  done
}
trap 'reap_children' CHLD

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
  ok "Setup complete"
}

RSYSLOG_CONF="/etc/rsyslog.d/server_manager_stdout.conf"
RSYSLOG_STATE_DIR="/var/spool/rsyslog"
SYSLOG_LOG_FILE="$RUN_DIR/server-manager-syslog.log"

syslog_running() {
  if supervisor_available && supervisor_running; then
    local name
    name="$(supervisor_program_name syslog)"
    if [[ -n "$name" ]] && supervisor_program_running "$name"; then
      return 0
    fi
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
  mkdir -p "$RUN_DIR" 2>/dev/null || true
  cat >"$RSYSLOG_CONF" <<'EOF'
$FileOwner root
$FileGroup root
$PrivDropToUser root
$PrivDropToGroup root
$WorkDirectory /var/spool/rsyslog
module(load="imuxsock")
$IMUXSockRateLimitInterval 0
$template server_manager,"%syslogseverity-text:::uppercase%|%timegenerated:::date-rfc3339%|%syslogtag%%msg:::sp-if-no-1st-sp%%msg:::drop-last-lf%\n"
$ActionFileDefaultTemplate server_manager

:msg, contains, "[session] Pending packets list is full" stop
*.* /var/run/enshrouded/server-manager-syslog.log
EOF
}

syslog_log_streamer_start() {
  if ! is_true "$LOG_TO_STDOUT"; then
    return 0
  fi
  if ! supervisor_available || ! supervisor_running; then
    return 0
  fi
  local name
  name="$(supervisor_program_name sysloglog)"
  if [[ -n "$name" ]] && ! supervisor_program_running "$name"; then
    supervisor_ctl start "$name" >/dev/null 2>&1 || warn "Start failed: $name"
  fi
}

syslog_log_streamer_stop() {
  if ! supervisor_available || ! supervisor_running; then
    return 0
  fi
  local name
  name="$(supervisor_program_name sysloglog)"
  if [[ -n "$name" ]]; then
    supervisor_ctl stop "$name" >/dev/null 2>&1 || true
  fi
}

run_syslog_log_streamer_foreground() {
  if ! is_true "$LOG_TO_STDOUT"; then
    return 0
  fi
  touch "$SYSLOG_LOG_FILE" 2>/dev/null || true
  tail -n 200 -F "$SYSLOG_LOG_FILE" 2>/dev/null | while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      continue
    fi
    local sev rest msg level
    if [[ "$line" == *"|"* ]]; then
      sev="${line%%|*}"
      rest="${line#*|}"
      if [[ "$rest" == *"|"* ]]; then
        msg="${rest#*|}"
      else
        msg="$rest"
      fi
    else
      sev="INFO"
      msg="$line"
    fi
    case "$sev" in
      EMERG|ALERT|CRIT|CRITICAL|ERR|ERROR) level="error" ;;
      WARN|WARNING) level="warn" ;;
      NOTICE|INFO) level="info" ;;
      DEBUG) level="debug" ;;
      *) level="info" ;;
    esac
    log_context_push "syslog"
    log_ts_force "$level" "$msg"
    log_context_pop
  done
}

start_syslog_daemon() {
  if ! is_true "$LOG_TO_STDOUT"; then
    return 0
  fi
  if syslog_running; then
    syslog_log_streamer_start
    return 0
  fi
  setup_syslog || return 1
  touch "$SYSLOG_LOG_FILE" 2>/dev/null || true
  local name
  name="$(supervisor_program_name syslog)"
  if [[ -n "$name" ]] && supervisor_start_job "$name"; then
    syslog_log_streamer_start
    ok "Syslog online"
    return 0
  fi
  warn "Syslog start failed: supervisor unavailable"
  return 1
}

stop_syslog_daemon() {
  syslog_log_streamer_stop || true
  if supervisor_available && supervisor_running; then
    local name
    name="$(supervisor_program_name syslog)"
    if [[ -n "$name" ]]; then
      supervisor_program_stop "$name"
    fi
  fi
}

run_syslog_foreground() {
  setup_syslog || exit 1
  touch "$SYSLOG_LOG_FILE" 2>/dev/null || true
  exec rsyslogd -n -f "$RSYSLOG_CONF"
}

run_cron_foreground() {
  if ! is_true "$ENABLE_CRON"; then
    return 0
  fi
  if [[ -z "${UPDATE_CRON:-}" && -z "${BACKUP_CRON:-}" && -z "${RESTART_CRON:-}" ]]; then
    return 0
  fi
  if command -v cron >/dev/null 2>&1; then
    exec cron -f
  elif command -v crond >/dev/null 2>&1; then
    exec crond -f
  fi
  fatal "Cron not available"
}

start_cron_daemon() {
  if ! is_true "$ENABLE_CRON"; then
    return 0
  fi
  if [[ -z "${UPDATE_CRON:-}" && -z "${BACKUP_CRON:-}" && -z "${RESTART_CRON:-}" ]]; then
    return 0
  fi
  if ! command -v cron >/dev/null 2>&1 && ! command -v crond >/dev/null 2>&1; then
    warn "Cron not available, skipping scheduled jobs"
    return 0
  fi
  if ! supervisor_available || ! supervisor_running; then
    return 0
  fi
  local name
  name="$(supervisor_program_name cron)"
  if [[ -n "$name" ]] && ! supervisor_program_running "$name"; then
    supervisor_ctl start "$name" >/dev/null 2>&1 || warn "Start failed: $name"
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
      echo "$UPDATE_CRON supervisorctl -c $SUPERVISOR_CONF start server-manager-update >>/proc/1/fd/1 2>>/proc/1/fd/2"
    fi
    if [[ -n "${BACKUP_CRON:-}" ]]; then
      echo "$BACKUP_CRON supervisorctl -c $SUPERVISOR_CONF start server-manager-backup >>/proc/1/fd/1 2>>/proc/1/fd/2"
    fi
    if [[ -n "${RESTART_CRON:-}" ]]; then
      echo "$RESTART_CRON supervisorctl -c $SUPERVISOR_CONF start server-manager-restart >>/proc/1/fd/1 2>>/proc/1/fd/2"
    fi
  } >"$cron_file"

  crontab "$cron_file"
  rm -f "$cron_file"
  ok "Crontab updated"
}

prepare_action_context() {
  update_or_create_manager_config
  init_colors
  set_umask
  ensure_run_dirs
}

action_pid_alive() {
  local pidfile pid
  pidfile="$1"
  if [[ -f "$pidfile" ]]; then
    pid="$(cat "$pidfile" 2>/dev/null || true)"
    if pid_alive "$pid"; then
      return 0
    fi
    rm -f "$pidfile" 2>/dev/null || true
  fi
  return 1
}

action_program_running() {
  local action name
  action="$1"
  if ! supervisor_available || ! supervisor_running; then
    return 1
  fi
  name="$(supervisor_program_name "$action")"
  if [[ -z "$name" ]]; then
    return 1
  fi
  supervisor_program_running "$name"
}

supervisor_start_job() {
  local name
  name="$1"
  if ! supervisor_available; then
    return 1
  fi
  if ! supervisor_running; then
    supervisor_start || return 1
  fi
  if supervisor_program_running "$name"; then
    return 0
  fi
  if ! supervisor_ctl start "$name" >/dev/null 2>&1; then
    warn "Start failed: $name"
    return 1
  fi
  local attempt state
  attempt=0
  while [[ "$attempt" -lt 20 ]]; do
    state="$(supervisor_program_state "$name")"
    if [[ "$state" == "RUNNING" ]]; then
      return 0
    fi
    case "$state" in
      STARTING|UNKNOWN)
        ;;
      EXITED|FATAL|BACKOFF|STOPPED)
        warn "Start failed: $name state=$state"
        return 1
        ;;
    esac
    sleep 0.1
    attempt=$((attempt + 1))
  done
  warn "Start failed: $name did not reach RUNNING"
  return 1
}

action_in_progress() {
  action_pid_alive "$PID_UPDATE_FILE" \
    || action_pid_alive "$PID_RESTART_FILE" \
    || action_program_running update \
    || action_program_running restart
}

start_update_async() {
  if action_pid_alive "$PID_RESTART_FILE" || action_program_running restart; then
    warn "Restart in progress, update skipped"
    return 0
  fi
  if action_pid_alive "$PID_UPDATE_FILE" || action_program_running update; then
    warn "Update already in progress"
    return 0
  fi
  local name
  name="$(supervisor_program_name update)"
  if [[ -n "$name" ]] && supervisor_start_job "$name"; then
    info "Update started (supervisor)"
    return 0
  fi
  warn "Update start failed: supervisor unavailable"
  return 1
}

start_backup_async() {
  if action_pid_alive "$PID_BACKUP_FILE" || action_program_running backup; then
    warn "Backup already in progress"
    return 0
  fi
  local name
  name="$(supervisor_program_name backup)"
  if [[ -n "$name" ]] && supervisor_start_job "$name"; then
    info "Backup started (supervisor)"
    return 0
  fi
  warn "Backup start failed: supervisor unavailable"
  return 1
}

start_restart_async() {
  if action_pid_alive "$PID_UPDATE_FILE" || action_program_running update; then
    warn "Update in progress, restart skipped"
    return 0
  fi
  if action_pid_alive "$PID_RESTART_FILE" || action_program_running restart; then
    warn "Restart already in progress"
    return 0
  fi
  local name
  name="$(supervisor_program_name restart)"
  if [[ -n "$name" ]] && supervisor_start_job "$name"; then
    info "Restart started (supervisor)"
    return 0
  fi
  warn "Restart start failed: supervisor unavailable"
  return 1
}

handle_requests() {
  if [[ -f "$RUN_DIR/update" ]]; then
    rm -f "$RUN_DIR/update"
    info "Update request received"
    start_update_async || true
  fi

  if [[ -f "$RUN_DIR/backup" ]]; then
    rm -f "$RUN_DIR/backup"
    info "Backup request received"
    start_backup_async || true
  fi

  if [[ -f "$RUN_DIR/restart" ]]; then
    rm -f "$RUN_DIR/restart"
    info "Start restart request"
    start_restart_async || true
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
  local supervisor_state update_state backup_state restart_state syslog_state
  local cron_state logstream_state supervisor_log_state syslog_log_state
  if is_server_running; then
    server_state="running"
  else
    server_state="stopped"
  fi
  pid="$(read_server_pid)"
  version="$(cat "$VERSION_FILE_PATH" 2>/dev/null || echo "unknown")"
  QUERY_PORT="$(get_query_port)"
  players="$(query_player_count)"

  if ! supervisor_available; then
    supervisor_state="missing"
  elif supervisor_running; then
    supervisor_state="running"
    update_state="$(supervisor_program_state "$(supervisor_program_name update)")"
    backup_state="$(supervisor_program_state "$(supervisor_program_name backup)")"
    restart_state="$(supervisor_program_state "$(supervisor_program_name restart)")"
    syslog_state="$(supervisor_program_state "$(supervisor_program_name syslog)")"
    cron_state="$(supervisor_program_state "$(supervisor_program_name cron)")"
    logstream_state="$(supervisor_program_state "$(supervisor_program_name logstream)")"
    supervisor_log_state="$(supervisor_program_state "$(supervisor_program_name supervisorlog)")"
    syslog_log_state="$(supervisor_program_state "$(supervisor_program_name sysloglog)")"
  else
    supervisor_state="stopped"
    update_state="n/a"
    backup_state="n/a"
    restart_state="n/a"
    syslog_state="n/a"
    cron_state="n/a"
    logstream_state="n/a"
    supervisor_log_state="n/a"
    syslog_log_state="n/a"
  fi

  ui_hr
  ui_kv "Server Manager" "$(manager_running && echo "running" || echo "stopped")"
  ui_kv "Supervisor" "$supervisor_state"
  ui_kv "Server" "$server_state"
  ui_kv "Update Job" "${update_state:-n/a}"
  ui_kv "Backup Job" "${backup_state:-n/a}"
  ui_kv "Restart Job" "${restart_state:-n/a}"
  ui_kv "Syslog Job" "${syslog_state:-n/a}"
  ui_kv "Cron Job" "${cron_state:-n/a}"
  ui_kv "Log Stream" "${logstream_state:-n/a}"
  ui_kv "Supervisor Log" "${supervisor_log_state:-n/a}"
  ui_kv "Syslog Log" "${syslog_log_state:-n/a}"
  ui_kv "Server PID" "${pid:-n/a}"
  ui_kv "Uptime" "$(server_uptime)"
  ui_kv "Players" "$players"
  ui_kv "Version" "$version"
  ui_kv "Install Path" "$INSTALL_PATH"
  ui_hr
}

tail_logs() {
  local latest
  latest="$(latest_log_file)"
  if [[ -z "$latest" ]]; then
    warn "No log files found (pattern: $LOG_FILE_PATTERN)"
    return 1
  fi
  info "Start log tail: $latest"
  tail -n "${LOG_TAIL_LINES:-200}" -F "$latest" 2>/dev/null | log_pipe info "server-log"
}

manager_loop() {
  local next_update_check now
  local restart_attempts
  local next_health_check
  local restart_suppressed
  next_update_check=$(( $(date +%s) + AUTO_UPDATE_INTERVAL ))
  next_health_check=$(( $(date +%s) + HEALTH_CHECK_INTERVAL ))
  restart_attempts=0
  restart_suppressed="false"

  while true; do
    handle_requests

    now="$(date +%s)"
    if is_true "$AUTO_UPDATE" && [[ "$now" -ge "$next_update_check" ]]; then
      info "Update check (auto)"
      start_update_async || true
      next_update_check=$(( now + AUTO_UPDATE_INTERVAL ))
    fi

    if [[ "$HEALTH_CHECK_INTERVAL" -gt 0 ]] && [[ "$now" -ge "$next_health_check" ]] && ! action_in_progress; then
      health_check || true
      next_health_check=$(( now + HEALTH_CHECK_INTERVAL ))
    fi

    if ! is_server_running; then
      if action_in_progress; then
        if [[ "$restart_suppressed" != "true" ]]; then
          warn "Auto restart skipped: update/restart in progress"
          restart_suppressed="true"
        fi
        sleep 2
        continue
      fi
      restart_suppressed="false"
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
      restart_suppressed="false"
    fi

    sleep 2
  done
}

manager_run() {
  if [[ "${1:-}" != "--as-steam" ]]; then
    update_or_create_manager_config
    init_colors
    ensure_root_and_map_user
    preflight_permissions
    local runtime_home
    runtime_home="${HOME:-/home/steam}"
    export HOME="$runtime_home"
    export INSTALL_PATH CONFIG_FILE STEAM_COMPAT_CLIENT_INSTALL_PATH STEAM_COMPAT_DATA_PATH WINEPREFIX
    supervisor_start || fatal "Supervisor required"
    start_cron_daemon
    start_syslog_daemon || fatal "Syslog start failed"
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
    start_update_async || true
  fi

  if ! is_server_running; then
    start_server
  fi

  start_log_streamer

  if is_true "$HEALTH_CHECK_ON_START"; then
    health_check || true
  fi

  ok "Start complete: Server Manager online"

  manager_loop
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  _server)
    run_server_foreground
    ;;
  _update)
    prepare_action_context
    update_now
    ;;
  _backup)
    prepare_action_context
    backup_now
    ;;
  _restart)
    prepare_action_context
    restart_now
    ;;
  _syslog)
    run_syslog_foreground
    ;;
  _sysloglog)
    run_syslog_log_streamer_foreground
    ;;
  _logstream)
    run_log_streamer_foreground
    ;;
  _supervisorlog)
    run_supervisor_log_streamer_foreground
    ;;
  _cron)
    run_cron_foreground
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
      start_restart_async || exit 1
    fi
    ;;
  update)
    if manager_running; then
      request_action update
    else
      start_update_async || exit 1
    fi
    ;;
  backup)
    if manager_running; then
      request_action backup
    else
      start_backup_async || exit 1
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

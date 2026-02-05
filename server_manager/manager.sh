#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANAGER_BIN="${MANAGER_BIN:-$ROOT_DIR/manager.sh}"
export MANAGER_BIN

. "$ROOT_DIR/lib/common.sh"
. "$ROOT_DIR/lib/config.sh"
. "$ROOT_DIR/lib/server.sh"
. "$ROOT_DIR/lib/update.sh"
. "$ROOT_DIR/lib/backup.sh"
. "$ROOT_DIR/lib/scheduler.sh"
. "$ROOT_DIR/lib/logs.sh"

on_error() {
  error "Unexpected error at line $1"
}
trap 'on_error $LINENO' ERR

print_help() {
  ui_banner
  cat <<EOF
Usage: $MANAGER_BIN <command>

Commands:
  run             Start manager (PID1 mode, handles signals)
  setup           Create config, directories, and install a2s
  start           Start server
  stop            Stop server (or manager if running)
  restart         Restart server (safe check optional)
  update          Check and apply updates
  backup          Create backup now
  status          Show current status
  logs            Tail latest log file
  help            Show this help

Notes:
  - Use UPDATE_CRON/BACKUP_CRON/RESTART_CRON for schedules.
  - Use AUTO_UPDATE=true to enable periodic update checks.
EOF
}

ensure_root_and_map_user() {
  if [[ "$(id -u)" -ne 0 ]]; then
    fatal "Manager must run as root to apply PUID/PGID mapping"
  fi
  if [[ -z "${PUID:-}" || -z "${PGID:-}" ]]; then
    fatal "PUID and PGID are required"
  fi
  if [[ "$PUID" -eq 0 || "$PGID" -eq 0 ]]; then
    fatal "PUID/PGID must not be 0"
  fi
  if ! [[ "$PUID" =~ ^[0-9]+$ ]] || ! [[ "$PGID" =~ ^[0-9]+$ ]]; then
    fatal "PUID/PGID must be numeric"
  fi
  require_cmd runuser

  mkdir -p "$INSTALL_PATH" "$RUN_DIR"
  groupmod -o -g "$PGID" steam
  usermod -o -u "$PUID" -g "$PGID" steam
  chown -R "$PUID:$PGID" "$HOME_DIR" 2>/dev/null || true
  chown -R "$PUID:$PGID" "$INSTALL_PATH" 2>/dev/null || true
  chown -R "$PUID:$PGID" "$RUN_DIR" 2>/dev/null || true
}

setup_environment() {
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

manager_cleanup() {
  stop_log_streamer
  clear_pid "$PID_MANAGER_FILE"
  rm -f "$REQUEST_DIR/update" "$REQUEST_DIR/backup" "$REQUEST_DIR/restart" 2>/dev/null || true
}

handle_shutdown() {
  warn "Shutdown signal received"
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
  players="$(query_player_count)"

  ui_hr
  ui_kv "Manager" "$(manager_running && echo "running" || echo "stopped")"
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
  info "Tailing $log_dir/$latest"
  tail -n "${LOG_TAIL_LINES:-200}" -F "$log_dir/$latest"
}

manager_loop() {
  local next_update_check now
  next_update_check=$(( $(date +%s) + AUTO_UPDATE_INTERVAL ))

  while true; do
    handle_requests

    now="$(date +%s)"
    if is_true "$AUTO_UPDATE" && [[ "$now" -ge "$next_update_check" ]]; then
      info "Auto update check"
      update_now || true
      next_update_check=$(( now + AUTO_UPDATE_INTERVAL ))
    fi

    if ! is_server_running; then
      warn "Server process exited"
      return 0
    fi

    sleep 2
  done
}

manager_run() {
  if [[ "${1:-}" != "--as-steam" ]]; then
    ensure_root_and_map_user
    start_cron_daemon
    exec runuser -u steam -p -- "$MANAGER_BIN" run --as-steam "$@"
  fi

  shift || true

  ui_banner
  ui_kv "Manager Version" "$MANAGER_VERSION"
  ui_kv "Install Path" "$INSTALL_PATH"
  ui_kv "Config" "$CONFIG_FILE"
  ui_hr

  ensure_run_dirs
  write_pid "$PID_MANAGER_FILE"
  trap manager_cleanup EXIT
  trap handle_shutdown SIGINT SIGTERM

  setup_environment

  if is_true "$AUTO_UPDATE_ON_BOOT"; then
    update_now || true
  fi

  if ! is_server_running; then
    start_server
  fi

  start_log_streamer

  manager_loop
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  run)
    manager_run "$@"
    ;;
  setup)
    setup_environment
    ;;
  start)
    if manager_running; then
      warn "Manager is running, start command ignored"
    else
      start_server
    fi
    ;;
  stop)
    if manager_running; then
      info "Stopping manager"
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

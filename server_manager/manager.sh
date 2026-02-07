#!/usr/bin/env bash
MANAGER_DATA_DIR="/server_manager"
BOOTSTRAP_LOG_FILE="/server_manager/manager-bootstrap.log"
BOOTSTRAP_CMD="${1:-}"
if [[ -z "${BOOTSTRAP_FORCE_COLOR:-}" ]]; then
  BOOTSTRAP_FORCE_COLOR="true"
fi

bootstrap_timestamp() {
  date -u "+%Y-%m-%d %H:%M:%S" 2>/dev/null || printf "%s" "1970-01-01 00:00:00"
}

bootstrap_color_enabled() {
  if [[ -n "${NO_COLOR:-}" ]]; then
    return 1
  fi
  if [[ "${BOOTSTRAP_FORCE_COLOR:-}" == "true" || "${BOOTSTRAP_FORCE_COLOR:-}" == "1" || "${FORCE_COLOR:-}" == "1" ]]; then
    return 0
  fi
  [[ -t 1 ]]
}

bootstrap_debug_enabled() {
  if [[ "${MANAGER_BOOTSTRAP_DEBUG:-false}" == "true" ]]; then
    return 0
  fi
  case "${BOOTSTRAP_CMD:-}" in
    bootstrap)
      return 0
      ;;
  esac
  return 1
}

bootstrap_format_message() {
  local msg tag
  msg="$*"
  tag="[BOOT]"
  if [[ -n "${C_PURPLE:-}" ]]; then
    tag="${C_PURPLE}[BOOT]${C_RESET}"
  elif bootstrap_color_enabled; then
    local c_reset c_purple
    c_reset=$'\033[0m'
    c_purple=$'\033[35m'
    tag="${c_purple}[BOOT]${c_reset}"
  fi
  printf "%s %s" "$tag" "$msg"
}

bootstrap_log_path() {
  local file
  file="${BOOTSTRAP_LOG_FILE:-}"
  if [[ -z "$file" ]]; then
    return 0
  fi
  printf "%s" "$file"
}

bootstrap_log() {
  local msg formatted out file
  msg="$*"
  formatted="$(bootstrap_format_message "$msg")"
  if declare -F log_ts_force >/dev/null 2>&1; then
    log_ts_force info "$formatted"
  else
    out="$(bootstrap_timestamp) $formatted"
    printf "%s\n" "$out" || true
  fi
  file="$(bootstrap_log_path)"
  if [[ -n "$file" ]]; then
    mkdir -p "$(dirname "$file")" 2>/dev/null || true
    printf "%s\n" "$(bootstrap_timestamp) [BOOT] [server_manager] $msg" >>"$file" 2>/dev/null || true
  fi
}

bootstrap_diagnostics() {
  if ! bootstrap_debug_enabled; then
    return 0
  fi

  local trap_type suspect line
  bootstrap_log "startup uid=$(id -u 2>/dev/null || echo '?') gid=$(id -g 2>/dev/null || echo '?') user=$(id -un 2>/dev/null || echo '?') bash=${BASH_VERSION:-unknown}"
  if trap_type="$(type -a trap 2>/dev/null || true)"; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && bootstrap_log "trap resolve: $line"
    done <<<"$trap_type"
  fi
  suspect="$(env | grep -E '^(BASH_ENV|ENV|PROMPT_COMMAND|BASH_FUNC_.*%%)=' || true)"
  if [[ -z "$suspect" ]]; then
    bootstrap_log "suspect env: none"
  else
    while IFS= read -r line; do
      [[ -n "$line" ]] && bootstrap_log "suspect env: ${line%%=*}=<set>"
    done <<<"$suspect"
  fi
}

build_sanitized_env() {
  local -n out_ref="$1"
  local entry name
  local dropped
  local -a dropped_names
  out_ref=()
  dropped=0
  dropped_names=()

  while IFS= read -r -d '' entry; do
    name="${entry%%=*}"
    if ! [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      dropped=$((dropped + 1))
      dropped_names+=("$name")
      continue
    fi
    case "$name" in
      BASH_ENV|ENV|PROMPT_COMMAND|SHELLOPTS|BASHOPTS|BASH_FUNC_*)
        dropped=$((dropped + 1))
        dropped_names+=("$name")
        continue
        ;;
    esac
    out_ref+=("$entry")
  done < <(env -0)
  if [[ "$dropped" -gt 0 && "${#dropped_names[@]}" -gt 0 ]]; then
    local list
    list="$(IFS=','; echo "${dropped_names[*]}")"
    bootstrap_log "env dropped: $list"
  fi
}

bootstrap_prepare_manager_dirs() {
  local install_dir data_target profile_target
  install_dir="/home/steam/enshrouded"
  data_target="${install_dir}/server_manager"
  profile_target="${install_dir}/profile"

  mkdir -p "$data_target" "$profile_target" 2>/dev/null || true

  bootstrap_move_dir_contents() {
    local from to label now dest
    from="$1"
    to="$2"
    label="$3"
    now="$(date -u +%Y%m%dT%H%M%SZ 2>/dev/null || echo "unknown")"
    dest="$to"
    mkdir -p "$to" 2>/dev/null || true

    shopt -s dotglob nullglob
    local -a items=("$from"/*)
    shopt -u dotglob nullglob
    if [[ "${#items[@]}" -eq 0 ]]; then
      return 0
    fi

    shopt -s dotglob nullglob
    local -a target_items=("$to"/*)
    shopt -u dotglob nullglob
    if [[ "${#target_items[@]}" -ne 0 ]]; then
      dest="$to/migrated-${label}-${now}"
      mkdir -p "$dest" 2>/dev/null || true
    fi

    if ! mv "${items[@]}" "$dest/" 2>/dev/null; then
      bootstrap_log "WARN: failed to migrate $label data from $from to $dest"
      return 1
    fi
    rmdir "$from" 2>/dev/null || true
    bootstrap_log "migrated $label data from $from to $dest"
  }

  bootstrap_ensure_volume_link() {
    local link target label real target_real
    link="$1"
    target="$2"
    label="$3"

    if [[ -L "$link" ]]; then
      real="$(readlink -f "$link" 2>/dev/null || true)"
      target_real="$(readlink -f "$target" 2>/dev/null || true)"
      if [[ -n "$real" && -n "$target_real" && "$real" == "$target_real" ]]; then
        return 0
      fi
      if [[ -n "$real" && -d "$real" && "$real" != "$target_real" ]]; then
        bootstrap_move_dir_contents "$real" "$target" "$label" || true
      fi
      rm -f "$link" 2>/dev/null || true
    fi

    if [[ -e "$link" && ! -L "$link" ]]; then
      if command -v mountpoint >/dev/null 2>&1 && mountpoint -q "$link"; then
        bootstrap_log "WARN: $label dir is a mountpoint; leaving as-is: $link"
        return 0
      fi
      if [[ -d "$link" ]]; then
        bootstrap_move_dir_contents "$link" "$target" "$label" || true
        rm -rf "$link" 2>/dev/null || true
      else
        rm -f "$link" 2>/dev/null || true
      fi
    fi

    if [[ ! -e "$link" ]]; then
      ln -s "$target" "$link" 2>/dev/null || true
    fi
    if [[ ! -e "$link" ]]; then
      mkdir -p "$link" 2>/dev/null || true
    fi
  }

  bootstrap_ensure_volume_link "/server_manager" "$data_target" "server_manager"
  bootstrap_ensure_volume_link "/profile" "$profile_target" "profile"

  mkdir -p /server_manager/run 2>/dev/null || true
}

# Defensive: avoid inherited shell hooks or function overrides.
bootstrap_prepare_manager_dirs
bootstrap_diagnostics
unset BASH_ENV ENV PROMPT_COMMAND
if declare -F trap >/dev/null 2>&1; then
  bootstrap_log "unset imported trap() function"
  unset -f trap
fi

# Drop any inherited trap handlers from parent environment/shell init.
for _sig in ERR RETURN DEBUG EXIT CHLD SIGINT SIGTERM; do
  builtin trap - "$_sig" 2>/dev/null || true
done

set -euo pipefail

MANAGER_ENV_SNAPSHOT="$(env | cut -d= -f1 | tr '\n' ' ')"

resolve_script_path() {
  local source dir target
  source="$1"

  if command -v readlink >/dev/null 2>&1; then
    while [[ -L "$source" ]]; do
      dir="$(cd -P "$(dirname "$source")" && pwd)"
      target="$(readlink "$source")"
      if [[ "$target" == /* ]]; then
        source="$target"
      else
        source="$dir/$target"
      fi
    done
  fi

  if command -v realpath >/dev/null 2>&1; then
    realpath "$source"
  else
    (cd -P "$(dirname "$source")" && printf "%s/%s" "$(pwd)" "$(basename "$source")")
  fi
}

SCRIPT_PATH="$(resolve_script_path "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
MANAGER_BIN="$SCRIPT_PATH"
MANAGER_ROOT="$ROOT_DIR"
export MANAGER_BIN
export MANAGER_ROOT

safe_source() {
  local file rc
  file="$1"
  if bootstrap_debug_enabled; then
    bootstrap_log "source begin: $file"
  fi
  set +e
  . "$file"
  rc=$?
  set -e
  if bootstrap_debug_enabled; then
    bootstrap_log "source end: $file rc=$rc"
  fi
  return "$rc"
}

safe_source "$ROOT_DIR/lib/common.sh"
safe_source "$ROOT_DIR/lib/profile.sh"
safe_source "$ROOT_DIR/lib/env.sh"
safe_source "$ROOT_DIR/lib/config.sh"
safe_source "$ROOT_DIR/lib/server.sh"
safe_source "$ROOT_DIR/lib/update.sh"
safe_source "$ROOT_DIR/lib/backup.sh"

print_help() {
  ui_banner
  cat <<EOF
Usage: $MANAGER_BIN <command>

Commands:
  run             Start Server Manager loop (expects supervisord running)
  bootstrap       Prepare runtime and exec supervisord (PID1)
  setup           Setup Server Manager (config, directories, a2s)
  start           Start server
  stop            Stop server (or Server Manager if running)
  restart         Restart server (safe check optional)
  update          Update server (check + apply)
  backup          Backup now
  status          Show status (Server Manager + Server)
  logs            Tail latest log file
  healthcheck     Docker healthcheck (supervisor + manager)
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
  ui_kv "Safe Mode" "$SAFE_MODE"
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

manager_bootstrap() {
  update_or_create_manager_config
  init_colors
  set_umask
  ensure_root_and_map_user
  preflight_permissions
  setup_syslog || true
  ok "Bootstrap complete"
  require_cmd supervisord
  exec /usr/bin/supervisord -c /opt/enshrouded/manager/supervisord.conf >/dev/null 2>&1
}

RSYSLOG_CONF="/etc/rsyslog.d/server_manager_stdout.conf"
RSYSLOG_STATE_DIR="${RSYSLOG_STATE_DIR:-${MANAGER_DATA_DIR}/rsyslog}"
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
  cat >"$RSYSLOG_CONF" <<EOF
\$FileOwner root
\$FileGroup root
\$PrivDropToUser root
\$PrivDropToGroup root
\$WorkDirectory ${RSYSLOG_STATE_DIR}
module(load="imuxsock")
\$IMUXSockRateLimitInterval 0
\$template server_manager,"%syslogseverity-text:::uppercase%|%timegenerated:::date-rfc3339%|%syslogtag%%msg:::sp-if-no-1st-sp%%msg:::drop-last-lf%\\n"
\$ActionFileDefaultTemplate server_manager

:msg, contains, "[session] Pending packets list is full" stop
*.* ${SYSLOG_LOG_FILE}
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

supervisor_is_pid1() {
  if is_true "${SUPERVISOR_PID1:-}"; then
    return 0
  fi
  if ! command -v ps >/dev/null 2>&1; then
    return 1
  fi
  local comm
  comm="$(ps -p 1 -o comm= 2>/dev/null || true)"
  [[ "$comm" == "supervisord" ]]
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
  if supervisor_is_pid1; then
    info "Supervisor is PID1; skipping managed shutdown"
  else
    stop_log_streamer
    stop_syslog_daemon || true
    supervisor_shutdown
  fi
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
  tail -n "$LOG_TAIL_LINES" -F "$latest" 2>/dev/null | log_pipe info "server-log"
}

healthcheck() {
  local conf socket comm state
  conf="/opt/enshrouded/manager/supervisord.conf"
  socket="${RUN_DIR}/server-manager-supervisor.sock"

  if ! command -v supervisorctl >/dev/null 2>&1; then
    echo "unhealthy: supervisorctl missing" >&2
    return 1
  fi
  if ! [[ -S "$socket" ]]; then
    echo "unhealthy: supervisor socket missing: $socket" >&2
    return 1
  fi
  if ! supervisorctl -c "$conf" pid >/dev/null 2>&1; then
    echo "unhealthy: supervisorctl not responding" >&2
    return 1
  fi
  if command -v ps >/dev/null 2>&1; then
    comm="$(ps -p 1 -o comm= 2>/dev/null || true)"
    if [[ "$comm" != "supervisord" ]]; then
      echo "unhealthy: pid1 is not supervisord (pid1=$comm)" >&2
      return 1
    fi
  fi
  state="$(supervisorctl -c "$conf" status server-manager-daemon 2>/dev/null | awk '{print $2}')"
  if [[ "$state" != "RUNNING" ]]; then
    echo "unhealthy: server-manager-daemon state=$state" >&2
    return 1
  fi
  return 0
}

manager_loop() {
  local next_update_check now
  local server_stopped_notice
  next_update_check=$(( $(date +%s) + AUTO_UPDATE_INTERVAL ))
  server_stopped_notice="false"

  while true; do
    handle_requests

    now="$(date +%s)"
    if is_true "$AUTO_UPDATE" && [[ "$now" -ge "$next_update_check" ]]; then
      info "Update check (auto)"
      start_update_async || true
      next_update_check=$(( now + AUTO_UPDATE_INTERVAL ))
    fi

    if ! is_server_running; then
      if action_in_progress; then
        sleep 2
        continue
      fi
      if [[ "$server_stopped_notice" != "true" ]]; then
        warn "Server not running (supervisor manages restarts)"
        server_stopped_notice="true"
      fi
      sleep 2
      continue
    else
      server_stopped_notice="false"
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
    local -a forwarded_env
    runtime_home="${HOME:-/home/steam}"
    export HOME="$runtime_home"
    export INSTALL_PATH CONFIG_FILE STEAM_COMPAT_CLIENT_INSTALL_PATH STEAM_COMPAT_DATA_PATH WINEPREFIX
    build_sanitized_env forwarded_env
    bootstrap_log "runuser env entries=${#forwarded_env[@]}"
    supervisor_start || fatal "Supervisor required"
    start_cron_daemon
    start_syslog_daemon || fatal "Syslog start failed"
    exec runuser -u steam -- env -i \
      "${forwarded_env[@]}" \
      HOME="$runtime_home" \
      INSTALL_PATH="$INSTALL_PATH" \
      CONFIG_FILE="$CONFIG_FILE" \
      STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH" \
      STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH" \
      WINEPREFIX="$WINEPREFIX" \
      "$MANAGER_BIN" run --as-steam "$@"
  fi

  shift || true
  update_or_create_manager_config

  ui_banner
  ui_kv "Server Manager Version" "$MANAGER_VERSION"
  ui_kv "Install Path" "$INSTALL_PATH"
  ui_kv "Config" "$CONFIG_FILE"
  ui_hr

  ensure_run_dirs
  write_pid "$PID_MANAGER_FILE"
  builtin trap manager_cleanup EXIT
  builtin trap handle_shutdown SIGINT SIGTERM

  setup_environment

  startup_summary

  start_cron_daemon

  if is_true "$AUTO_UPDATE_ON_BOOT"; then
    if action_in_progress; then
      warn "Update on boot skipped: update/restart in progress"
    else
      info "Update on boot"
      update_now || warn "Update on boot failed"
    fi
  fi

  if ! is_server_running; then
    if action_in_progress; then
      warn "Start skipped: update/restart in progress"
    else
      start_server
    fi
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
  bootstrap)
    manager_bootstrap
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
  healthcheck)
    healthcheck
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

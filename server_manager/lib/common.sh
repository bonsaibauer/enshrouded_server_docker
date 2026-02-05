#!/usr/bin/env bash

# Common helpers for Enshrouded Server Manager.

MANAGER_VERSION="0.1.0"

# Colors (ASCII only)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'
  C_DIM=$'\033[2m'
  C_BOLD=$'\033[1m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
  C_CYAN=$'\033[36m'
else
  C_RESET=""
  C_DIM=""
  C_BOLD=""
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
  C_BLUE=""
  C_CYAN=""
fi

LOG_LEVEL="${LOG_LEVEL:-info}"

level_num() {
  case "${1:-}" in
    debug) echo 10 ;;
    info) echo 20 ;;
    warn) echo 30 ;;
    error) echo 40 ;;
    *) echo 20 ;;
  esac
}

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

level_label() {
  case "${1:-}" in
    debug) echo "${C_DIM}DEBUG${C_RESET}" ;;
    info) echo "${C_GREEN}INFO${C_RESET}" ;;
    warn) echo "${C_YELLOW}WARN${C_RESET}" ;;
    error) echo "${C_RED}ERROR${C_RESET}" ;;
    *) echo "INFO" ;;
  esac
}

log() {
  local level message
  level="${1:-info}"
  shift || true
  message="$*"
  if [ "$(level_num "$level")" -ge "$(level_num "$LOG_LEVEL")" ]; then
    printf "%s [%s] %s\n" "$(timestamp)" "$(level_label "$level")" "$message"
  fi
}

debug() { log debug "$@"; }
info() { log info "$@"; }
warn() { log warn "$@"; }
error() { log error "$@"; }

fatal() {
  log error "$@"
  exit 1
}

ui_hr() {
  printf "%s\n" "----------------------------------------------------------------"
}

ui_banner() {
  cat <<'EOF'
  ______                 _                       _
 |  ____|               | |                     | |
 | |__   _ __  ___  __ _| |__  _ __ ___  ___  __| |
 |  __| | '_ \/ __|/ _` | '_ \| '__/ _ \/ _ \/ _` |
 | |____| | | \__ \ (_| | | | | | |  __/  __/ (_| |
 |______|_| |_|___/\__,_|_| |_|_|  \___|\___|\__,_|
EOF
  printf "%s\n" "                 Server Manager"
  ui_hr
}

ui_kv() {
  local key value
  key="$1"
  value="$2"
  printf "%-22s : %s\n" "$key" "$value"
}

require_cmd() {
  local cmd
  cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || fatal "Missing command: $cmd"
}

set_umask() {
  local mask
  mask="${UMASK:-027}"
  umask "$mask"
}

is_true() {
  case "${1:-}" in
    true|TRUE|yes|YES|1) return 0 ;;
    *) return 1 ;;
  esac
}

abs_path() {
  local p
  p="$1"
  if [[ "$p" == /* ]]; then
    printf "%s" "$p"
  else
    printf "%s" "$INSTALL_PATH/$p"
  fi
}

generate_password() {
  head -c 64 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8
}

# Defaults
HOME_DIR="${HOME_DIR:-${HOME:-/home/steam}}"
INSTALL_PATH="${INSTALL_PATH:-$HOME_DIR/enshrouded}"
CONFIG_FILE="${CONFIG_FILE:-$INSTALL_PATH/enshrouded_server.json}"
VERSION_FILE_PATH="${VERSION_FILE_PATH:-$INSTALL_PATH/.current_version}"
SAVEFILE_NAME="${SAVEFILE_NAME:-3ad85aea}"

STEAM_APP_ID="${STEAM_APP_ID:-2278520}"
GAME_BRANCH="${GAME_BRANCH:-public}"
STEAMCMD_ARGS="${STEAMCMD_ARGS:-validate}"
STEAMCMD_PATH="${STEAMCMD_PATH:-$HOME_DIR/steamcmd}"
PROTON_CMD="${PROTON_CMD:-/usr/local/bin/proton}"
WINESERVER_PATH="${WINESERVER_PATH:-/usr/local/bin/files/bin/wineserver}"

STEAM_COMPAT_CLIENT_INSTALL_PATH="${STEAM_COMPAT_CLIENT_INSTALL_PATH:-$HOME_DIR/.steam/steam}"
STEAM_COMPAT_DATA_PATH="${STEAM_COMPAT_DATA_PATH:-$INSTALL_PATH/steamapps/compatdata/$STEAM_APP_ID}"
WINEPREFIX="${WINEPREFIX:-$STEAM_COMPAT_DATA_PATH/pfx}"

RUN_DIR="${RUN_DIR:-/var/run/enshrouded}"
REQUEST_DIR="${REQUEST_DIR:-$RUN_DIR/requests}"
PID_MANAGER_FILE="${PID_MANAGER_FILE:-$RUN_DIR/enshrouded-manager.pid}"
PID_SERVER_FILE="${PID_SERVER_FILE:-$RUN_DIR/enshrouded-server.pid}"
PID_UPDATE_FILE="${PID_UPDATE_FILE:-$RUN_DIR/enshrouded-updater.pid}"
PID_BACKUP_FILE="${PID_BACKUP_FILE:-$RUN_DIR/enshrouded-backup.pid}"

AUTO_UPDATE="${AUTO_UPDATE:-true}"
AUTO_UPDATE_INTERVAL="${AUTO_UPDATE_INTERVAL:-1800}"
AUTO_UPDATE_ON_BOOT="${AUTO_UPDATE_ON_BOOT:-true}"
AUTO_RESTART_ON_UPDATE="${AUTO_RESTART_ON_UPDATE:-true}"
SAFE_MODE="${SAFE_MODE:-true}"
ENABLE_CRON="${ENABLE_CRON:-true}"
LOG_TO_STDOUT="${LOG_TO_STDOUT:-true}"
LOG_TAIL_LINES="${LOG_TAIL_LINES:-200}"
LOG_POLL_INTERVAL="${LOG_POLL_INTERVAL:-2}"
LOG_FILE_PATTERN="${LOG_FILE_PATTERN:-*}"

UPDATE_CHECK_PLAYERS="${UPDATE_CHECK_PLAYERS:-false}"
RESTART_CHECK_PLAYERS="${RESTART_CHECK_PLAYERS:-false}"

BACKUP_DIR="${BACKUP_DIR:-backups}"
BACKUP_MAX_COUNT="${BACKUP_MAX_COUNT:-0}"
PRINT_ADMIN_PASSWORD="${PRINT_ADMIN_PASSWORD:-true}"

ensure_run_dirs() {
  mkdir -p "$RUN_DIR" "$REQUEST_DIR"
}

write_pid() {
  local pidfile
  pidfile="$1"
  echo "$$" >"$pidfile"
}

clear_pid() {
  local pidfile
  pidfile="$1"
  rm -f "$pidfile"
}

pid_alive() {
  local pid
  pid="$1"
  if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

manager_running() {
  if [[ -f "$PID_MANAGER_FILE" ]]; then
    local pid
    pid="$(cat "$PID_MANAGER_FILE" 2>/dev/null || true)"
    pid_alive "$pid"
    return $?
  fi
  return 1
}

request_action() {
  local action
  action="$1"
  ensure_run_dirs
  echo "$(timestamp)" >"$REQUEST_DIR/$action"
}

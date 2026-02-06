#!/usr/bin/env bash

# Common helpers for Enshrouded Server Manager.

MANAGER_VERSION="0.1.0"

# Colors (ASCII only)
init_colors() {
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'
  C_DIM=$'\033[2m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
else
  C_RESET=""
  C_DIM=""
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
fi
}
init_colors

LOG_LEVEL="${LOG_LEVEL:-info}"
LOG_CONTEXT="${LOG_CONTEXT:-manager}"
LOG_CONTEXT_STACK=()

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
  date -u "+%Y-%m-%dT%H:%M:%SZ"
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
    local context prefix
    context="${LOG_CONTEXT:-manager}"
    prefix="[manager]"
    if [[ -n "$context" && "$context" != "manager" ]]; then
      prefix="$prefix [$context]"
    fi
    printf "%s [%s] %s %s\n" "$(timestamp)" "$(level_label "$level")" "$prefix" "$message"
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
>>=============================================================<<
|| __  __    _    _   _    _    ____ _____ ____    _           ||
|||  \/  |  / \  | \ | |  / \  / ___| ____|  _ \  | |__  _   _ ||
||| |\/| | / _ \ |  \| | / _ \| |  _|  _| | |_) | | '_ \| | | |||
||| |  | |/ ___ \| |\  |/ ___ \ |_| | |___|  _ <  | |_) | |_| |||
|||_|  |_/_/   \_\_| \_/_/   \_\____|_____|_| \_\ |_.__/ \__, |||
||| |__   ___  _ __  ___  __ _(_) |__   __ _ _   _  ___ _|___/ ||
||| '_ \ / _ \| '_ \/ __|/ _` | | '_ \ / _` | | | |/ _ \ '__|  ||
||| |_) | (_) | | | \__ \ (_| | | |_) | (_| | |_| |  __/ |     ||
|||_.__/ \___/|_| |_|___/\__,_|_|_.__/ \__,_|\__,_|\___|_|     ||
>>=============================================================<<
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

log_context_push() {
  local ctx
  ctx="$1"
  LOG_CONTEXT_STACK+=("${LOG_CONTEXT:-manager}")
  LOG_CONTEXT="$ctx"
}

log_context_pop() {
  local idx
  idx=$((${#LOG_CONTEXT_STACK[@]} - 1))
  if [[ "$idx" -ge 0 ]]; then
    LOG_CONTEXT="${LOG_CONTEXT_STACK[$idx]}"
    unset "LOG_CONTEXT_STACK[$idx]"
  else
    LOG_CONTEXT="manager"
  fi
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
HOME="/home/steam"
INSTALL_PATH="/home/steam/enshrouded"
CONFIG_FILE="/home/steam/enshrouded/enshrouded_server.json"
VERSION_FILE_PATH="/home/steam/enshrouded/.current_version"
SAVEFILE_NAME="${SAVEFILE_NAME:-3ad85aea}"

STEAM_APP_ID="${STEAM_APP_ID:-2278520}"
GAME_BRANCH="${GAME_BRANCH:-public}"
STEAMCMD_ARGS="${STEAMCMD_ARGS:-validate}"
STEAMCMD_PATH="/home/steam/steamcmd"
PROTON_CMD="${PROTON_CMD:-/usr/local/bin/proton}"
WINESERVER_PATH="${WINESERVER_PATH:-/usr/local/bin/files/bin/wineserver}"

STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/steam/.steam/steam"
STEAM_COMPAT_DATA_PATH="/home/steam/enshrouded/steamapps/compatdata/2278520"
WINEPREFIX="/home/steam/enshrouded/steamapps/compatdata/2278520/pfx"

RUN_DIR="/var/run/enshrouded"
PID_MANAGER_FILE="/var/run/enshrouded/enshrouded-manager.pid"
PID_SERVER_FILE="/var/run/enshrouded/enshrouded-server.pid"
PID_UPDATE_FILE="/var/run/enshrouded/enshrouded-updater.pid"
PID_BACKUP_FILE="/var/run/enshrouded/enshrouded-backup.pid"

AUTO_UPDATE="${AUTO_UPDATE:-true}"
AUTO_UPDATE_INTERVAL="${AUTO_UPDATE_INTERVAL:-1800}"
AUTO_UPDATE_ON_BOOT="${AUTO_UPDATE_ON_BOOT:-true}"
AUTO_RESTART_ON_UPDATE="${AUTO_RESTART_ON_UPDATE:-true}"
SAFE_MODE="${SAFE_MODE:-true}"
ENABLE_CRON="${ENABLE_CRON:-true}"
LOG_TO_STDOUT="${LOG_TO_STDOUT:-true}"
LOG_TAIL_LINES="${LOG_TAIL_LINES:-200}"
LOG_POLL_INTERVAL="${LOG_POLL_INTERVAL:-2}"
LOG_FILE_PATTERN="${LOG_FILE_PATTERN:-*.log}"
AUTO_RESTART="${AUTO_RESTART:-true}"
AUTO_RESTART_DELAY="${AUTO_RESTART_DELAY:-10}"
AUTO_RESTART_MAX_ATTEMPTS="${AUTO_RESTART_MAX_ATTEMPTS:-0}"
HEALTH_CHECK_INTERVAL="${HEALTH_CHECK_INTERVAL:-300}"
HEALTH_CHECK_ON_START="${HEALTH_CHECK_ON_START:-true}"
A2S_TIMEOUT="${A2S_TIMEOUT:-2}"
A2S_RETRIES="${A2S_RETRIES:-2}"
A2S_RETRY_DELAY="${A2S_RETRY_DELAY:-1}"

UPDATE_CHECK_PLAYERS="${UPDATE_CHECK_PLAYERS:-false}"
RESTART_CHECK_PLAYERS="${RESTART_CHECK_PLAYERS:-false}"

BACKUP_DIR="${BACKUP_DIR:-backups}"
BACKUP_MAX_COUNT="${BACKUP_MAX_COUNT:-0}"
PRINT_ADMIN_PASSWORD="${PRINT_ADMIN_PASSWORD:-true}"

ensure_run_dirs() {
  mkdir -p "$RUN_DIR"
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
  echo "$(timestamp)" >"$RUN_DIR/$action"
}

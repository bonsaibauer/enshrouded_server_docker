#!/usr/bin/env bash

# Common helpers for Enshrouded Server Manager.

MANAGER_VERSION_FILE="${MANAGER_ROOT:-/opt/enshrouded/manager}/VERSION"
MANAGER_VERSION="2.1.0"
if [[ -f "$MANAGER_VERSION_FILE" ]]; then
  MANAGER_VERSION="$(tr -d '\r\n' <"$MANAGER_VERSION_FILE")"
  if [[ -z "$MANAGER_VERSION" ]]; then
    MANAGER_VERSION="2.1.0"
  fi
fi

# Colors (ASCII only)
init_colors() {
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_RESET=$'\033[0m'
    C_DIM=$'\033[2m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_OK=$'\033[1;32m'
    C_YELLOW=$'\033[33m'
    C_PURPLE=$'\033[35m'
  else
    C_RESET=""
    C_DIM=""
    C_RED=""
    C_GREEN=""
    C_OK=""
    C_YELLOW=""
    C_PURPLE=""
  fi
}
init_colors

LOG_LEVEL="${LOG_LEVEL:-info}"
LOG_CONTEXT="${LOG_CONTEXT:-server_manager}"
LOG_CONTEXT_STACK=()

level_num() {
  case "${1:-}" in
    debug) echo 10 ;;
    info|ok) echo 20 ;;
    warn) echo 30 ;;
    error) echo 40 ;;
    *) echo 20 ;;
  esac
}

timestamp() {
  date -u "+%Y-%m-%d %H:%M:%S" 2>/dev/null || printf "%s" "1970-01-01 00:00:00"
}

level_label() {
  case "${1:-}" in
    debug) echo "${C_DIM}DEBUG${C_RESET}" ;;
    info) echo "${C_GREEN}INFO${C_RESET}" ;;
    ok) echo "${C_OK}OK${C_RESET}" ;;
    warn) echo "${C_YELLOW}WARN${C_RESET}" ;;
    error) echo "${C_RED}ERROR${C_RESET}" ;;
    *) echo "INFO" ;;
  esac
}

log_emit() {
  local line
  line="$1"
  printf "%s\n" "$line" || true
  return 0
}

log() {
  local level message out
  level="${1:-info}"
  shift || true
  message="$*"
  if [ "$(level_num "$level")" -ge "$(level_num "$LOG_LEVEL")" ]; then
    local context prefix
    context="${LOG_CONTEXT:-server_manager}"
    prefix="[server_manager]"
    if [[ -n "$context" && "$context" != "server_manager" ]]; then
      prefix="$prefix [$context]"
    fi
    printf -v out "%s [%s] %s %s" "$(timestamp)" "$(level_label "$level")" "$prefix" "$message"
    log_emit "$out"
  fi
  return 0
}

log_no_ts_force() {
  local level message out
  level="${1:-info}"
  shift || true
  message="$*"
  local context prefix
  context="${LOG_CONTEXT:-server_manager}"
  prefix="[server_manager]"
  if [[ -n "$context" && "$context" != "server_manager" ]]; then
    prefix="$prefix [$context]"
  fi
  printf -v out "[%s] %s %s" "$(level_label "$level")" "$prefix" "$message"
  log_emit "$out"
  return 0
}

log_ts_force() {
  local level message out
  level="${1:-info}"
  shift || true
  message="$*"
  local context prefix
  context="${LOG_CONTEXT:-server_manager}"
  prefix="[server_manager]"
  if [[ -n "$context" && "$context" != "server_manager" ]]; then
    prefix="$prefix [$context]"
  fi
  printf -v out "%s [%s] %s %s" "$(timestamp)" "$(level_label "$level")" "$prefix" "$message"
  log_emit "$out"
  return 0
}

log_pipe() {
  local level context line prev
  level="${1:-info}"
  context="${2:-}"
  prev="${LOG_CONTEXT:-server_manager}"
  if [[ -n "$context" ]]; then
    LOG_CONTEXT="$context"
  fi
  while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      continue
    fi
    log_ts_force "$level" "$line"
  done
  LOG_CONTEXT="$prev"
}

run_logged() {
  local level context
  level="${1:-info}"
  context="${2:-}"
  shift 2 || true
  "$@" 2>&1 | log_pipe "$level" "$context"
  return ${PIPESTATUS[0]}
}

run_hook_logged() {
  local hook level context fifo log_pid rc
  hook="${1:-}"
  level="${2:-info}"
  context="${3:-}"
  if [[ -z "$hook" ]]; then
    return 0
  fi
  if ! command -v mktemp >/dev/null 2>&1 || ! command -v mkfifo >/dev/null 2>&1; then
    eval "$hook"
    return $?
  fi
  fifo="$(mktemp)"
  rm -f "$fifo"
  mkfifo "$fifo"
  log_pipe "$level" "$context" <"$fifo" &
  log_pid=$!
  eval "$hook" >"$fifo" 2>&1
  rc=$?
  wait "$log_pid" || true
  rm -f "$fifo"
  return $rc
}

debug() { log debug "$@"; }
info() { log info "$@"; }
ok() { log ok "$@"; }
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
  printf "%s\n" "        Enshrouded Control Layer"
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
  LOG_CONTEXT_STACK+=("${LOG_CONTEXT:-server_manager}")
  LOG_CONTEXT="$ctx"
}

log_context_pop() {
  local idx
  idx=$((${#LOG_CONTEXT_STACK[@]} - 1))
  if [[ "$idx" -ge 0 ]]; then
    LOG_CONTEXT="${LOG_CONTEXT_STACK[$idx]}"
    unset "LOG_CONTEXT_STACK[$idx]"
  else
    LOG_CONTEXT="server_manager"
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
PROTON_CMD="/usr/local/bin/proton"
WINESERVER_PATH="/usr/local/bin/files/bin/wineserver"
WINETRICKS="${WINETRICKS:-/usr/local/bin/winetricks}"
export WINETRICKS

STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/steam/.steam/steam"
STEAM_COMPAT_DATA_PATH="/home/steam/enshrouded/steamapps/compatdata/2278520"
WINEPREFIX="/home/steam/enshrouded/steamapps/compatdata/2278520/pfx"

RUN_DIR="/var/run/enshrouded"
PID_MANAGER_FILE="/var/run/enshrouded/enshrouded-manager.pid"
PID_SERVER_FILE="/var/run/enshrouded/enshrouded-server.pid"
PID_UPDATE_FILE="/var/run/enshrouded/enshrouded-updater.pid"
PID_BACKUP_FILE="/var/run/enshrouded/enshrouded-backup.pid"
PID_RESTART_FILE="/var/run/enshrouded/enshrouded-restart.pid"

AUTO_UPDATE="${AUTO_UPDATE:-true}"
AUTO_UPDATE_INTERVAL="${AUTO_UPDATE_INTERVAL:-1800}"
AUTO_UPDATE_ON_BOOT="${AUTO_UPDATE_ON_BOOT:-true}"
AUTO_RESTART_ON_UPDATE="${AUTO_RESTART_ON_UPDATE:-true}"
SAFE_MODE="${SAFE_MODE:-true}"
ENABLE_CRON="${ENABLE_CRON:-true}"
LOG_TO_STDOUT="true"
LOG_TAIL_LINES="200"
LOG_POLL_INTERVAL="2"
LOG_FILE_PATTERN="*.log"
A2S_TIMEOUT="${A2S_TIMEOUT:-2}"
A2S_RETRIES="${A2S_RETRIES:-2}"
A2S_RETRY_DELAY="${A2S_RETRY_DELAY:-1}"

UPDATE_CHECK_PLAYERS="${UPDATE_CHECK_PLAYERS:-false}"
RESTART_CHECK_PLAYERS="${RESTART_CHECK_PLAYERS:-false}"

BACKUP_DIR="${BACKUP_DIR:-backups}"
BACKUP_MAX_COUNT="${BACKUP_MAX_COUNT:-0}"
PRINT_GROUP_PASSWORDS="${PRINT_GROUP_PASSWORDS:-true}"

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

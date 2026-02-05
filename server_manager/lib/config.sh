#!/usr/bin/env bash

# Config and setup helpers.
#
# Supported ENV (ENSHROUDED_ prefix):
# Core:
#   ENSHROUDED_NAME
#   ENSHROUDED_SAVE_DIR
#   ENSHROUDED_LOG_DIR
#   ENSHROUDED_IP
#   ENSHROUDED_QUERY_PORT
#   ENSHROUDED_SLOT_COUNT
#   ENSHROUDED_TAGS (comma separated)
#   ENSHROUDED_VOICE_CHAT_MODE
#   ENSHROUDED_ENABLE_VOICE_CHAT (true/false)
#   ENSHROUDED_ENABLE_TEXT_CHAT (true/false)
# Roles (repeat for any index):
#   ENSHROUDED_ROLE_<index>_NAME
#   ENSHROUDED_ROLE_<index>_PASSWORD
#   ENSHROUDED_ROLE_<index>_CAN_KICK_BAN (true/false)
#   ENSHROUDED_ROLE_<index>_CAN_ACCESS_INVENTORIES (true/false)
#   ENSHROUDED_ROLE_<index>_CAN_EDIT_WORLD (true/false)
#   ENSHROUDED_ROLE_<index>_CAN_EDIT_BASE (true/false)
#   ENSHROUDED_ROLE_<index>_CAN_EXTEND_BASE (true/false)
#   ENSHROUDED_ROLE_<index>_RESERVED_SLOTS (number)
# Game settings (prefix ENSHROUDED_GS_):
#   ENSHROUDED_GS_PRESET
#   ENSHROUDED_GS_PLAYER_HEALTH_FACTOR
#   ENSHROUDED_GS_PLAYER_MANA_FACTOR
#   ENSHROUDED_GS_PLAYER_STAMINA_FACTOR
#   ENSHROUDED_GS_PLAYER_BODY_HEAT_FACTOR
#   ENSHROUDED_GS_PLAYER_DIVING_TIME_FACTOR
#   ENSHROUDED_GS_ENABLE_DURABILITY
#   ENSHROUDED_GS_ENABLE_STARVING_DEBUFF
#   ENSHROUDED_GS_FOOD_BUFF_DURATION_FACTOR
#   ENSHROUDED_GS_FROM_HUNGER_TO_STARVING
#   ENSHROUDED_GS_SHROUD_TIME_FACTOR
#   ENSHROUDED_GS_TOMBSTONE_MODE
#   ENSHROUDED_GS_ENABLE_GLIDER_TURBULENCES
#   ENSHROUDED_GS_WEATHER_FREQUENCY
#   ENSHROUDED_GS_FISHING_DIFFICULTY
#   ENSHROUDED_GS_MINING_DAMAGE_FACTOR
#   ENSHROUDED_GS_PLANT_GROWTH_SPEED_FACTOR
#   ENSHROUDED_GS_RESOURCE_DROP_STACK_AMOUNT_FACTOR
#   ENSHROUDED_GS_FACTORY_PRODUCTION_SPEED_FACTOR
#   ENSHROUDED_GS_PERK_UPGRADE_RECYCLING_FACTOR
#   ENSHROUDED_GS_PERK_COST_FACTOR
#   ENSHROUDED_GS_EXPERIENCE_COMBAT_FACTOR
#   ENSHROUDED_GS_EXPERIENCE_MINING_FACTOR
#   ENSHROUDED_GS_EXPERIENCE_EXPLORATION_QUESTS_FACTOR
#   ENSHROUDED_GS_RANDOM_SPAWNER_AMOUNT
#   ENSHROUDED_GS_AGGRO_POOL_AMOUNT
#   ENSHROUDED_GS_ENEMY_DAMAGE_FACTOR
#   ENSHROUDED_GS_ENEMY_HEALTH_FACTOR
#   ENSHROUDED_GS_ENEMY_STAMINA_FACTOR
#   ENSHROUDED_GS_ENEMY_PERCEPTION_RANGE_FACTOR
#   ENSHROUDED_GS_BOSS_DAMAGE_FACTOR
#   ENSHROUDED_GS_BOSS_HEALTH_FACTOR
#   ENSHROUDED_GS_THREAT_BONUS
#   ENSHROUDED_GS_PACIFY_ALL_ENEMIES
#   ENSHROUDED_GS_TAMING_STARTLE_REPERCUSSION
#   ENSHROUDED_GS_DAY_TIME_DURATION
#   ENSHROUDED_GS_NIGHT_TIME_DURATION
#   ENSHROUDED_GS_CURSE_MODIFIER

ENSHROUDED_NAME="${ENSHROUDED_NAME:-}"
ENSHROUDED_SAVE_DIR="${ENSHROUDED_SAVE_DIR:-}"
ENSHROUDED_LOG_DIR="${ENSHROUDED_LOG_DIR:-}"
ENSHROUDED_IP="${ENSHROUDED_IP:-}"
ENSHROUDED_QUERY_PORT="${ENSHROUDED_QUERY_PORT:-}"
ENSHROUDED_SLOT_COUNT="${ENSHROUDED_SLOT_COUNT:-}"
ENSHROUDED_TAGS="${ENSHROUDED_TAGS:-}"
ENSHROUDED_VOICE_CHAT_MODE="${ENSHROUDED_VOICE_CHAT_MODE:-}"
ENSHROUDED_ENABLE_VOICE_CHAT="${ENSHROUDED_ENABLE_VOICE_CHAT:-}"
ENSHROUDED_ENABLE_TEXT_CHAT="${ENSHROUDED_ENABLE_TEXT_CHAT:-}"
ENSHROUDED_GS_PRESET="${ENSHROUDED_GS_PRESET:-}"

is_bool() {
  case "$1" in
    true|false) return 0 ;;
    *) return 1 ;;
  esac
}

is_number() {
  [[ "$1" =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]]
}

validate_bool() {
  local name value
  name="$1"
  value="$2"
  if [[ -n "$value" ]] && ! is_bool "$value"; then
    fatal "$name must be true or false (actual: $value)"
  fi
}

validate_bool_soft() {
  local name value
  name="$1"
  value="$2"
  if [[ -n "$value" ]] && ! is_bool "$value"; then
    warn "$name must be true or false (actual: $value)"
    return 1
  fi
  return 0
}

validate_enum() {
  local name value allowed
  name="$1"
  value="$2"
  shift 2
  for allowed in "$@"; do
    if [[ "$value" == "$allowed" ]]; then
      return 0
    fi
  done
  fatal "$name must be one of: $* (actual: $value)"
}

validate_enum_soft() {
  local name value allowed
  name="$1"
  value="$2"
  shift 2
  for allowed in "$@"; do
    if [[ "$value" == "$allowed" ]]; then
      return 0
    fi
  done
  warn "$name must be one of: $* (actual: $value)"
  return 1
}

validate_number_range_soft() {
  local name value min max
  name="$1"
  value="$2"
  min="$3"
  max="$4"
  if ! is_number "$value"; then
    warn "$name must be numeric (actual: $value)"
    return 1
  fi
  if awk -v v="$value" -v min="$min" -v max="$max" 'BEGIN { exit !(v >= min && v <= max) }'; then
    return 0
  fi
  warn "$name must be between $min and $max (actual: $value)"
  return 1
}

json_has_value() {
  local path
  path="$1"
  jq -e "$path != null" "$CONFIG_FILE" >/dev/null 2>&1
}

env_was_set() {
  local name value
  name="$1"

  if [[ -n "${MANAGER_ENV_IGNORE[$name]-}" ]]; then
    return 1
  fi

  if [[ -n "${MANAGER_ENV_SNAPSHOT:-}" ]]; then
    case " $MANAGER_ENV_SNAPSHOT " in
      *" $name "*) ;;
      *) return 1 ;;
    esac
  fi

  value="$(printenv "$name" 2>/dev/null || true)"
  [[ -n "$value" ]]
}

manager_config_path() {
  local dir
  dir="$(dirname "$CONFIG_FILE")"
  printf "%s/server_manager.json" "$dir"
}

declare -a MANAGER_VARS=(
  PUID
  PGID
  MANAGER_BIN
  NO_COLOR
  LOG_LEVEL
  LOG_CONTEXT
  UMASK
  HOME_DIR
  INSTALL_PATH
  CONFIG_FILE
  VERSION_FILE_PATH
  SAVEFILE_NAME
  ENSHROUDED_BINARY
  STOP_TIMEOUT
  RUN_DIR
  REQUEST_DIR
  PID_MANAGER_FILE
  PID_SERVER_FILE
  PID_UPDATE_FILE
  PID_BACKUP_FILE
  STEAM_APP_ID
  GAME_BRANCH
  STEAMCMD_ARGS
  STEAMCMD_PATH
  PROTON_CMD
  WINESERVER_PATH
  STEAM_COMPAT_CLIENT_INSTALL_PATH
  STEAM_COMPAT_DATA_PATH
  WINEPREFIX
  WINEDEBUG
  WINETRICKS
  AUTO_UPDATE
  AUTO_UPDATE_INTERVAL
  AUTO_UPDATE_ON_BOOT
  AUTO_RESTART_ON_UPDATE
  AUTO_RESTART
  AUTO_RESTART_DELAY
  AUTO_RESTART_MAX_ATTEMPTS
  SAFE_MODE
  HEALTH_CHECK_INTERVAL
  HEALTH_CHECK_ON_START
  UPDATE_CHECK_PLAYERS
  RESTART_CHECK_PLAYERS
  A2S_TIMEOUT
  A2S_RETRIES
  A2S_RETRY_DELAY
  LOG_TO_STDOUT
  LOG_TAIL_LINES
  LOG_POLL_INTERVAL
  LOG_FILE_PATTERN
  LOG_STREAM_PID_FILE
  LOG_STREAM_TAIL_PID_FILE
  BACKUP_DIR
  BACKUP_MAX_COUNT
  BACKUP_PRE_HOOK
  BACKUP_POST_HOOK
  ENABLE_CRON
  UPDATE_CRON
  BACKUP_CRON
  RESTART_CRON
  BOOTSTRAP_HOOK
  UPDATE_PRE_HOOK
  UPDATE_POST_HOOK
  RESTART_PRE_HOOK
  RESTART_POST_HOOK
  PRINT_ADMIN_PASSWORD
)

declare -A MANAGER_JSON_PATH=(
  [PUID]=".puid"
  [PGID]=".pgid"
  [MANAGER_BIN]=".managerBin"
  [NO_COLOR]=".noColor"
  [LOG_LEVEL]=".logLevel"
  [LOG_CONTEXT]=".logContext"
  [UMASK]=".umask"
  [HOME_DIR]=".homeDir"
  [INSTALL_PATH]=".installPath"
  [CONFIG_FILE]=".configFile"
  [VERSION_FILE_PATH]=".versionFilePath"
  [SAVEFILE_NAME]=".savefileName"
  [ENSHROUDED_BINARY]=".enshroudedBinary"
  [STOP_TIMEOUT]=".stopTimeout"
  [RUN_DIR]=".runDir"
  [REQUEST_DIR]=".requestDir"
  [PID_MANAGER_FILE]=".pidManagerFile"
  [PID_SERVER_FILE]=".pidServerFile"
  [PID_UPDATE_FILE]=".pidUpdateFile"
  [PID_BACKUP_FILE]=".pidBackupFile"
  [STEAM_APP_ID]=".steamAppId"
  [GAME_BRANCH]=".gameBranch"
  [STEAMCMD_ARGS]=".steamcmdArgs"
  [STEAMCMD_PATH]=".steamcmdPath"
  [PROTON_CMD]=".protonCmd"
  [WINESERVER_PATH]=".wineserverPath"
  [STEAM_COMPAT_CLIENT_INSTALL_PATH]=".steamCompatClientInstallPath"
  [STEAM_COMPAT_DATA_PATH]=".steamCompatDataPath"
  [WINEPREFIX]=".wineprefix"
  [WINEDEBUG]=".winedebug"
  [WINETRICKS]=".winetricks"
  [AUTO_UPDATE]=".autoUpdate"
  [AUTO_UPDATE_INTERVAL]=".autoUpdateInterval"
  [AUTO_UPDATE_ON_BOOT]=".autoUpdateOnBoot"
  [AUTO_RESTART_ON_UPDATE]=".autoRestartOnUpdate"
  [AUTO_RESTART]=".autoRestart"
  [AUTO_RESTART_DELAY]=".autoRestartDelay"
  [AUTO_RESTART_MAX_ATTEMPTS]=".autoRestartMaxAttempts"
  [SAFE_MODE]=".safeMode"
  [HEALTH_CHECK_INTERVAL]=".healthCheckInterval"
  [HEALTH_CHECK_ON_START]=".healthCheckOnStart"
  [UPDATE_CHECK_PLAYERS]=".updateCheckPlayers"
  [RESTART_CHECK_PLAYERS]=".restartCheckPlayers"
  [A2S_TIMEOUT]=".a2sTimeout"
  [A2S_RETRIES]=".a2sRetries"
  [A2S_RETRY_DELAY]=".a2sRetryDelay"
  [LOG_TO_STDOUT]=".logToStdout"
  [LOG_TAIL_LINES]=".logTailLines"
  [LOG_POLL_INTERVAL]=".logPollInterval"
  [LOG_FILE_PATTERN]=".logFilePattern"
  [LOG_STREAM_PID_FILE]=".logStreamPidFile"
  [LOG_STREAM_TAIL_PID_FILE]=".logStreamTailPidFile"
  [BACKUP_DIR]=".backupDir"
  [BACKUP_MAX_COUNT]=".backupMaxCount"
  [BACKUP_PRE_HOOK]=".backupPreHook"
  [BACKUP_POST_HOOK]=".backupPostHook"
  [ENABLE_CRON]=".enableCron"
  [UPDATE_CRON]=".updateCron"
  [BACKUP_CRON]=".backupCron"
  [RESTART_CRON]=".restartCron"
  [BOOTSTRAP_HOOK]=".bootstrapHook"
  [UPDATE_PRE_HOOK]=".updatePreHook"
  [UPDATE_POST_HOOK]=".updatePostHook"
  [RESTART_PRE_HOOK]=".restartPreHook"
  [RESTART_POST_HOOK]=".restartPostHook"
  [PRINT_ADMIN_PASSWORD]=".printAdminPassword"
)

declare -A MANAGER_TYPE=(
  [PUID]="int"
  [PGID]="int"
  [STEAM_APP_ID]="int"
  [AUTO_UPDATE_INTERVAL]="int"
  [AUTO_RESTART_DELAY]="int"
  [AUTO_RESTART_MAX_ATTEMPTS]="int"
  [HEALTH_CHECK_INTERVAL]="int"
  [A2S_RETRIES]="int"
  [LOG_TAIL_LINES]="int"
  [LOG_POLL_INTERVAL]="int"
  [BACKUP_MAX_COUNT]="int"
  [STOP_TIMEOUT]="int"
  [A2S_TIMEOUT]="number"
  [A2S_RETRY_DELAY]="number"
  [AUTO_UPDATE]="bool"
  [AUTO_UPDATE_ON_BOOT]="bool"
  [AUTO_RESTART_ON_UPDATE]="bool"
  [AUTO_RESTART]="bool"
  [SAFE_MODE]="bool"
  [HEALTH_CHECK_ON_START]="bool"
  [UPDATE_CHECK_PLAYERS]="bool"
  [RESTART_CHECK_PLAYERS]="bool"
  [LOG_TO_STDOUT]="bool"
  [ENABLE_CRON]="bool"
  [PRINT_ADMIN_PASSWORD]="bool"
)

declare -A MANAGER_EXPLICIT_VARS=()
declare -A MANAGER_ENV_IGNORE=()
declare -A MANAGER_JSON_INVALID=()

manager_config_set() {
  local file temp_file
  file="$1"
  shift
  temp_file="$(mktemp)"
  if jq "$@" "$file" >"$temp_file"; then
    mv "$temp_file" "$file"
  else
    rm -f "$temp_file"
    fatal "Failed to update $file (jq error)"
  fi
}

manager_json_get() {
  local file var path
  file="$1"
  var="$2"
  path="${MANAGER_JSON_PATH[$var]-}"
  if [[ -z "$path" ]]; then
    echo ""
    return 0
  fi
  jq -r "$path // empty" "$file" 2>/dev/null || true
}

manager_config_set_value() {
  local file var value path type
  file="$1"
  var="$2"
  value="${3-}"
  path="${MANAGER_JSON_PATH[$var]-}"
  type="${MANAGER_TYPE[$var]-string}"
  if [[ -z "$path" ]]; then
    return 0
  fi
  if [[ -z "$value" ]]; then
    manager_config_set "$file" "$path = null"
    return 0
  fi
  case "$type" in
    bool|int|number)
      manager_config_set "$file" --argjson val "$value" "$path = \$val"
      ;;
    *)
      manager_config_set "$file" --arg val "$value" "$path = \$val"
      ;;
  esac
}

normalize_log_level() {
  local value lowered
  value="$1"
  lowered="$(echo "$value" | tr '[:upper:]' '[:lower:]')"
  case "$lowered" in
    debug|info|warn|error)
      echo "$lowered"
      return 0
      ;;
    *)
      echo "info"
      return 1
      ;;
  esac
}

manager_validation_fail() {
  local mode
  mode="$1"
  shift
  if [[ "$mode" == "hard" ]]; then
    fatal "$@"
  else
    warn "$@"
    return 1
  fi
}

validate_int_min() {
  local name value min mode
  name="$1"
  value="$2"
  min="$3"
  mode="$4"
  if ! [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" -lt "$min" ]]; then
    manager_validation_fail "$mode" "$name must be an integer >= $min (actual: $value)"
    return 1
  fi
  return 0
}

validate_number_min() {
  local name value min mode
  name="$1"
  value="$2"
  min="$3"
  mode="$4"
  if ! is_number "$value"; then
    manager_validation_fail "$mode" "$name must be numeric (actual: $value)"
    return 1
  fi
  if awk -v v="$value" -v min="$min" 'BEGIN { exit !(v >= min) }'; then
    return 0
  fi
  manager_validation_fail "$mode" "$name must be >= $min (actual: $value)"
  return 1
}

validate_manager_value() {
  local var value mode normalized
  var="$1"
  value="$2"
  mode="$3"

  case "$var" in
    PUID|PGID)
      if [[ -z "$value" ]]; then
        return 0
      fi
      validate_int_min "$var" "$value" 1 "$mode"
      return $?
      ;;
    STEAM_APP_ID)
      if [[ -z "$value" ]]; then
        return 0
      fi
      validate_int_min "$var" "$value" 1 "$mode"
      return $?
      ;;
    STOP_TIMEOUT)
      validate_int_min "$var" "$value" 1 "$mode"
      return $?
      ;;
    AUTO_UPDATE_INTERVAL)
      validate_int_min "$var" "$value" 1 "$mode"
      return $?
      ;;
    AUTO_RESTART_DELAY)
      validate_int_min "$var" "$value" 0 "$mode"
      return $?
      ;;
    AUTO_RESTART_MAX_ATTEMPTS)
      validate_int_min "$var" "$value" 0 "$mode"
      return $?
      ;;
    HEALTH_CHECK_INTERVAL)
      validate_int_min "$var" "$value" 0 "$mode"
      return $?
      ;;
    A2S_RETRIES)
      validate_int_min "$var" "$value" 0 "$mode"
      return $?
      ;;
    LOG_TAIL_LINES)
      validate_int_min "$var" "$value" 0 "$mode"
      return $?
      ;;
    LOG_POLL_INTERVAL)
      validate_int_min "$var" "$value" 0 "$mode"
      return $?
      ;;
    BACKUP_MAX_COUNT)
      validate_int_min "$var" "$value" 0 "$mode"
      return $?
      ;;
    A2S_TIMEOUT)
      validate_number_min "$var" "$value" 0 "$mode"
      return $?
      ;;
    A2S_RETRY_DELAY)
      validate_number_min "$var" "$value" 0 "$mode"
      return $?
      ;;
    UMASK)
      if [[ -n "$value" ]] && ! [[ "$value" =~ ^[0-7]{3,4}$ ]]; then
        manager_validation_fail "$mode" "$var must be an octal string like 027 (actual: $value)"
        return 1
      fi
      ;;
    LOG_LEVEL)
      if [[ -n "$value" ]]; then
        case "$(echo "$value" | tr '[:upper:]' '[:lower:]')" in
          debug|info|warn|error) ;;
          *)
            manager_validation_fail "$mode" "$var must be one of: debug info warn error (actual: $value)"
            return 1
            ;;
        esac
      fi
      ;;
    AUTO_UPDATE|AUTO_UPDATE_ON_BOOT|AUTO_RESTART_ON_UPDATE|AUTO_RESTART|SAFE_MODE|HEALTH_CHECK_ON_START|UPDATE_CHECK_PLAYERS|RESTART_CHECK_PLAYERS|LOG_TO_STDOUT|ENABLE_CRON|PRINT_ADMIN_PASSWORD)
      if [[ "$mode" == "hard" ]]; then
        validate_bool "$var" "$value"
      else
        validate_bool_soft "$var" "$value"
      fi
      return $?
      ;;
  esac
}

manager_default_for_var() {
  local var home install run_dir app_id compat
  var="$1"

  if [[ -n "${MANAGER_EXPLICIT_VARS[$var]-}" ]]; then
    echo "${!var-}"
    return 0
  fi

  case "$var" in
    PUID|PGID)
      echo ""
      ;;
    MANAGER_BIN)
      echo "${MANAGER_BIN:-}"
      ;;
    NO_COLOR)
      echo "${NO_COLOR:-}"
      ;;
    LOG_LEVEL)
      echo "${LOG_LEVEL:-info}"
      ;;
    LOG_CONTEXT)
      echo "${LOG_CONTEXT:-manager}"
      ;;
    UMASK)
      echo "${UMASK:-027}"
      ;;
    HOME_DIR)
      if [[ -n "${HOME_DIR:-}" ]]; then
        echo "$HOME_DIR"
      else
        echo "${HOME:-/home/steam}"
      fi
      ;;
    INSTALL_PATH)
      home="${HOME_DIR:-${HOME:-/home/steam}}"
      echo "$home/enshrouded"
      ;;
    CONFIG_FILE)
      home="${HOME_DIR:-${HOME:-/home/steam}}"
      install="${INSTALL_PATH:-$home/enshrouded}"
      echo "$install/enshrouded_server.json"
      ;;
    VERSION_FILE_PATH)
      home="${HOME_DIR:-${HOME:-/home/steam}}"
      install="${INSTALL_PATH:-$home/enshrouded}"
      echo "$install/.current_version"
      ;;
    SAVEFILE_NAME)
      echo "${SAVEFILE_NAME:-3ad85aea}"
      ;;
    ENSHROUDED_BINARY)
      home="${HOME_DIR:-${HOME:-/home/steam}}"
      install="${INSTALL_PATH:-$home/enshrouded}"
      echo "$install/enshrouded_server.exe"
      ;;
    STOP_TIMEOUT)
      echo "${STOP_TIMEOUT:-60}"
      ;;
    RUN_DIR)
      echo "${RUN_DIR:-/var/run/enshrouded}"
      ;;
    REQUEST_DIR)
      run_dir="${RUN_DIR:-/var/run/enshrouded}"
      echo "$run_dir/requests"
      ;;
    PID_MANAGER_FILE)
      run_dir="${RUN_DIR:-/var/run/enshrouded}"
      echo "$run_dir/enshrouded-manager.pid"
      ;;
    PID_SERVER_FILE)
      run_dir="${RUN_DIR:-/var/run/enshrouded}"
      echo "$run_dir/enshrouded-server.pid"
      ;;
    PID_UPDATE_FILE)
      run_dir="${RUN_DIR:-/var/run/enshrouded}"
      echo "$run_dir/enshrouded-updater.pid"
      ;;
    PID_BACKUP_FILE)
      run_dir="${RUN_DIR:-/var/run/enshrouded}"
      echo "$run_dir/enshrouded-backup.pid"
      ;;
    STEAM_APP_ID)
      echo "${STEAM_APP_ID:-2278520}"
      ;;
    GAME_BRANCH)
      echo "${GAME_BRANCH:-public}"
      ;;
    STEAMCMD_ARGS)
      echo "${STEAMCMD_ARGS:-validate}"
      ;;
    STEAMCMD_PATH)
      home="${HOME_DIR:-${HOME:-/home/steam}}"
      echo "$home/steamcmd"
      ;;
    PROTON_CMD)
      echo "${PROTON_CMD:-/usr/local/bin/proton}"
      ;;
    WINESERVER_PATH)
      echo "${WINESERVER_PATH:-/usr/local/bin/files/bin/wineserver}"
      ;;
    STEAM_COMPAT_CLIENT_INSTALL_PATH)
      home="${HOME_DIR:-${HOME:-/home/steam}}"
      echo "$home/.steam/steam"
      ;;
    STEAM_COMPAT_DATA_PATH)
      home="${HOME_DIR:-${HOME:-/home/steam}}"
      install="${INSTALL_PATH:-$home/enshrouded}"
      app_id="${STEAM_APP_ID:-2278520}"
      echo "$install/steamapps/compatdata/$app_id"
      ;;
    WINEPREFIX)
      home="${HOME_DIR:-${HOME:-/home/steam}}"
      install="${INSTALL_PATH:-$home/enshrouded}"
      app_id="${STEAM_APP_ID:-2278520}"
      compat="${STEAM_COMPAT_DATA_PATH:-$install/steamapps/compatdata/$app_id}"
      echo "$compat/pfx"
      ;;
    WINEDEBUG)
      echo "${WINEDEBUG:--all}"
      ;;
    WINETRICKS)
      echo "${WINETRICKS:-/usr/local/bin/winetricks}"
      ;;
    AUTO_UPDATE)
      echo "${AUTO_UPDATE:-true}"
      ;;
    AUTO_UPDATE_INTERVAL)
      echo "${AUTO_UPDATE_INTERVAL:-1800}"
      ;;
    AUTO_UPDATE_ON_BOOT)
      echo "${AUTO_UPDATE_ON_BOOT:-true}"
      ;;
    AUTO_RESTART_ON_UPDATE)
      echo "${AUTO_RESTART_ON_UPDATE:-true}"
      ;;
    AUTO_RESTART)
      echo "${AUTO_RESTART:-true}"
      ;;
    AUTO_RESTART_DELAY)
      echo "${AUTO_RESTART_DELAY:-10}"
      ;;
    AUTO_RESTART_MAX_ATTEMPTS)
      echo "${AUTO_RESTART_MAX_ATTEMPTS:-0}"
      ;;
    SAFE_MODE)
      echo "${SAFE_MODE:-true}"
      ;;
    HEALTH_CHECK_INTERVAL)
      echo "${HEALTH_CHECK_INTERVAL:-300}"
      ;;
    HEALTH_CHECK_ON_START)
      echo "${HEALTH_CHECK_ON_START:-true}"
      ;;
    UPDATE_CHECK_PLAYERS)
      echo "${UPDATE_CHECK_PLAYERS:-false}"
      ;;
    RESTART_CHECK_PLAYERS)
      echo "${RESTART_CHECK_PLAYERS:-false}"
      ;;
    A2S_TIMEOUT)
      echo "${A2S_TIMEOUT:-2}"
      ;;
    A2S_RETRIES)
      echo "${A2S_RETRIES:-2}"
      ;;
    A2S_RETRY_DELAY)
      echo "${A2S_RETRY_DELAY:-1}"
      ;;
    LOG_TO_STDOUT)
      echo "${LOG_TO_STDOUT:-true}"
      ;;
    LOG_TAIL_LINES)
      echo "${LOG_TAIL_LINES:-200}"
      ;;
    LOG_POLL_INTERVAL)
      echo "${LOG_POLL_INTERVAL:-2}"
      ;;
    LOG_FILE_PATTERN)
      echo "${LOG_FILE_PATTERN:-*.log}"
      ;;
    LOG_STREAM_PID_FILE)
      run_dir="${RUN_DIR:-/var/run/enshrouded}"
      echo "$run_dir/enshrouded-logstream.pid"
      ;;
    LOG_STREAM_TAIL_PID_FILE)
      run_dir="${RUN_DIR:-/var/run/enshrouded}"
      echo "$run_dir/enshrouded-logtail.pid"
      ;;
    BACKUP_DIR)
      echo "${BACKUP_DIR:-backups}"
      ;;
    BACKUP_MAX_COUNT)
      echo "${BACKUP_MAX_COUNT:-0}"
      ;;
    BACKUP_PRE_HOOK)
      echo "${BACKUP_PRE_HOOK:-}"
      ;;
    BACKUP_POST_HOOK)
      echo "${BACKUP_POST_HOOK:-}"
      ;;
    ENABLE_CRON)
      echo "${ENABLE_CRON:-true}"
      ;;
    UPDATE_CRON)
      echo "${UPDATE_CRON:-}"
      ;;
    BACKUP_CRON)
      echo "${BACKUP_CRON:-}"
      ;;
    RESTART_CRON)
      echo "${RESTART_CRON:-}"
      ;;
    BOOTSTRAP_HOOK)
      echo "${BOOTSTRAP_HOOK:-}"
      ;;
    UPDATE_PRE_HOOK)
      echo "${UPDATE_PRE_HOOK:-}"
      ;;
    UPDATE_POST_HOOK)
      echo "${UPDATE_POST_HOOK:-}"
      ;;
    RESTART_PRE_HOOK)
      echo "${RESTART_PRE_HOOK:-}"
      ;;
    RESTART_POST_HOOK)
      echo "${RESTART_POST_HOOK:-}"
      ;;
    PRINT_ADMIN_PASSWORD)
      echo "${PRINT_ADMIN_PASSWORD:-true}"
      ;;
    *)
      echo ""
      ;;
  esac
}

apply_manager_env_overrides() {
  local file var raw value normalized
  file="$1"
  for var in "${MANAGER_VARS[@]}"; do
    if ! env_was_set "$var"; then
      continue
    fi
    raw="${!var-}"
    if ! validate_manager_value "$var" "$raw" "soft"; then
      MANAGER_ENV_IGNORE[$var]="true"
      printf -v "$var" '%s' ""
      continue
    fi
    value="$raw"
    if [[ "$var" == "LOG_LEVEL" && -n "$raw" ]]; then
      normalized="$(normalize_log_level "$raw")"
      value="$normalized"
      LOG_LEVEL="$normalized"
    fi
    MANAGER_EXPLICIT_VARS[$var]="true"
    manager_config_set_value "$file" "$var" "$value"
    printf -v "$var" '%s' "$value"
  done
}

load_manager_config_values() {
  local file var value normalized
  file="$1"
  for var in "${MANAGER_VARS[@]}"; do
    if env_was_set "$var"; then
      continue
    fi
    value="$(manager_json_get "$file" "$var")"
    if [[ -z "$value" ]]; then
      continue
    fi
    if ! validate_manager_value "$var" "$value" "soft"; then
      MANAGER_JSON_INVALID[$var]="true"
      continue
    fi
    if [[ "$var" == "LOG_LEVEL" ]]; then
      normalized="$(normalize_log_level "$value")"
      value="$normalized"
      manager_config_set_value "$file" "$var" "$value"
    fi
    MANAGER_EXPLICIT_VARS[$var]="true"
    printf -v "$var" '%s' "$value"
  done
}

apply_manager_defaults() {
  local file var value default normalized
  file="$1"
  for var in "${MANAGER_VARS[@]}"; do
    if [[ -n "${MANAGER_JSON_INVALID[$var]-}" ]]; then
      if [[ -n "${MANAGER_JSON_PATH[$var]-}" ]]; then
        manager_config_set "$file" "${MANAGER_JSON_PATH[$var]-} = null"
      fi
      value=""
    else
      value="$(manager_json_get "$file" "$var")"
      if [[ -n "$value" ]]; then
        continue
      fi
    fi
    default="$(manager_default_for_var "$var")"
    if [[ -z "$default" ]]; then
      manager_config_set "$file" "${MANAGER_JSON_PATH[$var]-} = null"
      printf -v "$var" '%s' ""
      continue
    fi
    if [[ "$var" == "LOG_LEVEL" ]]; then
      normalized="$(normalize_log_level "$default")"
      default="$normalized"
    fi
    manager_config_set_value "$file" "$var" "$default"
    printf -v "$var" '%s' "$default"
  done
}

validate_manager_json_values() {
  local file var value
  file="$1"
  for var in "${MANAGER_VARS[@]}"; do
    value="$(manager_json_get "$file" "$var")"
    if [[ -z "$value" ]]; then
      continue
    fi
    validate_manager_value "$var" "$value" "soft" || true
  done
}

ensure_manager_config_file() {
  local file
  file="$1"
  mkdir -p "$(dirname "$file")"
  if [[ ! -f "$file" ]]; then
    info "Creating initial server_manager.json"
    echo "{}" >"$file"
  fi
}

update_or_create_manager_config() {
  local file new_file
  require_cmd jq
  MANAGER_EXPLICIT_VARS=()
  MANAGER_ENV_IGNORE=()
  MANAGER_JSON_INVALID=()

  file="$(manager_config_path)"
  ensure_manager_config_file "$file"
  if ! jq -e '.' "$file" >/dev/null 2>&1; then
    fatal "Invalid JSON in $file"
  fi

  apply_manager_env_overrides "$file"
  load_manager_config_values "$file"

  new_file="$(manager_config_path)"
  if [[ "$new_file" != "$file" ]]; then
    file="$new_file"
    ensure_manager_config_file "$file"
    if ! jq -e '.' "$file" >/dev/null 2>&1; then
      fatal "Invalid JSON in $file"
    fi
    MANAGER_EXPLICIT_VARS=()
    MANAGER_JSON_INVALID=()
    apply_manager_env_overrides "$file"
    load_manager_config_values "$file"
  fi

  apply_manager_defaults "$file"
  load_manager_config_values "$file"
  validate_manager_json_values "$file"
  MANAGER_CONFIG_FILE="$file"
}

validate_tags() {
  local tag_list tag trimmed
  tag_list="$1"
  IFS=',' read -r -a tags <<<"$tag_list"
  for tag in "${tags[@]}"; do
    trimmed="$(echo "$tag" | xargs)"
    if [[ -z "$trimmed" ]]; then
      warn "ENSHROUDED_TAGS contains an empty tag"
      return 1
    fi
    if ! [[ "$trimmed" =~ ^[A-Za-z0-9._-]+$ ]]; then
      warn "ENSHROUDED_TAGS contains invalid tag: $trimmed"
      return 1
    fi
  done
  return 0
}

validate_core_json_values() {
  local qp sc tags t
  qp="$(jq -r '.queryPort // empty' "$CONFIG_FILE" 2>/dev/null || true)"
  if [[ -n "$qp" ]]; then
    if ! [[ "$qp" =~ ^[0-9]+$ ]] || [[ "$qp" -lt 1 ]] || [[ "$qp" -gt 65535 ]]; then
      warn "queryPort in JSON is invalid (actual: $qp)"
    fi
  fi

  sc="$(jq -r '.slotCount // empty' "$CONFIG_FILE" 2>/dev/null || true)"
  if [[ -n "$sc" ]]; then
    if ! [[ "$sc" =~ ^[0-9]+$ ]] || [[ "$sc" -lt 1 ]] || [[ "$sc" -gt 16 ]]; then
      warn "slotCount in JSON is invalid (actual: $sc)"
    fi
  fi

  if jq -e '.tags != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    tags="$(jq -r '.tags[]?' "$CONFIG_FILE" 2>/dev/null || true)"
    if [[ -n "$tags" ]]; then
      while read -r t; do
        if [[ -z "$t" ]]; then
          warn "tags in JSON contains empty value"
          continue
        fi
        if ! [[ "$t" =~ ^[A-Za-z0-9._-]+$ ]]; then
          warn "tags in JSON contains invalid tag: $t"
        fi
      done <<<"$tags"
    fi
  fi
}

ensure_core_defaults() {
  if ! jq -e '.name != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    debug "Applied default name=Enshrouded Server"
    config_set --arg name "Enshrouded Server" '.name = $name'
  fi

  if ! jq -e '.saveDirectory != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    debug "Applied default saveDirectory=./savegame"
    config_set --arg saveDirectory "./savegame" '.saveDirectory = $saveDirectory'
  fi

  if ! jq -e '.logDirectory != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    debug "Applied default logDirectory=./logs"
    config_set --arg logDirectory "./logs" '.logDirectory = $logDirectory'
  fi

  if ! jq -e '.ip != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    debug "Applied default ip=0.0.0.0"
    config_set --arg ip "0.0.0.0" '.ip = $ip'
  fi

  if ! jq -e '.queryPort != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    debug "Applied default queryPort=15637"
    config_set --argjson queryPort 15637 '.queryPort = $queryPort'
  fi

  if ! jq -e '.slotCount != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    debug "Applied default slotCount=16"
    config_set --argjson slotCount 16 '.slotCount = $slotCount'
  fi

  if ! jq -e '.tags != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    debug "Applied default tags=[]"
    config_set '.tags = []'
  fi

  if ! jq -e '.voiceChatMode != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    debug "Applied default voiceChatMode=Proximity"
    config_set --arg voiceChatMode "Proximity" '.voiceChatMode = $voiceChatMode'
  fi

  if ! jq -e '.enableVoiceChat != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    debug "Applied default enableVoiceChat=false"
    config_set --argjson enableVoiceChat false '.enableVoiceChat = $enableVoiceChat'
  fi

  if ! jq -e '.enableTextChat != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    debug "Applied default enableTextChat=false"
    config_set --argjson enableTextChat false '.enableTextChat = $enableTextChat'
  fi
}

gs_default_for_suffix() {
  case "$1" in
    PRESET) echo "Default" ;;
    PLAYER_HEALTH_FACTOR) echo "1" ;;
    PLAYER_MANA_FACTOR) echo "1" ;;
    PLAYER_STAMINA_FACTOR) echo "1" ;;
    PLAYER_BODY_HEAT_FACTOR) echo "1" ;;
    PLAYER_DIVING_TIME_FACTOR) echo "1" ;;
    ENABLE_DURABILITY) echo "true" ;;
    ENABLE_STARVING_DEBUFF) echo "false" ;;
    FOOD_BUFF_DURATION_FACTOR) echo "1" ;;
    FROM_HUNGER_TO_STARVING) echo "600000000000" ;;
    SHROUD_TIME_FACTOR) echo "1" ;;
    TOMBSTONE_MODE) echo "AddBackpackMaterials" ;;
    ENABLE_GLIDER_TURBULENCES) echo "true" ;;
    WEATHER_FREQUENCY) echo "Normal" ;;
    FISHING_DIFFICULTY) echo "Normal" ;;
    MINING_DAMAGE_FACTOR) echo "1" ;;
    PLANT_GROWTH_SPEED_FACTOR) echo "1" ;;
    RESOURCE_DROP_STACK_AMOUNT_FACTOR) echo "1" ;;
    FACTORY_PRODUCTION_SPEED_FACTOR) echo "1" ;;
    PERK_UPGRADE_RECYCLING_FACTOR) echo "0.5" ;;
    PERK_COST_FACTOR) echo "1" ;;
    EXPERIENCE_COMBAT_FACTOR) echo "1" ;;
    EXPERIENCE_MINING_FACTOR) echo "1" ;;
    EXPERIENCE_EXPLORATION_QUESTS_FACTOR) echo "1" ;;
    RANDOM_SPAWNER_AMOUNT) echo "Normal" ;;
    AGGRO_POOL_AMOUNT) echo "Normal" ;;
    ENEMY_DAMAGE_FACTOR) echo "1" ;;
    ENEMY_HEALTH_FACTOR) echo "1" ;;
    ENEMY_STAMINA_FACTOR) echo "1" ;;
    ENEMY_PERCEPTION_RANGE_FACTOR) echo "1" ;;
    BOSS_DAMAGE_FACTOR) echo "1" ;;
    BOSS_HEALTH_FACTOR) echo "1" ;;
    THREAT_BONUS) echo "1" ;;
    PACIFY_ALL_ENEMIES) echo "false" ;;
    TAMING_STARTLE_REPERCUSSION) echo "LoseSomeProgress" ;;
    DAY_TIME_DURATION) echo "1800000000000" ;;
    NIGHT_TIME_DURATION) echo "720000000000" ;;
    CURSE_MODIFIER) echo "Normal" ;;
    *) echo "" ;;
  esac
}

apply_game_setting() {
  local suffix value jq_key_name full_jq_path jq_arg_option temp_json_file
  suffix="$1"
  value="$2"

  jq_key_name=$(echo "$suffix" | tr '[:upper:]' '[:lower:]' | awk -F_ '{for(i=1;i<=NF;i++){if(i==1){out=$i}else{out=out toupper(substr($i,1,1)) substr($i,2)}}}END{print out}')

  if [[ "$suffix" == "PRESET" ]]; then
    full_jq_path=".gameSettingsPreset"
    jq_arg_option="--arg"
  else
    full_jq_path=".gameSettings.$jq_key_name"
    if [[ "$value" == "true" || "$value" == "false" || "$value" =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]]; then
      jq_arg_option="--argjson"
    else
      jq_arg_option="--arg"
    fi
  fi

  temp_json_file="$(mktemp)"
  if jq "$jq_arg_option" val "$value" "$full_jq_path = \$val" "$CONFIG_FILE" >"$temp_json_file"; then
    mv "$temp_json_file" "$CONFIG_FILE"
  else
    warn "Failed to update ENSHROUDED_GS_${suffix} in $CONFIG_FILE"
    rm -f "$temp_json_file"
  fi
}

validate_game_setting() {
  local suffix value name
  suffix="$1"
  value="$2"
  name="ENSHROUDED_GS_${suffix}"

  case "$suffix" in
    PRESET)
      validate_enum_soft "$name" "$value" Default Relaxed Hard Survival Custom
      ;;
    PLAYER_HEALTH_FACTOR)
      validate_number_range_soft "$name" "$value" 0.25 4
      ;;
    PLAYER_MANA_FACTOR)
      validate_number_range_soft "$name" "$value" 0.25 4
      ;;
    PLAYER_STAMINA_FACTOR)
      validate_number_range_soft "$name" "$value" 0.25 4
      ;;
    PLAYER_BODY_HEAT_FACTOR)
      validate_enum_soft "$name" "$value" 0.5 1 1.5 2
      ;;
    PLAYER_DIVING_TIME_FACTOR)
      validate_number_range_soft "$name" "$value" 0.5 2
      ;;
    ENABLE_DURABILITY|ENABLE_STARVING_DEBUFF|ENABLE_GLIDER_TURBULENCES|PACIFY_ALL_ENEMIES)
      validate_bool_soft "$name" "$value"
      ;;
    FOOD_BUFF_DURATION_FACTOR)
      validate_number_range_soft "$name" "$value" 0.5 2
      ;;
    FROM_HUNGER_TO_STARVING)
      validate_number_range_soft "$name" "$value" 300000000000 1200000000000
      ;;
    SHROUD_TIME_FACTOR)
      validate_number_range_soft "$name" "$value" 0.5 2
      ;;
    TOMBSTONE_MODE)
      validate_enum_soft "$name" "$value" AddBackpackMaterials Everything NoTombstone
      ;;
    WEATHER_FREQUENCY)
      validate_enum_soft "$name" "$value" Disabled Rare Normal Often
      ;;
    FISHING_DIFFICULTY)
      validate_enum_soft "$name" "$value" VeryEasy Easy Normal Hard VeryHard
      ;;
    MINING_DAMAGE_FACTOR)
      validate_number_range_soft "$name" "$value" 0.5 2
      ;;
    PLANT_GROWTH_SPEED_FACTOR)
      validate_number_range_soft "$name" "$value" 0.25 2
      ;;
    RESOURCE_DROP_STACK_AMOUNT_FACTOR)
      validate_number_range_soft "$name" "$value" 0.25 2
      ;;
    FACTORY_PRODUCTION_SPEED_FACTOR)
      validate_number_range_soft "$name" "$value" 0.25 2
      ;;
    PERK_UPGRADE_RECYCLING_FACTOR)
      validate_number_range_soft "$name" "$value" 0 1
      ;;
    PERK_COST_FACTOR)
      validate_number_range_soft "$name" "$value" 0.25 2
      ;;
    EXPERIENCE_COMBAT_FACTOR)
      validate_number_range_soft "$name" "$value" 0.25 2
      ;;
    EXPERIENCE_MINING_FACTOR)
      validate_number_range_soft "$name" "$value" 0 2
      ;;
    EXPERIENCE_EXPLORATION_QUESTS_FACTOR)
      validate_number_range_soft "$name" "$value" 0.25 2
      ;;
    RANDOM_SPAWNER_AMOUNT)
      validate_enum_soft "$name" "$value" Few Normal Many Extreme
      ;;
    AGGRO_POOL_AMOUNT)
      validate_enum_soft "$name" "$value" Few Normal Many Extreme
      ;;
    ENEMY_DAMAGE_FACTOR)
      validate_number_range_soft "$name" "$value" 0.25 5
      ;;
    ENEMY_HEALTH_FACTOR)
      validate_number_range_soft "$name" "$value" 0.25 4
      ;;
    ENEMY_STAMINA_FACTOR)
      validate_number_range_soft "$name" "$value" 0.5 2
      ;;
    ENEMY_PERCEPTION_RANGE_FACTOR)
      validate_number_range_soft "$name" "$value" 0.5 2
      ;;
    BOSS_DAMAGE_FACTOR)
      validate_number_range_soft "$name" "$value" 0.2 5
      ;;
    BOSS_HEALTH_FACTOR)
      validate_number_range_soft "$name" "$value" 0.2 5
      ;;
    THREAT_BONUS)
      validate_number_range_soft "$name" "$value" 0.25 4
      ;;
    TAMING_STARTLE_REPERCUSSION)
      validate_enum_soft "$name" "$value" KeepProgress LoseSomeProgress LoseAllProgress
      ;;
    DAY_TIME_DURATION)
      validate_number_range_soft "$name" "$value" 120000000000 3600000000000
      ;;
    NIGHT_TIME_DURATION)
      validate_number_range_soft "$name" "$value" 120000000000 3600000000000
      ;;
    CURSE_MODIFIER)
      validate_enum_soft "$name" "$value" Easy Normal Hard
      ;;
    *)
      warn "Unknown game setting: $name"
      return 1
      ;;
  esac
}

verify_variables() {
  if [[ -n "$ENSHROUDED_SLOT_COUNT" ]]; then
    if [[ ! "$ENSHROUDED_SLOT_COUNT" =~ ^[0-9]+$ ]] || [[ "$ENSHROUDED_SLOT_COUNT" -lt 1 ]] || [[ "$ENSHROUDED_SLOT_COUNT" -gt 16 ]]; then
      fatal "ENSHROUDED_SLOT_COUNT must be between 1 and 16 (actual: $ENSHROUDED_SLOT_COUNT)"
    fi
  fi

  if [[ -n "$ENSHROUDED_QUERY_PORT" ]]; then
    if [[ ! "$ENSHROUDED_QUERY_PORT" =~ ^[0-9]+$ ]] || [[ "$ENSHROUDED_QUERY_PORT" -lt 1 ]] || [[ "$ENSHROUDED_QUERY_PORT" -gt 65535 ]]; then
      fatal "ENSHROUDED_QUERY_PORT must be between 1 and 65535 (actual: $ENSHROUDED_QUERY_PORT)"
    fi
  fi

  if [[ -n "$ENSHROUDED_IP" ]]; then
    if ! [[ "$ENSHROUDED_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      fatal "ENSHROUDED_IP must be a valid ipv4 address (actual: $ENSHROUDED_IP)"
    fi
  fi

  if [[ -n "$ENSHROUDED_VOICE_CHAT_MODE" ]]; then
    validate_enum "ENSHROUDED_VOICE_CHAT_MODE" "$ENSHROUDED_VOICE_CHAT_MODE" Proximity Global
  fi

  validate_bool "ENSHROUDED_ENABLE_VOICE_CHAT" "$ENSHROUDED_ENABLE_VOICE_CHAT"
  validate_bool "ENSHROUDED_ENABLE_TEXT_CHAT" "$ENSHROUDED_ENABLE_TEXT_CHAT"

  if [[ -n "${PUID:-}" ]] && ! [[ "$PUID" =~ ^[0-9]+$ ]]; then
    fatal "PUID must be numeric (actual: $PUID)"
  fi

  if [[ -n "${PGID:-}" ]] && ! [[ "$PGID" =~ ^[0-9]+$ ]]; then
    fatal "PGID must be numeric (actual: $PGID)"
  fi

  if [[ -n "${UPDATE_CHECK_PLAYERS:-}" ]] && [[ "$UPDATE_CHECK_PLAYERS" != "true" ]] && [[ "$UPDATE_CHECK_PLAYERS" != "false" ]]; then
    fatal "UPDATE_CHECK_PLAYERS must be true or false (actual: $UPDATE_CHECK_PLAYERS)"
  fi

  if [[ -n "${RESTART_CHECK_PLAYERS:-}" ]] && [[ "$RESTART_CHECK_PLAYERS" != "true" ]] && [[ "$RESTART_CHECK_PLAYERS" != "false" ]]; then
    fatal "RESTART_CHECK_PLAYERS must be true or false (actual: $RESTART_CHECK_PLAYERS)"
  fi
}

ensure_base_dirs() {
  mkdir -p "$INSTALL_PATH" "$RUN_DIR" "$REQUEST_DIR"
}

create_folders() {
  local save_dir log_dir backup_dir
  if [[ -n "$ENSHROUDED_SAVE_DIR" ]]; then
    save_dir="$(abs_path "$ENSHROUDED_SAVE_DIR")"
  elif command -v jq >/dev/null 2>&1 && [[ -f "$CONFIG_FILE" ]]; then
    save_dir="$(abs_path "$(jq -r '.saveDirectory // "./savegame"' "$CONFIG_FILE" 2>/dev/null || echo "./savegame")")"
  else
    save_dir="$(abs_path "./savegame")"
  fi

  if [[ -n "$ENSHROUDED_LOG_DIR" ]]; then
    log_dir="$(abs_path "$ENSHROUDED_LOG_DIR")"
  elif command -v jq >/dev/null 2>&1 && [[ -f "$CONFIG_FILE" ]]; then
    log_dir="$(abs_path "$(jq -r '.logDirectory // "./logs"' "$CONFIG_FILE" 2>/dev/null || echo "./logs")")"
  else
    log_dir="$(abs_path "./logs")"
  fi

  backup_dir="$(abs_path "$BACKUP_DIR")"

  mkdir -p "$save_dir" "$log_dir" "$backup_dir"
}

ensure_steam_paths() {
  mkdir -p "$WINEPREFIX" "$STEAM_COMPAT_DATA_PATH" "$STEAM_COMPAT_CLIENT_INSTALL_PATH"
  mkdir -p "$HOME_DIR/.steam" "$HOME_DIR/.steam/sdk32" "$HOME_DIR/.steam/sdk64"
}

create_default_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    return 0
  fi

  info "Creating initial enshrouded_server.json"

  local admin_pw friend_pw guest_pw visitor_pw
  admin_pw="$(generate_password)"
  friend_pw="$(generate_password)"
  guest_pw="$(generate_password)"
  visitor_pw="$(generate_password)"

  cat <<EOF >"$CONFIG_FILE"
{
  "name": "Enshrouded Server",
  "saveDirectory": "./savegame",
  "logDirectory": "./logs",
  "ip": "0.0.0.0",
  "queryPort": 15637,
  "slotCount": 16,
  "tags": [],
  "voiceChatMode": "Proximity",
  "enableVoiceChat": false,
  "enableTextChat": false,
  "gameSettingsPreset": "Default",
  "gameSettings": {
    "playerHealthFactor": 1,
    "playerManaFactor": 1,
    "playerStaminaFactor": 1,
    "playerBodyHeatFactor": 1,
    "playerDivingTimeFactor": 1,
    "enableDurability": true,
    "enableStarvingDebuff": false,
    "foodBuffDurationFactor": 1,
    "fromHungerToStarving": 600000000000,
    "shroudTimeFactor": 1,
    "tombstoneMode": "AddBackpackMaterials",
    "enableGliderTurbulences": true,
    "weatherFrequency": "Normal",
    "fishingDifficulty": "Normal",
    "miningDamageFactor": 1,
    "plantGrowthSpeedFactor": 1,
    "resourceDropStackAmountFactor": 1,
    "factoryProductionSpeedFactor": 1,
    "perkUpgradeRecyclingFactor": 0.5,
    "perkCostFactor": 1,
    "experienceCombatFactor": 1,
    "experienceMiningFactor": 1,
    "experienceExplorationQuestsFactor": 1,
    "randomSpawnerAmount": "Normal",
    "aggroPoolAmount": "Normal",
    "enemyDamageFactor": 1,
    "enemyHealthFactor": 1,
    "enemyStaminaFactor": 1,
    "enemyPerceptionRangeFactor": 1,
    "bossDamageFactor": 1,
    "bossHealthFactor": 1,
    "threatBonus": 1,
    "pacifyAllEnemies": false,
    "tamingStartleRepercussion": "LoseSomeProgress",
    "dayTimeDuration": 1800000000000,
    "nightTimeDuration": 720000000000,
    "curseModifier": "Normal"
  },
  "userGroups": [
    {
      "name": "Admin",
      "password": "${admin_pw}",
      "canKickBan": true,
      "canAccessInventories": true,
      "canEditWorld": true,
      "canEditBase": true,
      "canExtendBase": true,
      "reservedSlots": 0
    },
    {
      "name": "Friend",
      "password": "${friend_pw}",
      "canKickBan": false,
      "canAccessInventories": true,
      "canEditWorld": true,
      "canEditBase": true,
      "canExtendBase": false,
      "reservedSlots": 0
    },
    {
      "name": "Guest",
      "password": "${guest_pw}",
      "canKickBan": false,
      "canAccessInventories": false,
      "canEditWorld": true,
      "canEditBase": false,
      "canExtendBase": false,
      "reservedSlots": 0
    },
    {
      "name": "Visitor",
      "password": "${visitor_pw}",
      "canKickBan": false,
      "canAccessInventories": false,
      "canEditWorld": false,
      "canEditBase": false,
      "canExtendBase": false,
      "reservedSlots": 0
    }
  ],
  "bans": []
}
EOF

  chmod 600 "$CONFIG_FILE" 2>/dev/null || true
  info "enshrouded_server.json created"
  if is_true "$PRINT_ADMIN_PASSWORD"; then
    info "Admin password: $admin_pw"
  fi
}

config_set() {
  local temp_file
  temp_file="$(mktemp)"
  if jq "$@" "$CONFIG_FILE" >"$temp_file"; then
    mv "$temp_file" "$CONFIG_FILE"
  else
    rm -f "$temp_file"
    fatal "Failed to update $CONFIG_FILE (jq error)"
  fi
}

update_or_create_config() {
  log_context_push "config"
  create_default_config
  require_cmd jq

  if [[ -n "$ENSHROUDED_NAME" ]]; then
    debug "Applied ENSHROUDED_NAME=$ENSHROUDED_NAME"
    config_set --arg name "$ENSHROUDED_NAME" '.name = $name'
  fi

  if [[ -n "$ENSHROUDED_SAVE_DIR" ]]; then
    debug "Applied ENSHROUDED_SAVE_DIR=$ENSHROUDED_SAVE_DIR"
    config_set --arg saveDirectory "$ENSHROUDED_SAVE_DIR" '.saveDirectory = $saveDirectory'
  fi

  if [[ -n "$ENSHROUDED_LOG_DIR" ]]; then
    debug "Applied ENSHROUDED_LOG_DIR=$ENSHROUDED_LOG_DIR"
    config_set --arg logDirectory "$ENSHROUDED_LOG_DIR" '.logDirectory = $logDirectory'
  fi

  if [[ -n "$ENSHROUDED_IP" ]]; then
    debug "Applied ENSHROUDED_IP=$ENSHROUDED_IP"
    config_set --arg ip "$ENSHROUDED_IP" '.ip = $ip'
  fi

  if [[ -n "$ENSHROUDED_QUERY_PORT" ]]; then
    debug "Applied ENSHROUDED_QUERY_PORT=$ENSHROUDED_QUERY_PORT"
    config_set --argjson queryPort "$ENSHROUDED_QUERY_PORT" '.queryPort = $queryPort'
  fi

  if [[ -n "$ENSHROUDED_SLOT_COUNT" ]]; then
    debug "Applied ENSHROUDED_SLOT_COUNT=$ENSHROUDED_SLOT_COUNT"
    config_set --argjson slotCount "$ENSHROUDED_SLOT_COUNT" '.slotCount = $slotCount'
  fi

  if [[ -n "$ENSHROUDED_VOICE_CHAT_MODE" ]]; then
    debug "Applied ENSHROUDED_VOICE_CHAT_MODE=$ENSHROUDED_VOICE_CHAT_MODE"
    config_set --arg voiceChatMode "$ENSHROUDED_VOICE_CHAT_MODE" '.voiceChatMode = $voiceChatMode'
  fi

  if [[ -n "$ENSHROUDED_ENABLE_VOICE_CHAT" ]]; then
    debug "Applied ENSHROUDED_ENABLE_VOICE_CHAT=$ENSHROUDED_ENABLE_VOICE_CHAT"
    config_set --argjson enableVoiceChat "$ENSHROUDED_ENABLE_VOICE_CHAT" '.enableVoiceChat = $enableVoiceChat'
  fi

  if [[ -n "$ENSHROUDED_ENABLE_TEXT_CHAT" ]]; then
    debug "Applied ENSHROUDED_ENABLE_TEXT_CHAT=$ENSHROUDED_ENABLE_TEXT_CHAT"
    config_set --argjson enableTextChat "$ENSHROUDED_ENABLE_TEXT_CHAT" '.enableTextChat = $enableTextChat'
  fi

  if [[ -n "$ENSHROUDED_TAGS" ]]; then
    if validate_tags "$ENSHROUDED_TAGS"; then
      debug "Applied ENSHROUDED_TAGS=$ENSHROUDED_TAGS"
      config_set --arg tags "$ENSHROUDED_TAGS" '.tags = ($tags | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length>0)))'
    else
      warn "ENSHROUDED_TAGS invalid; keeping existing value"
    fi
  fi

  ensure_core_defaults
  update_user_group_config
  update_game_settings_config
  validate_core_json_values
  log_context_pop
}

update_user_group_config() {
  local group_count
  group_count=$(compgen -A variable | grep -E "^ENSHROUDED_ROLE_[0-9]+_" | cut -d'_' -f3 | sort -nr | head -n1 || true)

  if ! jq -e 'has("userGroups")' "$CONFIG_FILE" >/dev/null; then
    config_set '.userGroups = []'
  fi

  if [[ -n "${group_count:-}" ]]; then
    local group_index
    for group_index in $(seq 0 "$group_count"); do
      if ! jq -e --argjson group_index "$group_index" '.userGroups | has($group_index)' "$CONFIG_FILE" >/dev/null; then
        config_set '.userGroups += [{"name": "Default", "password": "", "canKickBan": false, "canAccessInventories": false, "canEditWorld": false, "canEditBase": false, "canExtendBase": false, "reservedSlots": 0}]'
      fi
    done
  fi

  local var_name group_index group_param group_value
  for var_name in $(compgen -A variable | grep -E "^ENSHROUDED_ROLE_[0-9]+_" || true); do
    group_index="$(echo "$var_name" | cut -d'_' -f3)"
    group_param="$(echo "$var_name" | cut -d'_' -f4-)"
    group_value="$(eval echo "\$$var_name")"

    case "$group_param" in
      NAME)
        debug "Applied ENSHROUDED_ROLE_${group_index}_NAME=$group_value"
        config_set --argjson group_index "$group_index" --arg name "$group_value" '.userGroups[$group_index].name = $name'
        ;;
      PASSWORD)
        debug "Applied ENSHROUDED_ROLE_${group_index}_PASSWORD=***"
        config_set --argjson group_index "$group_index" --arg password "$group_value" '.userGroups[$group_index].password = $password'
        ;;
      CAN_KICK_BAN)
        validate_bool "ENSHROUDED_ROLE_${group_index}_CAN_KICK_BAN" "$group_value"
        debug "Applied ENSHROUDED_ROLE_${group_index}_CAN_KICK_BAN=$group_value"
        config_set --argjson group_index "$group_index" --argjson canKickBan "$group_value" '.userGroups[$group_index].canKickBan = $canKickBan'
        ;;
      CAN_ACCESS_INVENTORIES)
        validate_bool "ENSHROUDED_ROLE_${group_index}_CAN_ACCESS_INVENTORIES" "$group_value"
        debug "Applied ENSHROUDED_ROLE_${group_index}_CAN_ACCESS_INVENTORIES=$group_value"
        config_set --argjson group_index "$group_index" --argjson canAccessInventories "$group_value" '.userGroups[$group_index].canAccessInventories = $canAccessInventories'
        ;;
      CAN_EDIT_WORLD)
        validate_bool "ENSHROUDED_ROLE_${group_index}_CAN_EDIT_WORLD" "$group_value"
        debug "Applied ENSHROUDED_ROLE_${group_index}_CAN_EDIT_WORLD=$group_value"
        config_set --argjson group_index "$group_index" --argjson canEditWorld "$group_value" '.userGroups[$group_index].canEditWorld = $canEditWorld'
        ;;
      CAN_EDIT_BASE)
        validate_bool "ENSHROUDED_ROLE_${group_index}_CAN_EDIT_BASE" "$group_value"
        debug "Applied ENSHROUDED_ROLE_${group_index}_CAN_EDIT_BASE=$group_value"
        config_set --argjson group_index "$group_index" --argjson canEditBase "$group_value" '.userGroups[$group_index].canEditBase = $canEditBase'
        ;;
      CAN_EXTEND_BASE)
        validate_bool "ENSHROUDED_ROLE_${group_index}_CAN_EXTEND_BASE" "$group_value"
        debug "Applied ENSHROUDED_ROLE_${group_index}_CAN_EXTEND_BASE=$group_value"
        config_set --argjson group_index "$group_index" --argjson canExtendBase "$group_value" '.userGroups[$group_index].canExtendBase = $canExtendBase'
        ;;
      RESERVED_SLOTS)
        if [[ ! "$group_value" =~ ^[0-9]+$ ]]; then
          fatal "ENSHROUDED_ROLE_${group_index}_RESERVED_SLOTS must be numeric (actual: $group_value)"
        fi
        debug "Applied ENSHROUDED_ROLE_${group_index}_RESERVED_SLOTS=$group_value"
        config_set --argjson group_index "$group_index" --argjson reservedSlots "$group_value" '.userGroups[$group_index].reservedSlots = $reservedSlots'
        ;;
    esac
  done
}

update_game_settings_config() {
  local suffix var_name var_value jq_key_name full_jq_path
  local gs_keys
  local missing_keys
  local allowed_vars
  local default_value
  missing_keys=()
  allowed_vars=""
  gs_keys=(
    PRESET
    PLAYER_HEALTH_FACTOR
    PLAYER_MANA_FACTOR
    PLAYER_STAMINA_FACTOR
    PLAYER_BODY_HEAT_FACTOR
    PLAYER_DIVING_TIME_FACTOR
    ENABLE_DURABILITY
    ENABLE_STARVING_DEBUFF
    FOOD_BUFF_DURATION_FACTOR
    FROM_HUNGER_TO_STARVING
    SHROUD_TIME_FACTOR
    TOMBSTONE_MODE
    ENABLE_GLIDER_TURBULENCES
    WEATHER_FREQUENCY
    FISHING_DIFFICULTY
    MINING_DAMAGE_FACTOR
    PLANT_GROWTH_SPEED_FACTOR
    RESOURCE_DROP_STACK_AMOUNT_FACTOR
    FACTORY_PRODUCTION_SPEED_FACTOR
    PERK_UPGRADE_RECYCLING_FACTOR
    PERK_COST_FACTOR
    EXPERIENCE_COMBAT_FACTOR
    EXPERIENCE_MINING_FACTOR
    EXPERIENCE_EXPLORATION_QUESTS_FACTOR
    RANDOM_SPAWNER_AMOUNT
    AGGRO_POOL_AMOUNT
    ENEMY_DAMAGE_FACTOR
    ENEMY_HEALTH_FACTOR
    ENEMY_STAMINA_FACTOR
    ENEMY_PERCEPTION_RANGE_FACTOR
    BOSS_DAMAGE_FACTOR
    BOSS_HEALTH_FACTOR
    THREAT_BONUS
    PACIFY_ALL_ENEMIES
    TAMING_STARTLE_REPERCUSSION
    DAY_TIME_DURATION
    NIGHT_TIME_DURATION
    CURSE_MODIFIER
  )

  for suffix in "${gs_keys[@]}"; do
    var_name="ENSHROUDED_GS_${suffix}"
    allowed_vars="${allowed_vars} ${var_name}"
    var_value="${!var_name:-}"

    if [[ "$suffix" == "PRESET" ]]; then
      full_jq_path=".gameSettingsPreset"
    else
      jq_key_name=$(echo "$suffix" | tr '[:upper:]' '[:lower:]' | awk -F_ '{for(i=1;i<=NF;i++){if(i==1){out=$i}else{out=out toupper(substr($i,1,1)) substr($i,2)}}}END{print out}')
      full_jq_path=".gameSettings.$jq_key_name"
    fi

    if [[ -z "$var_value" ]]; then
      if ! json_has_value "$full_jq_path"; then
        default_value="$(gs_default_for_suffix "$suffix")"
        if [[ -n "$default_value" ]] && validate_game_setting "$suffix" "$default_value"; then
          debug "Applied default $var_name=$default_value"
          apply_game_setting "$suffix" "$default_value"
        fi
      else
        missing_keys+=("$var_name")
      fi
      continue
    fi

    if ! validate_game_setting "$suffix" "$var_value"; then
      warn "$var_name invalid; keeping existing value"
      continue
    fi

    debug "Applied $var_name=$var_value"
    apply_game_setting "$suffix" "$var_value"
  done

  if [[ "${#missing_keys[@]}" -gt 0 ]]; then
    debug "Game settings not set (using existing values): ${missing_keys[*]}"
  fi

  local unknown_vars pattern
  pattern="^($(echo "$allowed_vars" | xargs | sed 's/ /|/g'))$"
  if [[ -n "$pattern" ]]; then
    unknown_vars="$(compgen -A variable | grep '^ENSHROUDED_GS_' | grep -v -E "$pattern" || true)"
  fi
  if [[ -n "$unknown_vars" ]]; then
    warn "Unknown game setting env vars detected: $(echo "$unknown_vars" | xargs)"
  fi
}

bootstrap_hook() {
  if [[ -n "${BOOTSTRAP_HOOK:-}" ]]; then
    info "Running bootstrap hook: $BOOTSTRAP_HOOK"
    eval "$BOOTSTRAP_HOOK"
  fi
}

prepare_a2s_library() {
  if ! command -v python3 >/dev/null 2>&1; then
    warn "python3 not available, skipping A2S library install"
    return
  fi
  if python3 -c "import a2s" >/dev/null 2>&1; then
    return
  fi
  if ! command -v pip3 >/dev/null 2>&1; then
    warn "pip3 not available, cannot install python-a2s"
    return
  fi
  info "Installing python-a2s for player checks"
  pip3 install python-a2s==1.3.0 --break-system-packages >/dev/null 2>&1 || warn "Failed to install python-a2s"
}

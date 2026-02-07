#!/usr/bin/env bash

# Config and setup helpers.
#
# Supported ENV (ENSHROUDED_ prefix):
# Profile:
#   EN_PROFILE
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
EN_PROFILE="${EN_PROFILE:-}"
MANAGER_PROFILE="${MANAGER_PROFILE:-}"

EN_PROFILE_DEFAULT="default"
EN_PROFILE_DIR="${MANAGER_ROOT:-/opt/enshrouded/manager}/profiles_enshrouded"
EN_CONFIG_CREATED="false"

MANAGER_PROFILE_DEFAULT="default"
MANAGER_DATA_DIR="/server_manager"
MANAGER_PROFILE_ROOT="/profile"
MANAGER_PROFILE_DIR="$MANAGER_PROFILE_ROOT"
MANAGER_PROFILE_TEMPLATE_DIR="${MANAGER_PROFILE_TEMPLATE_DIR:-${MANAGER_ROOT:-/opt/enshrouded/manager}/profiles}"

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
  printf "%s/server_manager.json" "$MANAGER_DATA_DIR"
}

enshrouded_profile_path() {
  local name
  name="${1:-$EN_PROFILE_DEFAULT}"
  printf "%s/%s/enshrouded_server.json" "$EN_PROFILE_DIR" "$name"
}

enshrouded_profile_resolve() {
  local name
  name="${EN_PROFILE:-}"
  if [[ -z "$name" ]]; then
    echo "$EN_PROFILE_DEFAULT"
    return 0
  fi
  if [[ -f "$(enshrouded_profile_path "$name")" ]]; then
    echo "$name"
    return 0
  fi
  warn "Enshrouded profile not found: $name (fallback: $EN_PROFILE_DEFAULT)" >&2
  echo "$EN_PROFILE_DEFAULT"
}

manager_profile_path() {
  local name
  name="${1:-$MANAGER_PROFILE_DEFAULT}"
  printf "%s/%s/server_manager.json" "$MANAGER_PROFILE_DIR" "$name"
}

manager_profile_template_path() {
  local name
  name="${1:-$MANAGER_PROFILE_DEFAULT}"
  printf "%s/%s.json" "$MANAGER_PROFILE_TEMPLATE_DIR" "$name"
}

manager_profile_resolve() {
  local name
  name="${MANAGER_PROFILE:-}"
  if [[ -z "$name" ]]; then
    echo "$MANAGER_PROFILE_DEFAULT"
    return 0
  fi
  if [[ -f "$(manager_profile_path "$name")" || -f "$(manager_profile_template_path "$name")" ]]; then
    echo "$name"
    return 0
  fi
  warn "Profile not found: $name (fallback: $MANAGER_PROFILE_DEFAULT)" >&2
  echo "$MANAGER_PROFILE_DEFAULT"
}

ensure_manager_paths() {
  local data_link profile_link data_target profile_target data_real target_real profile_real profile_target_real
  data_link="$MANAGER_DATA_DIR"
  profile_link="$MANAGER_PROFILE_ROOT"
  data_target="${INSTALL_PATH}/server_manager"
  profile_target="${INSTALL_PATH}/profile"

  mkdir -p "$data_target" "$profile_target" 2>/dev/null || true

  ensure_volume_link() {
    local link target label real target_real
    link="$1"
    target="$2"
    label="$3"

    migrate_dir_contents() {
      local from to now dest
      from="$1"
      to="$2"
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
        warn "Failed to migrate $label data from $from to $dest"
        return 1
      fi
      rmdir "$from" 2>/dev/null || true
      info "Migrated $label data from $from to $dest"
    }

    if [[ -L "$link" ]]; then
      real="$(readlink -f "$link" 2>/dev/null || true)"
      target_real="$(readlink -f "$target" 2>/dev/null || true)"
      if [[ -n "$real" && -n "$target_real" && "$real" == "$target_real" ]]; then
        return 0
      fi
      if [[ -n "$real" && -d "$real" && "$real" != "$target_real" ]]; then
        migrate_dir_contents "$real" "$target" || true
      fi
      rm -f "$link" 2>/dev/null || true
    fi

    if [[ -e "$link" && ! -L "$link" ]]; then
      if command -v mountpoint >/dev/null 2>&1 && mountpoint -q "$link"; then
        warn "$label dir is a mountpoint; leaving as-is: $link"
        return 0
      fi
      if [[ -d "$link" ]]; then
        migrate_dir_contents "$link" "$target" || true
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

  ensure_volume_link "$data_link" "$data_target" "server_manager"
  ensure_volume_link "$profile_link" "$profile_target" "profile"

  data_real="$(readlink -f "$data_link" 2>/dev/null || true)"
  target_real="$(readlink -f "$data_target" 2>/dev/null || true)"
  if [[ -n "$data_real" && -n "$target_real" && "$data_real" != "$target_real" ]]; then
    warn "Manager data dir is not in mounted volume: $data_link -> $data_real (expected $target_real)"
  fi

  profile_real="$(readlink -f "$profile_link" 2>/dev/null || true)"
  profile_target_real="$(readlink -f "$profile_target" 2>/dev/null || true)"
  if [[ -n "$profile_real" && -n "$profile_target_real" && "$profile_real" != "$profile_target_real" ]]; then
    warn "Manager profile dir is not in mounted volume: $profile_link -> $profile_real (expected $profile_target_real)"
  fi

  mkdir -p "$data_link/run" 2>/dev/null || true
}

ensure_manager_profile_file() {
  local profile profile_file template_file
  profile="$1"
  profile_file="$(manager_profile_path "$profile")"
  template_file="$(manager_profile_template_path "$profile")"

  if [[ -f "$profile_file" ]]; then
    return 0
  fi
  if [[ ! -f "$template_file" ]]; then
    fatal "Server Manager profile template not found: $template_file"
  fi
  mkdir -p "$(dirname "$profile_file")" 2>/dev/null || true
  if ! jq -e '.' "$template_file" >/dev/null 2>&1; then
    fatal "Invalid JSON in server manager profile template: $template_file"
  fi
  cp "$template_file" "$profile_file"
  ok "Server Manager profile created: $profile_file"
}

manager_config_is_stub() {
  local file
  file="$1"
  if [[ ! -f "$file" ]]; then
    return 0
  fi
  if ! jq -e 'type == "object"' "$file" >/dev/null 2>&1; then
    return 1
  fi
  jq -e 'keys | all(. == "profile" or . == "profileApplied")' "$file" >/dev/null 2>&1
}

copy_manager_profile_to_config() {
  local profile_file config_file
  profile_file="$1"
  config_file="$2"
  if [[ ! -f "$profile_file" ]]; then
    fatal "Server Manager profile not found: $profile_file"
  fi
  if ! jq -e '.' "$profile_file" >/dev/null 2>&1; then
    fatal "Invalid JSON in server manager profile: $profile_file"
  fi
  mkdir -p "$(dirname "$config_file")" 2>/dev/null || true
  cp "$profile_file" "$config_file"
  ok "Server Manager config created from profile: $profile_file"
}

manager_profile_key_exists() {
  local file path key
  file="$1"
  path="$2"
  key="${path#.}"
  if [[ -z "$key" ]] || [[ ! -f "$file" ]]; then
    return 1
  fi
  jq -e --arg key "$key" 'has($key)' "$file" >/dev/null 2>&1
}

manager_profile_raw_value() {
  local file path
  file="$1"
  path="$2"
  jq -r "$path" "$file" 2>/dev/null || echo "null"
}

manager_profile_value_for_var() {
  local profile var path profile_file default_file raw
  profile="$1"
  var="$2"
  path="${MANAGER_JSON_PATH[$var]-}"
  if [[ -z "$path" ]]; then
    echo ""
    return 0
  fi
  profile_file="$(manager_profile_path "$profile")"
  if manager_profile_key_exists "$profile_file" "$path"; then
    raw="$(manager_profile_raw_value "$profile_file" "$path")"
    echo "$raw"
    return 0
  fi
  default_file="$(manager_profile_path "$MANAGER_PROFILE_DEFAULT")"
  if [[ "$profile" != "$MANAGER_PROFILE_DEFAULT" ]] && manager_profile_key_exists "$default_file" "$path"; then
    raw="$(manager_profile_raw_value "$default_file" "$path")"
    echo "$raw"
    return 0
  fi
  echo ""
}

apply_manager_profile_defaults() {
  local file profile var raw value normalized path
  file="$1"
  profile="$2"

  for var in "${MANAGER_VARS[@]}"; do
    value=""
    raw="$(manager_profile_value_for_var "$profile" "$var")"
    if [[ -z "$raw" ]]; then
      continue
    fi

    path="${MANAGER_JSON_PATH[$var]-}"
    if [[ -z "$path" ]]; then
      continue
    fi

    if [[ "$raw" == "null" ]]; then
      manager_config_set "$file" "$path = null"
      printf -v "$var" '%s' ""
      continue
    fi

    if ! validate_manager_value "$var" "$raw" "soft"; then
      if [[ "$profile" != "$MANAGER_PROFILE_DEFAULT" ]]; then
        raw="$(manager_profile_value_for_var "$MANAGER_PROFILE_DEFAULT" "$var")"
        if [[ -n "$raw" && "$raw" != "null" ]] && validate_manager_value "$var" "$raw" "soft"; then
          value="$raw"
        else
          warn "Profile $profile: $var invalid, skipping"
          continue
        fi
      else
        warn "Profile $profile: $var invalid, skipping"
        continue
      fi
    fi

    value="${value:-$raw}"
    if [[ "$var" == "LOG_LEVEL" ]]; then
      normalized="$(normalize_log_level "$raw")"
      value="$normalized"
      LOG_LEVEL="$normalized"
    fi

    manager_config_set_value "$file" "$var" "$value"
    printf -v "$var" '%s' "$value"
  done

}

declare -a MANAGER_VARS=(
  PUID
  PGID
  NO_COLOR
  LOG_LEVEL
  LOG_CONTEXT
  UMASK
  AUTO_FIX_PERMS
  AUTO_FIX_DIR_MODE
  AUTO_FIX_FILE_MODE
  SAVEFILE_NAME
  STOP_TIMEOUT
  STEAM_APP_ID
  GAME_BRANCH
  STEAMCMD_ARGS
  WINEDEBUG
  AUTO_UPDATE
  AUTO_UPDATE_INTERVAL
  AUTO_UPDATE_ON_BOOT
  AUTO_RESTART_ON_UPDATE
  SAFE_MODE
  UPDATE_CHECK_PLAYERS
  RESTART_CHECK_PLAYERS
  A2S_TIMEOUT
  A2S_RETRIES
  A2S_RETRY_DELAY
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
  PRINT_GROUP_PASSWORDS
)

declare -A MANAGER_JSON_PATH=(
  [PUID]=".puid"
  [PGID]=".pgid"
  [NO_COLOR]=".noColor"
  [LOG_LEVEL]=".logLevel"
  [LOG_CONTEXT]=".logContext"
  [UMASK]=".umask"
  [AUTO_FIX_PERMS]=".autoFixPerms"
  [AUTO_FIX_DIR_MODE]=".autoFixDirMode"
  [AUTO_FIX_FILE_MODE]=".autoFixFileMode"
  [SAVEFILE_NAME]=".savefileName"
  [STOP_TIMEOUT]=".stopTimeout"
  [STEAM_APP_ID]=".steamAppId"
  [GAME_BRANCH]=".gameBranch"
  [STEAMCMD_ARGS]=".steamcmdArgs"
  [WINEDEBUG]=".winedebug"
  [AUTO_UPDATE]=".autoUpdate"
  [AUTO_UPDATE_INTERVAL]=".autoUpdateInterval"
  [AUTO_UPDATE_ON_BOOT]=".autoUpdateOnBoot"
  [AUTO_RESTART_ON_UPDATE]=".autoRestartOnUpdate"
  [SAFE_MODE]=".safeMode"
  [UPDATE_CHECK_PLAYERS]=".updateCheckPlayers"
  [RESTART_CHECK_PLAYERS]=".restartCheckPlayers"
  [A2S_TIMEOUT]=".a2sTimeout"
  [A2S_RETRIES]=".a2sRetries"
  [A2S_RETRY_DELAY]=".a2sRetryDelay"
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
  [PRINT_GROUP_PASSWORDS]=".printGroupPasswords"
)

declare -A MANAGER_TYPE=(
  [PUID]="int"
  [PGID]="int"
  [STEAM_APP_ID]="int"
  [AUTO_UPDATE_INTERVAL]="int"
  [A2S_RETRIES]="int"
  [BACKUP_MAX_COUNT]="int"
  [STOP_TIMEOUT]="int"
  [A2S_TIMEOUT]="number"
  [A2S_RETRY_DELAY]="number"
  [AUTO_FIX_PERMS]="bool"
  [AUTO_UPDATE]="bool"
  [AUTO_UPDATE_ON_BOOT]="bool"
  [AUTO_RESTART_ON_UPDATE]="bool"
  [SAFE_MODE]="bool"
  [UPDATE_CHECK_PLAYERS]="bool"
  [RESTART_CHECK_PLAYERS]="bool"
  [ENABLE_CRON]="bool"
  [PRINT_GROUP_PASSWORDS]="bool"
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
    A2S_RETRIES)
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
    AUTO_FIX_DIR_MODE|AUTO_FIX_FILE_MODE)
      if [[ -n "$value" ]] && ! [[ "$value" =~ ^[0-7]{3,4}$ ]]; then
        manager_validation_fail "$mode" "$var must be an octal string like 775 (actual: $value)"
        return 1
      fi
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
    AUTO_UPDATE|AUTO_UPDATE_ON_BOOT|AUTO_RESTART_ON_UPDATE|SAFE_MODE|UPDATE_CHECK_PLAYERS|RESTART_CHECK_PLAYERS|ENABLE_CRON|PRINT_GROUP_PASSWORDS)
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
  local var default raw
  var="$1"

  if [[ -n "${MANAGER_EXPLICIT_VARS[$var]-}" ]]; then
    echo "${!var-}"
    return 0
  fi

  raw="$(manager_profile_value_for_var "$MANAGER_PROFILE_DEFAULT" "$var")"
  if [[ "$raw" == "null" || -z "$raw" ]]; then
    echo ""
    return 0
  fi
  if [[ "$var" == "LOG_LEVEL" ]]; then
    default="$(normalize_log_level "$raw")"
    echo "$default"
    return 0
  fi
  echo "$raw"
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
    ok "Server Manager config created"
  fi
}

cleanup_manager_config_paths() {
  local file temp_file
  file="$1"
  temp_file="$(mktemp)"
  if jq 'del(.protonCmd, .wineserverPath, .winetricks, .profile, .profileApplied)' "$file" >"$temp_file"; then
    mv "$temp_file" "$file"
  else
    rm -f "$temp_file"
    fatal "Failed to update $file (jq error)"
  fi
}

update_or_create_manager_config() {
  local file profile profile_file
  require_cmd jq
  MANAGER_EXPLICIT_VARS=()
  MANAGER_ENV_IGNORE=()
  MANAGER_JSON_INVALID=()

  ensure_manager_paths
  profile="$(manager_profile_resolve)"
  ensure_manager_profile_file "$profile"
  profile_file="$(manager_profile_path "$profile")"

  file="$(manager_config_path)"
  if [[ ! -f "$file" ]] || manager_config_is_stub "$file"; then
    copy_manager_profile_to_config "$profile_file" "$file"
  fi
  if ! jq -e '.' "$file" >/dev/null 2>&1; then
    fatal "Invalid JSON in $file"
  fi
  cleanup_manager_config_paths "$file"

  apply_manager_env_overrides "$file"
  load_manager_config_values "$file"

  apply_manager_defaults "$file"
  load_manager_config_values "$file"
  validate_manager_json_values "$file"
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
  ensure_manager_paths
  mkdir -p "$INSTALL_PATH" "$RUN_DIR"
}

resolve_save_dir() {
  if [[ -n "$ENSHROUDED_SAVE_DIR" ]]; then
    abs_path "$ENSHROUDED_SAVE_DIR"
  elif command -v jq >/dev/null 2>&1 && [[ -f "$CONFIG_FILE" ]]; then
    abs_path "$(jq -r '.saveDirectory // "./savegame"' "$CONFIG_FILE" 2>/dev/null || echo "./savegame")"
  else
    abs_path "./savegame"
  fi
}

resolve_log_dir() {
  if [[ -n "$ENSHROUDED_LOG_DIR" ]]; then
    abs_path "$ENSHROUDED_LOG_DIR"
  elif command -v jq >/dev/null 2>&1 && [[ -f "$CONFIG_FILE" ]]; then
    abs_path "$(jq -r '.logDirectory // "./logs"' "$CONFIG_FILE" 2>/dev/null || echo "./logs")"
  else
    abs_path "./logs"
  fi
}

resolve_backup_dir() {
  abs_path "$BACKUP_DIR"
}

AUTO_FIX_PERMS_LOGGED="false"

auto_fix_enabled() {
  local value
  value="${AUTO_FIX_PERMS-}"
  if [[ -z "$value" ]]; then
    return 0
  fi
  case "$value" in
    false|FALSE|0|no|NO)
      log_auto_fix_disabled_once
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

log_auto_fix_disabled_once() {
  if [[ "${AUTO_FIX_PERMS_LOGGED:-false}" == "true" ]]; then
    return 0
  fi
  case "${AUTO_FIX_PERMS-}" in
    false|FALSE|0|no|NO)
      AUTO_FIX_PERMS_LOGGED="true"
      warn "AUTO_FIX_PERMS disabled (value: ${AUTO_FIX_PERMS})"
      ;;
  esac
}

ensure_writable_dir() {
  local dir
  dir="$1"
  if [[ -z "$dir" ]]; then
    return 0
  fi

  mkdir -p "$dir" 2>/dev/null || true

  if runuser -u steam -p -- test -w "$dir" 2>/dev/null; then
    return 0
  fi

  warn "Permission check failed for: $dir"

  if ! auto_fix_enabled; then
    log_auto_fix_disabled_once
    info "Auto permission repair disabled for: $dir (AUTO_FIX_PERMS=${AUTO_FIX_PERMS:-<unset>})"
    return 1
  fi

  info "Attempting to fix permissions for: $dir"
  chown -R "$PUID:$PGID" "$dir" 2>/dev/null || true
  if [[ -n "${AUTO_FIX_DIR_MODE:-}" ]]; then
    find "$dir" -type d -exec chmod "$AUTO_FIX_DIR_MODE" {} + 2>/dev/null || true
  fi
  if [[ -n "${AUTO_FIX_FILE_MODE:-}" ]]; then
    find "$dir" -type f -exec chmod "$AUTO_FIX_FILE_MODE" {} + 2>/dev/null || true
  fi

  if runuser -u steam -p -- test -w "$dir" 2>/dev/null; then
    info "Permissions fixed for: $dir"
    return 0
  fi

  warn "Still not writable after fix attempt: $dir"
  return 1
}

preflight_permissions() {
  local save_dir log_dir backup_dir
  local -a failed
  failed=()
  ensure_manager_paths
  if ! auto_fix_enabled; then
    log_auto_fix_disabled_once
  fi
  save_dir="$(resolve_save_dir)"
  log_dir="$(resolve_log_dir)"
  backup_dir="$(resolve_backup_dir)"

  if ! ensure_writable_dir "$MANAGER_DATA_DIR"; then
    failed+=("$MANAGER_DATA_DIR")
  fi
  if ! ensure_writable_dir "$MANAGER_PROFILE_DIR"; then
    failed+=("$MANAGER_PROFILE_DIR")
  fi
  if ! ensure_writable_dir "$INSTALL_PATH"; then
    failed+=("$INSTALL_PATH")
  fi
  if ! ensure_writable_dir "$RUN_DIR"; then
    failed+=("$RUN_DIR")
  fi
  if ! ensure_writable_dir "$save_dir"; then
    failed+=("$save_dir")
  fi
  if ! ensure_writable_dir "$log_dir"; then
    failed+=("$log_dir")
  fi
  if ! ensure_writable_dir "$backup_dir"; then
    failed+=("$backup_dir")
  fi

  if [[ "${#failed[@]}" -gt 0 ]]; then
    if auto_fix_enabled; then
      fatal "Permission check failed after auto-fix for: ${failed[*]}"
    fi
    fatal "Permission check failed (AUTO_FIX_PERMS=${AUTO_FIX_PERMS:-<unset>}) for: ${failed[*]}"
  fi
}

create_folders() {
  local save_dir log_dir backup_dir
  save_dir="$(resolve_save_dir)"
  log_dir="$(resolve_log_dir)"
  backup_dir="$(resolve_backup_dir)"

  mkdir -p "$save_dir" "$log_dir" "$backup_dir"
}

ensure_steam_paths() {
  mkdir -p "$WINEPREFIX" "$STEAM_COMPAT_DATA_PATH" "$STEAM_COMPAT_CLIENT_INSTALL_PATH"
  mkdir -p "${HOME:-/home/steam}/.steam" "${HOME:-/home/steam}/.steam/sdk32" "${HOME:-/home/steam}/.steam/sdk64"
}

create_default_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    return 0
  fi

  require_cmd jq
  local profile profile_file temp_file
  profile="$(enshrouded_profile_resolve)"
  profile_file="$(enshrouded_profile_path "$profile")"

  if [[ ! -f "$profile_file" ]]; then
    fatal "Enshrouded profile not found: $profile_file"
  fi
  if ! jq -e '.' "$profile_file" >/dev/null 2>&1; then
    fatal "Invalid JSON in enshrouded profile: $profile_file"
  fi

  info "Creating initial enshrouded_server.json (profile: $profile)"
  temp_file="$(mktemp)"
  if jq 'if has("bans") then . else . + {bans: []} end' "$profile_file" >"$temp_file"; then
    mv "$temp_file" "$CONFIG_FILE"
  else
    rm -f "$temp_file"
    fatal "Failed to create $CONFIG_FILE (jq error)"
  fi

  chmod 600 "$CONFIG_FILE" 2>/dev/null || true
  ok "enshrouded_server.json created"
  EN_CONFIG_CREATED="true"
}

ensure_user_group_passwords() {
  local count idx name pw new_pw label print_passwords
  if ! command -v jq >/dev/null 2>&1; then
    return 0
  fi
  if ! jq -e '.userGroups' "$CONFIG_FILE" >/dev/null 2>&1; then
    return 0
  fi
  count="$(jq -r '.userGroups | length' "$CONFIG_FILE" 2>/dev/null || echo 0)"
  if ! [[ "$count" =~ ^[0-9]+$ ]] || [[ "$count" -le 0 ]]; then
    return 0
  fi

  print_passwords="false"
  if is_true "$PRINT_GROUP_PASSWORDS"; then
    print_passwords="true"
  fi

  for idx in $(seq 0 $((count - 1))); do
    name="$(jq -r ".userGroups[$idx].name // \"\"" "$CONFIG_FILE" 2>/dev/null || echo "")"
    pw="$(jq -r ".userGroups[$idx].password // \"\"" "$CONFIG_FILE" 2>/dev/null || echo "")"
    if [[ -z "$pw" || "$pw" == "null" ]]; then
      new_pw="$(generate_password)"
      config_set --argjson group_index "$idx" --arg password "$new_pw" '.userGroups[$group_index].password = $password'
      pw="$new_pw"
    fi

    if [[ "$print_passwords" == "true" && -n "$pw" && "$pw" != "null" ]]; then
      if [[ -n "$name" && "$name" != "null" ]]; then
        label="Group $idx ($name)"
      else
        label="Group $idx"
      fi
      info "$label password: $pw"
    fi
  done
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
  EN_CONFIG_CREATED="false"
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
  if [[ "$EN_CONFIG_CREATED" == "true" ]]; then
    ensure_user_group_passwords
  fi
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
    # Use indirect expansion to avoid eval (safer for secrets and special chars).
    group_value="${!var_name-}"

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
    info "Start bootstrap hook: $BOOTSTRAP_HOOK"
    run_hook_logged "$BOOTSTRAP_HOOK" info "$LOG_CONTEXT"
  fi
}

prepare_a2s_library() {
  if ! command -v python3 >/dev/null 2>&1; then
    warn "python3 not available, player count checks may be unavailable"
    return
  fi
  debug "A2S player query uses Python stdlib, no pip packages required"
}

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
  local missing_keys
  local default_value
  missing_keys=()

  for var_name in "${ENSHROUDED_GS_VARS[@]}"; do
    suffix="${var_name#ENSHROUDED_GS_}"
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
  pattern="^($(printf '%s\n' "${ENSHROUDED_GS_VARS[@]}" | tr '\n' '|' | sed 's/|$//'))$"
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

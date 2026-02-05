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
  create_default_config
  require_cmd jq

  if [[ -n "$ENSHROUDED_NAME" ]]; then
    config_set --arg name "$ENSHROUDED_NAME" '.name = $name'
  fi

  if [[ -n "$ENSHROUDED_SAVE_DIR" ]]; then
    config_set --arg saveDirectory "$ENSHROUDED_SAVE_DIR" '.saveDirectory = $saveDirectory'
  fi

  if [[ -n "$ENSHROUDED_LOG_DIR" ]]; then
    config_set --arg logDirectory "$ENSHROUDED_LOG_DIR" '.logDirectory = $logDirectory'
  fi

  if [[ -n "$ENSHROUDED_IP" ]]; then
    config_set --arg ip "$ENSHROUDED_IP" '.ip = $ip'
  fi

  if [[ -n "$ENSHROUDED_QUERY_PORT" ]]; then
    config_set --argjson queryPort "$ENSHROUDED_QUERY_PORT" '.queryPort = $queryPort'
  fi

  if [[ -n "$ENSHROUDED_SLOT_COUNT" ]]; then
    config_set --argjson slotCount "$ENSHROUDED_SLOT_COUNT" '.slotCount = $slotCount'
  fi

  if [[ -n "$ENSHROUDED_VOICE_CHAT_MODE" ]]; then
    config_set --arg voiceChatMode "$ENSHROUDED_VOICE_CHAT_MODE" '.voiceChatMode = $voiceChatMode'
  fi

  if [[ -n "$ENSHROUDED_ENABLE_VOICE_CHAT" ]]; then
    config_set --argjson enableVoiceChat "$ENSHROUDED_ENABLE_VOICE_CHAT" '.enableVoiceChat = $enableVoiceChat'
  fi

  if [[ -n "$ENSHROUDED_ENABLE_TEXT_CHAT" ]]; then
    config_set --argjson enableTextChat "$ENSHROUDED_ENABLE_TEXT_CHAT" '.enableTextChat = $enableTextChat'
  fi

  if [[ -n "$ENSHROUDED_TAGS" ]]; then
    config_set --arg tags "$ENSHROUDED_TAGS" '.tags = ($tags | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length>0)))'
  fi

  update_user_group_config
  update_game_settings_config
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
        config_set --argjson group_index "$group_index" --arg name "$group_value" '.userGroups[$group_index].name = $name'
        ;;
      PASSWORD)
        config_set --argjson group_index "$group_index" --arg password "$group_value" '.userGroups[$group_index].password = $password'
        ;;
      CAN_KICK_BAN)
        validate_bool "ENSHROUDED_ROLE_${group_index}_CAN_KICK_BAN" "$group_value"
        config_set --argjson group_index "$group_index" --argjson canKickBan "$group_value" '.userGroups[$group_index].canKickBan = $canKickBan'
        ;;
      CAN_ACCESS_INVENTORIES)
        validate_bool "ENSHROUDED_ROLE_${group_index}_CAN_ACCESS_INVENTORIES" "$group_value"
        config_set --argjson group_index "$group_index" --argjson canAccessInventories "$group_value" '.userGroups[$group_index].canAccessInventories = $canAccessInventories'
        ;;
      CAN_EDIT_WORLD)
        validate_bool "ENSHROUDED_ROLE_${group_index}_CAN_EDIT_WORLD" "$group_value"
        config_set --argjson group_index "$group_index" --argjson canEditWorld "$group_value" '.userGroups[$group_index].canEditWorld = $canEditWorld'
        ;;
      CAN_EDIT_BASE)
        validate_bool "ENSHROUDED_ROLE_${group_index}_CAN_EDIT_BASE" "$group_value"
        config_set --argjson group_index "$group_index" --argjson canEditBase "$group_value" '.userGroups[$group_index].canEditBase = $canEditBase'
        ;;
      CAN_EXTEND_BASE)
        validate_bool "ENSHROUDED_ROLE_${group_index}_CAN_EXTEND_BASE" "$group_value"
        config_set --argjson group_index "$group_index" --argjson canExtendBase "$group_value" '.userGroups[$group_index].canExtendBase = $canExtendBase'
        ;;
      RESERVED_SLOTS)
        if [[ ! "$group_value" =~ ^[0-9]+$ ]]; then
          fatal "ENSHROUDED_ROLE_${group_index}_RESERVED_SLOTS must be numeric (actual: $group_value)"
        fi
        config_set --argjson group_index "$group_index" --argjson reservedSlots "$group_value" '.userGroups[$group_index].reservedSlots = $reservedSlots'
        ;;
    esac
  done
}

update_game_settings_config() {
  local suffix var_name var_value jq_key_name full_jq_path jq_arg_option temp_json_file
  local gs_keys
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
    var_value="${!var_name:-}"

    if [[ -z "$var_value" ]]; then
      info "$var_name not set; keeping existing value"
      continue
    fi

    if ! validate_game_setting "$suffix" "$var_value"; then
      warn "$var_name invalid; keeping existing value"
      continue
    fi

    jq_key_name=$(echo "$suffix" | tr '[:upper:]' '[:lower:]' | awk -F_ '{for(i=1;i<=NF;i++){if(i==1){out=$i}else{out=out toupper(substr($i,1,1)) substr($i,2)}}}END{print out}')

    if [[ "$suffix" == "PRESET" ]]; then
      full_jq_path=".gameSettingsPreset"
      jq_arg_option="--arg"
    else
      full_jq_path=".gameSettings.$jq_key_name"
      if [[ "$var_value" == "true" || "$var_value" == "false" || "$var_value" =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]]; then
        jq_arg_option="--argjson"
      else
        jq_arg_option="--arg"
      fi
    fi

    temp_json_file="$(mktemp)"
    if jq "$jq_arg_option" val "$var_value" "$full_jq_path = \$val" "$CONFIG_FILE" >"$temp_json_file"; then
      mv "$temp_json_file" "$CONFIG_FILE"
    else
      warn "Failed to update $var_name in $CONFIG_FILE"
      rm -f "$temp_json_file"
    fi
  done
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

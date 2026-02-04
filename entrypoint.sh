#!/bin/bash
set -euo pipefail

# --- helpers ---

ensure_dirs() {
    # Guarantee base directories exist for Steam and server data
    mkdir -p /home/steam/.steam
    mkdir -p /home/steam/enshrouded
}

detect_ids_from_volume() {
    # Read owner UID/GID of the mounted data volume
    local uid gid
    uid=$(stat -c '%u' /home/steam/enshrouded)
    gid=$(stat -c '%g' /home/steam/enshrouded)
    echo "$uid" "$gid"
}

remap_uid_gid() {
    # Remap steam to match host volume ownership (or env overrides)
    if [ "$(id -u)" -ne 0 ]; then
        echo "Not running as root; skipping UID/GID remap. Ensure host volume ownership matches container user."
        return
    fi

    local target_uid target_gid
    read -r target_uid target_gid <<<"$(detect_ids_from_volume)"

    # Use volume owner only (no env overrides)
    target_uid=$target_uid
    target_gid=$target_gid

    # If the volume is owned by root, don't remap steam to UID 0; just fix ownership.
    if [ "$target_uid" = "0" ] || [ "$target_gid" = "0" ]; then
        echo "Volume owned by root; keeping steam UID/GID and chowning data instead."
        chown -R steam:steam /home/steam/enshrouded || true
        return
    fi

    current_uid=$(id -u steam)
    current_gid=$(id -g steam)

    if [ "$current_uid" != "$target_uid" ]; then
        usermod -o -u "$target_uid" steam
    fi
    if [ "$current_gid" != "$target_gid" ]; then
        groupmod -o -g "$target_gid" steam
    fi

    # Align ownership of home (steam cache + data) with remapped steam user
    chown -R "$target_uid:$target_gid" /home/steam || true
}

run_as_steam() {
    # Drop privileges to steam via gosu
    gosu steam "$@"
}

generate_password() {
    # Generate 8-char alphanumeric password
    head -c 64 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8
}

# --- main flow ---

ensure_dirs           # create required dirs
remap_uid_gid         # align steam UID/GID with volume

# Create config on first run
ADMIN_PW=""
if [ ! -e "/home/steam/enshrouded/enshrouded_server.json" ]; then
    echo " ----- Starting initial configuration -----"

    ADMIN_PW=$(generate_password)
    FRIEND_PW=$(generate_password)
    GUEST_PW=$(generate_password)
    VISITOR_PW=$(generate_password)

    cat << EOF > "/home/steam/enshrouded/enshrouded_server.json"
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
      "password": "${ADMIN_PW}",
      "canKickBan": true,
      "canAccessInventories": true,
      "canEditWorld": true,
      "canEditBase": true,
      "canExtendBase": true,
      "reservedSlots": 0
    },
    {
      "name": "Friend",
      "password": "${FRIEND_PW}",
      "canKickBan": false,
      "canAccessInventories": true,
      "canEditWorld": true,
      "canEditBase": true,
      "canExtendBase": false,
      "reservedSlots": 0
    },
    {
      "name": "Guest",
      "password": "${GUEST_PW}",
      "canKickBan": false,
      "canAccessInventories": false,
      "canEditWorld": true,
      "canEditBase": false,
      "canExtendBase": false,
      "reservedSlots": 0
    },
    {
      "name": "Visitor",
      "password": "${VISITOR_PW}",
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

    echo "enshrouded_server.json created."
    echo " ----- Initial configuration complete -----"
else
    echo " ----- Server configuration already exists -----"
fi

run_as_steam ./steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir /home/steam/enshrouded +login anonymous +app_update 2278520 +quit
echo "Server files updated."

echo ""
echo "================================================================"
echo "   ENSHROUDED SERVER is READY — Starting now!"
echo "================================================================"
echo ""

run_as_steam wine /home/steam/enshrouded/enshrouded_server.exe &
SERVER_PID=$!

if [ -n "$ADMIN_PW" ]; then
    echo ""
    echo "================================================================"
    echo " In-game Admin login password: ${ADMIN_PW}"
    echo " Change it anytime in enshrouded_server.json."
    echo "================================================================"
    echo ""
fi

wait $SERVER_PID

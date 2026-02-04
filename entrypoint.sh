#!/bin/bash

# Ensure .steam directory exists to avoid symlink issues
mkdir -p /home/steam/.steam

# If this is the first initialization of the container, create the server config
if [ ! -e /home/steam/enshrouded/enshrouded_server.json ]; then

    echo " ----- Starting initial configuration -----"
    echo "Changing UID and GID to host IDs"
    usermod -u "$ENSHROUDED_USER_ID" steam
    groupmod -g "$ENSHROUDED_GROUP_ID" steam

    # Create server properties file using default settings (passwords stay configurable via env or auto-generated)

    generate_password() {
        # 8-char alphanumeric password
        head -c 64 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8
    }

    ADMIN_PW=$(generate_password)
    FRIEND_PW=$(generate_password)
    GUEST_PW=$(generate_password)
    VISITOR_PW=$(generate_password)

    echo "Creating server configuration file..."

    touch /home/steam/enshrouded/enshrouded_server.json
    cat << EOF >> /home/steam/enshrouded/enshrouded_server.json
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

# Update or install the Enshrouded dedicated server using SteamCMD
./steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir /home/steam/enshrouded +login anonymous +app_update 2278520 +quit
echo "Server files updated."

# Launch the Enshrouded server executable using Wine
# Using exec to replace the shell with wine, making it tini's direct child.
# This allows tini to forward signals (SIGTERM, SIGINT, etc.) directly to wine
echo ""
echo "================================================================"
echo "   ENSHROUDED SERVER is READY — Starting now!"
echo "================================================================"
echo ""

exec wine /home/steam/enshrouded/enshrouded_server.exe &
SERVER_PID=$!

echo ""
echo "================================================================"
echo " In-game Admin login password (randomly generated): ${ADMIN_PW}"
echo " Change it anytime in enshrouded_server.json."
echo "================================================================"
echo ""

wait $SERVER_PID

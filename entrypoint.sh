#!/bin/bash

# Ensure .steam directory exists to avoid symlink issues
mkdir -p /home/steam/.steam

# If this is the first initialization of the container, create the server config and change UID & GID to host IDs
if [ ! -e /home/steam/enshrouded/enshrouded_server.json ]; then

    echo " ----- Starting initial configuration -----"

    echo "Changing UID and GID to host IDs"
    usermod -u "$ENSHROUDED_USER_ID" steam
    groupmod -g "$ENSHROUDED_GROUP_ID" steam

    # Create server properties file using environment variables
    echo "Creating server configuration file..."

    touch /home/steam/enshrouded/enshrouded_server.json
    cat << EOF >> /home/steam/enshrouded/enshrouded_server.json
{
  "name": "${ENSHROUDED_SERVER_NAME}",
  "saveDirectory": "./savegame",
  "logDirectory": "./logs",
  "ip": "0.0.0.0",
  "queryPort": 15637,
  "slotCount": ${ENSHROUDED_SERVER_MAXPLAYERS},
  "voiceChatMode": "${ENSHROUDED_VOICE_CHAT_MODE}",
  "enableVoiceChat": ${ENSHROUDED_ENABLE_VOICE_CHAT},
  "enableTextChat": ${ENSHROUDED_ENABLE_TEXT_CHAT},
  "gameSettingsPreset": "${ENSHROUDED_GAME_PRESET}",
  "gameSettings": {
    "playerHealthFactor": 1,
    "playerManaFactor": 1,
    "playerStaminaFactor": 1,
    "playerBodyHeatFactor": 1,
    "enableDurability": true,
    "enableStarvingDebuff": false,
    "foodBuffDurationFactor": 1,
    "fromHungerToStarving": 600000000000,
    "shroudTimeFactor": 1,
    "tombstoneMode": "AddBackpackMaterials",
    "enableGliderTurbulences": true,
    "weatherFrequency": "Normal",
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
    "nightTimeDuration": 720000000000
  },
  "userGroups": [
    {
      "name": "Admin",
      "password": "${ENSHROUDED_ADMIN_PW}",
      "canKickBan": true,
      "canAccessInventories": true,
      "canEditBase": true,
      "canExtendBase": true,
      "reservedSlots": 0
    },
    {
      "name": "Friend",
      "password": "${ENSHROUDED_FRIEND_PW}",
      "canKickBan": false,
      "canAccessInventories": true,
      "canEditBase": true,
      "canExtendBase": false,
      "reservedSlots": 0
    },
    {
      "name": "Guest",
      "password": "${ENSHROUDED_GUEST_PW}",
      "canKickBan": false,
      "canAccessInventories": false,
      "canEditBase": false,
      "canExtendBase": false,
      "reservedSlots": 0
    }
  ]
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
echo "Launching Enshrouded server..."
exec wine /home/steam/enshrouded/enshrouded_server.exe

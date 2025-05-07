#!/bin/bash

set -e

CONFIG_PATH="/home/steam/enshrouded/enshrouded_server.json"

# Standard-IP, falls nicht gesetzt
: "${ENSHROUDED_SERVER_NAME:=Enshrouded Server}"
: "${ENSHROUDED_SERVER_MAXPLAYERS:=16}"
: "${ENSHROUDED_SERVER_IP:=0.0.0.0}"
: "${ENSHROUDED_VOICE_CHAT_MODE:=Proximity}"
: "${ENSHROUDED_ENABLE_VOICE_CHAT:=false}"
: "${ENSHROUDED_ENABLE_TEXT_CHAT:=false}"
: "${ENSHROUDED_GAME_PRESET:=Default}"
: "${ENSHROUDED_ADMIN_PW:=AdminXXXXXXXX}"
: "${ENSHROUDED_FRIEND_PW:=FriendXXXXXXXX}"
: "${ENSHROUDED_GUEST_PW:=GuestXXXXXXXX}"

# Initial configuration
if [ ! -e "$CONFIG_PATH" ]; then
    echo " ----- Creating server config: enshrouded_server.json -----"

    cat << EOF > "$CONFIG_PATH"
{
  "name": "${ENSHROUDED_SERVER_NAME}",
  "saveDirectory": "./savegame",
  "logDirectory": "./logs",
  "ip": "${ENSHROUDED_SERVER_IP}",
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

    echo " ----- Server config created successfully -----"
else
    echo " ----- Existing config found, skipping creation -----"
fi

# Update or install the Enshrouded dedicated server using SteamCMD
su steam -c "./steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir /home/steam/enshrouded +login anonymous +app_update 2278520 +quit"
echo "Server files updated."

# Launch server
su steam -c "wine /home/steam/enshrouded/enshrouded_server.exe"
echo "Server launched successfully."
/bin/bash

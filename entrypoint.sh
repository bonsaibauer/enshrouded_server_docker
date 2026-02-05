#!/bin/bash

if [ "${1:-}" != "--as-steam" ]; then
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: entrypoint must run as root to apply PUID/PGID." >&2
        echo "Set -e PUID=\$(id -u enshrouded) -e PGID=\$(id -g enshrouded) and do not use --user." >&2
        exit 1
    fi

    if [ -z "${PUID:-}" ] || [ -z "${PGID:-}" ]; then
        echo "ERROR: PUID and PGID are required." >&2
        echo "Example: -e PUID=\$(id -u enshrouded) -e PGID=\$(id -g enshrouded)" >&2
        exit 1
    fi

    case "$PUID" in
        ''|*[!0-9]*)
            echo "ERROR: PUID must be numeric (got: $PUID)." >&2
            exit 1
            ;;
    esac

    case "$PGID" in
        ''|*[!0-9]*)
            echo "ERROR: PGID must be numeric (got: $PGID)." >&2
            exit 1
            ;;
    esac

    if [ "$PUID" -eq 0 ] || [ "$PGID" -eq 0 ]; then
        echo "ERROR: PUID/PGID must not be 0 (root)." >&2
        exit 1
    fi

    groupmod -o -g "$PGID" steam
    usermod -o -u "$PUID" -g "$PGID" steam
    chown "$PUID:$PGID" /home/steam 2>/dev/null || true
    chown -R "$PUID:$PGID" /home/steam/enshrouded 2>/dev/null || true

    exec runuser -u steam -p -- env HOME=/home/steam USER=steam LOGNAME=steam "$0" --as-steam "$@"
fi

if [ "${1:-}" = "--as-steam" ]; then
    shift
fi

# Ensure HOME and WINEPREFIX are set for the steam user
export HOME="/home/steam"
if [ -z "${WINEPREFIX:-}" ]; then
    export WINEPREFIX="${HOME}/.wine"
fi
mkdir -p "${WINEPREFIX}"

# Ensure .steam directory exists to avoid symlink issues
mkdir -p /home/steam/.steam

# If this is the first initialization of the container, create the server config
if [ ! -e "/home/steam/enshrouded/enshrouded_server.json" ]; then
    echo " ----- Starting initial configuration -----"

    generate_password() {
        # 8-char alphanumeric password
        head -c 64 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8
    }

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

# Update or install the Enshrouded dedicated server using SteamCMD
./steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir /home/steam/enshrouded +login anonymous +app_update 2278520 +quit
echo "Server files updated."

# Launch the Enshrouded server executable using Wine
echo ""
cat <<'EOF'
================================================================
···································································
:  _____ _             _   _                  _   _               :
: / ____| |           | | (_)                | \ | |              :
:| (___ | |_ __ _ _ __| |_ _ _ __   __ _     |  \| | _____      __:
: \___ \| __/ _` | '__| __| | '_ \ / _` |    | . ` |/ _ \ \ /\ / /:
: ____) | || (_| | |  | |_| | | | | (_| |    | |\  | (_) \ V  V / :
:|_____/ \__\__,_|_|   \__|_|_| |_|\__, |    |_| \_|\___/ \_/\_/  :
:                                   __/ |                         :
:                                  |___/                          :
···································································
EOF
echo "================================================================"
echo ""
exec wine /home/steam/enshrouded/enshrouded_server.exe &
SERVER_PID=$!

if [ -n "$ADMIN_PW" ]; then
    echo ""
    cat <<'EOF'
================================================================
···························································
: ______           _                         _          _ :
:|  ____|         | |                       | |        | |:
:| |__   _ __  ___| |__  _ __ ___  _   _  __| | ___  __| |:
:|  __| | '_ \/ __| '_ \| '__/ _ \| | | |/ _` |/ _ \/ _` |:
:| |____| | | \__ \ | | | | | (_) | |_| | (_| |  __/ (_| |:
:|______|_| |_|___/_| |_|_|  \___/ \__,_|\__,_|\___|\__,_|:
···························································
EOF
    echo "================================================================"
    echo " In-game Admin login password: ${ADMIN_PW}"
    echo " Change it anytime in enshrouded_server.json."
    echo "================================================================"
    echo ""
fi

wait $SERVER_PID

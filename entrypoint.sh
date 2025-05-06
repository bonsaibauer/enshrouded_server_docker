#!/bin/bash

# If this is the first initialization of the container, create the server config
if [ ! -e /home/steam/enshrouded/enshrouded_server.json ]; then

    echo " ----- Starting initial configuration -----"

    # Create server properties file using environment variables
    echo "Creating server configuration file..."

    touch /home/steam/enshrouded/enshrouded_server.json
    cat << EOF >> /home/steam/enshrouded/enshrouded_server.json
{
    "name": "$(echo $ENSHROUDED_SERVER_NAME)",
    "password": "$(echo $ENSHROUDED_SERVER_PASSWORD)",
    "saveDirectory": "./savegame",
    "logDirectory": "./logs",
    "ip": "0.0.0.0",
    "gamePort": 15636,
    "queryPort": 15637,
    "slotCount": $(echo $ENSHROUDED_SERVER_MAXPLAYERS)
}
EOF

    echo "enshrouded_server.json created."

    echo " ----- Initial configuration complete -----"
else
    echo " ----- Server configuration already exists -----"
fi

# Update or install the Enshrouded dedicated server using SteamCMD
su steam -c "./steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir /home/steam/enshrouded +login anonymous +app_update 2278520 +quit"
echo "Server files updated."

# Launch the Enshrouded server executable using Wine
su steam -c "wine /home/steam/enshrouded/enshrouded_server.exe"
echo "Server launched successfully."
/bin/bash

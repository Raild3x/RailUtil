#!/bin/bash

echo "Initializing submodules..."

git submodule init
git submodule update

 
TEST_PLACE="TestEz Companion.rbxl"
# check if the test place exists, if not then create it
if [ ! -f "$TEST_PLACE" ]; then
    echo "Test place not found, creating it..."
    rojo build -o "$TEST_PLACE"
fi


echo "Do you want to open Roblox Studio? (y/n)"
read USER_INPUT
if [ "$USER_INPUT" = "y" ]; then
   # Define the file path using the username
    USERNAME=$(whoami)
    ROBLOX_STUDIO_PATH="C:/Users/$USERNAME/AppData/Local/Roblox/Versions/version-1b1a91b0565547cc/RobloxStudioBeta.exe"

    echo "Opening Roblox Studio..."
    start "" "$ROBLOX_STUDIO_PATH" "$TEST_PLACE"
fi

# echo "Do you want to serve ROJO? (y/n)"
# read USER_INPUT
# if [ "$USER_INPUT" = "y" ]; then
#     echo "Serving ROJO..."
#     rojo serve test.project.json
# fi

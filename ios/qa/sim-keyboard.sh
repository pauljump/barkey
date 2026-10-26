#!/bin/bash
# Enables the BARkey keyboard in a simulator (writes the same preference Settings does) and disconnects the
# hardware keyboard so the software keyboard shows. Usage: qa/sim-keyboard.sh <udid>
set -euo pipefail
SIM="$1"
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false
xcrun simctl spawn "$SIM" defaults write com.apple.Preferences AppleKeyboards -array "en_US@sw=QWERTY;hw=Automatic" "emoji@sw=Emoji" "com.barkey.app.keyboard"
xcrun simctl spawn "$SIM" defaults write com.apple.Preferences AppleKeyboardsExpanded -int 1
# Full Access for the extension (what the "Allow Full Access" switch writes).
xcrun simctl spawn "$SIM" defaults write com.apple.Preferences KeyboardsAllowedToUseOpenAccess -array "com.barkey.app.keyboard" 2>/dev/null || true
echo "BARkey keyboard enabled on $SIM"

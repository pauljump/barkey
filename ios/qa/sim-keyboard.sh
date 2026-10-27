#!/bin/bash
# Prepares a simulator for the keyboard UI tests: software keyboard on (hardware keyboard disconnected) and a reboot
# so the change takes. The tests themselves add BARkey and allow Full Access through the real Settings app.
# Usage: qa/sim-keyboard.sh <udid>
set -euo pipefail
SIM="$1"
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false
xcrun simctl shutdown "$SIM" >/dev/null 2>&1 || true
sleep 2
xcrun simctl boot "$SIM"
sleep 8
echo "simulator $SIM ready for keyboard tests"

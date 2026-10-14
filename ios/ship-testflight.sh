#!/bin/bash
# Archive BARkey and upload it to App Store Connect (TestFlight). Runs headless.
# Export uses Apple's cloud signing through the API key: the dedicated signing
# keychain is dropped from the search list for the export (and restored after),
# so no local distribution key, keychain unlock or GUI prompt is needed.
set -eo pipefail
cd "$(dirname "$0")"
set -a; . "$HOME/.secrets/monorepo.env"; set +a
set -u
KEY="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
OUT=/tmp/barkey-ship
rm -rf "$OUT" && mkdir -p "$OUT"
cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>99US464DK4</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
  <key>uploadSymbols</key><true/>
</dict></plist>
PLIST
AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$KEY" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
xcodegen generate -q
xcodebuild archive -project BARkey.xcodeproj -scheme BARkey -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$OUT/BARkey.xcarchive" "${AUTH[@]}"
SAVED_KEYCHAINS=()
while IFS= read -r kc; do SAVED_KEYCHAINS+=("$(echo "$kc" | tr -d ' "')"); done < <(security list-keychains -d user)
restore_keychains() { security list-keychains -d user -s "${SAVED_KEYCHAINS[@]}"; }
trap restore_keychains EXIT
security list-keychains -d user -s "$HOME/Library/Keychains/login.keychain-db"
xcodebuild -exportArchive -archivePath "$OUT/BARkey.xcarchive" -exportPath "$OUT/export" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" "${AUTH[@]}"
echo "Uploaded. Apple takes ~10-30 min to process before it shows in TestFlight."

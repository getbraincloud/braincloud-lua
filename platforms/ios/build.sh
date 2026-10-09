#!/usr/bin/env bash
#  Builds a LÖVE game that uses the brainCloud Lua SDK as an iOS app.
#  iOS can't load the SDK's native pack, so this builds LÖVE 11.5 for iOS with LuaSec + OpenSSL
#  linked in (lib/*/libbcssl.a + love-11.5-ios.patch), then embeds your game.
#
#  platforms/ios/build.sh <game folder | game.love> --team <TEAM_ID> --bundle-id <id> [options]
#    --name <name>        home-screen name (default: game folder name)
#    --icon <png>         app icon, square, ideally 1024x1024
#    --version <x.y.z>    CFBundleShortVersionString (default 1.0)
#    --build <n>          CFBundleVersion (default 1)
#    --out <dir>          output folder (default ./build/ios)
#    --simulator          build for the iOS Simulator (no signing needed)
#    --install            install on a connected iPhone/iPad (or the booted simulator)
#    --device <udid>      device to install on (default: first paired device)
#    --launch             launch after installing
#    --archive            App Store build: .xcarchive + exported .ipa
#  Needs Xcode, signed in (Xcode > Settings > Accounts) to the team you pass.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOVE_VERSION=11.5
IOS_MIN=15.0

GAME="" TEAM="" BUNDLE="" NAME="" ICON="" VERSION=1.0 BUILD=1 OUT="$PWD/build/ios"
SIM=0 INSTALL=0 LAUNCH=0 ARCHIVE=0 DEVICE=""
while [ $# -gt 0 ]; do
	case "$1" in
		--team) TEAM="$2"; shift ;;
		--bundle-id) BUNDLE="$2"; shift ;;
		--name) NAME="$2"; shift ;;
		--icon) ICON="$2"; shift ;;
		--version) VERSION="$2"; shift ;;
		--build) BUILD="$2"; shift ;;
		--out) OUT="$2"; shift ;;
		--device) DEVICE="$2"; shift ;;
		--simulator) SIM=1 ;;
		--install) INSTALL=1 ;;
		--launch) INSTALL=1; LAUNCH=1 ;;
		--archive) ARCHIVE=1 ;;
		-h|--help) sed -n '2,18p' "$0" | sed 's/^#  \{0,1\}//'; exit 0 ;;
		-*) echo "unknown option $1" >&2; exit 1 ;;
		*) GAME="$1" ;;
	esac
	shift
done

fail() { echo "error: $*" >&2; exit 1; }
[ -n "$GAME" ] && [ -e "$GAME" ] || fail "pass your game folder or .love file (see --help)"
[ -n "$BUNDLE" ] || fail "--bundle-id is required (e.g. com.yourcompany.yourgame)"
[ $SIM = 1 ] || [ -n "$TEAM" ] || fail "--team is required for device builds (your Apple Developer team id)"
[ $SIM = 1 ] && [ $ARCHIVE = 1 ] && fail "--archive is a device build; drop --simulator"
command -v xcodebuild >/dev/null || fail "Xcode is required"
GAME="$(cd "$(dirname "$GAME")" && pwd)/$(basename "$GAME")"
[ -n "$NAME" ] || NAME="$(basename "${GAME%.love}")"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

SDK=iphoneos
[ $SIM = 1 ] && SDK=iphonesimulator
LIB="$HERE/lib/$SDK/libbcssl.a"
[ -f "$LIB" ] || fail "missing $LIB"

# LÖVE iOS source (includes its prebuilt dependencies), cached between builds
CACHE="${BRAINCLOUD_LUA_CACHE:-$HOME/Library/Caches/braincloud-lua}"
SRC="$CACHE/love-$LOVE_VERSION-ios-source"
if [ ! -d "$SRC" ]; then
	echo "Downloading LÖVE $LOVE_VERSION iOS source..."
	mkdir -p "$CACHE"
	curl -fsSL -o "$CACHE/love-ios.zip" "https://github.com/love2d/love/releases/download/$LOVE_VERSION/love-$LOVE_VERSION-ios-source.zip"
	unzip -q -o "$CACHE/love-ios.zip" -d "$CACHE" -x '__MACOSX/*'
	rm "$CACHE/love-ios.zip"
fi

# Working copy: patched for LuaSec, branded with your name and icon
TREE="$OUT/love-ios"
rsync -a --delete "$SRC/" "$TREE/"
(cd "$TREE" && patch -p1 -s < "$HERE/love-$LOVE_VERSION-ios.patch")
XC="$TREE/platform/xcode"
PLIST="$XC/ios/love-ios.plist"
PB=/usr/libexec/PlistBuddy
$PB -c "Set :CFBundleDisplayName $NAME" -c "Set :CFBundleVersion \$(CURRENT_PROJECT_VERSION)" "$PLIST"
# drop LÖVE's own "open .love files" document types and file sharing
for key in CFBundleDocumentTypes UTExportedTypeDeclarations UIFileSharingEnabled; do
	$PB -c "Delete :$key" "$PLIST" 2>/dev/null || true
done
if [ -n "$ICON" ]; then
	SET="$XC/Images.xcassets/iOS AppIcon.appiconset"
	rm -f "$SET"/*.png
	# App Store icons can't have alpha: round-trip through JPEG
	sips -s format jpeg -z 1024 1024 "$ICON" --out "$OUT/icon.jpg" >/dev/null
	sips -s format png "$OUT/icon.jpg" --out "$SET/icon-1024.png" >/dev/null
	rm "$OUT/icon.jpg"
	cat > "$SET/Contents.json" <<-EOF
	{ "images": [ { "filename": "icon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024" } ],
	  "info": { "author": "xcode", "version": 1 } }
	EOF
fi

# The game: a folder is zipped without the desktop native libraries (unused on iOS)
LOVEFILE="$OUT/game.love"
if [ -d "$GAME" ]; then
	rm -f "$LOVEFILE"
	(cd "$GAME" && zip -qr -9 "$LOVEFILE" . -x '.git*' '*.DS_Store' '*braincloud/native/*/*' 'build/*' '.braincloud/*' '.vscode/*')
else
	cp "$GAME" "$LOVEFILE"
fi

cat > "$OUT/braincloud.xcconfig" <<EOF
PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE
DEVELOPMENT_TEAM = $TEAM
CODE_SIGN_STYLE = Automatic
CODE_SIGN_IDENTITY = Apple Development
IPHONEOS_DEPLOYMENT_TARGET = $IOS_MIN
MARKETING_VERSION = $VERSION
CURRENT_PROJECT_VERSION = $BUILD
OTHER_LDFLAGS = \$(inherited) "$LIB"
EOF

XB=(xcodebuild -project "$XC/love.xcodeproj" -scheme love-ios -configuration Release
	-derivedDataPath "$OUT/DerivedData" -xcconfig "$OUT/braincloud.xcconfig" -allowProvisioningUpdates)
LOG="$OUT/xcodebuild.log"
run_xcodebuild() {
	echo "Building LÖVE for iOS (log: $LOG)..."
	if ! "${XB[@]}" "$@" > "$LOG" 2>&1; then
		grep -E "error:" "$LOG" | sort -u | head -20 >&2
		fail "xcodebuild failed, see $LOG"
	fi
}

# Adds the game to a built .app and signs it again (xcodebuild signed it without the game).
embed_game() {
	local app="$1"
	cp "$LOVEFILE" "$app/game.love"
	if [ $SIM = 1 ]; then
		codesign -f -s - "$app" 2>/dev/null
	else
		local identity
		identity="$(codesign -dvv "$app" 2>&1 | sed -n 's/^Authority=//p' | head -1)"
		codesign -d --entitlements :- "$app" > "$OUT/entitlements.plist" 2>/dev/null
		codesign -f -s "$identity" --entitlements "$OUT/entitlements.plist" "$app" 2>/dev/null
	fi
}

if [ $ARCHIVE = 1 ]; then
	ARCHIVE_PATH="$OUT/$NAME.xcarchive"
	rm -rf "$ARCHIVE_PATH" "$OUT/export"
	run_xcodebuild -destination 'generic/platform=iOS' -archivePath "$ARCHIVE_PATH" archive
	embed_game "$ARCHIVE_PATH/Products/Applications/love.app"
	cat > "$OUT/ExportOptions.plist" <<-EOF
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0"><dict>
	<key>method</key><string>app-store-connect</string>
	<key>teamID</key><string>$TEAM</string>
	<key>signingStyle</key><string>automatic</string>
	</dict></plist>
	EOF
	xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportPath "$OUT/export" \
		-exportOptionsPlist "$OUT/ExportOptions.plist" -allowProvisioningUpdates >> "$LOG" 2>&1 || fail "export failed, see $LOG"
	echo "Built $ARCHIVE_PATH"
	echo "App Store package: $(ls "$OUT"/export/*.ipa)"
	echo "Upload it with Transporter or: xcrun altool --upload-app -t ios -f <ipa> ..."
	exit 0
fi

if [ $SIM = 1 ]; then
	run_xcodebuild -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
	BUILT="$OUT/DerivedData/Build/Products/Release-iphonesimulator/love.app"
else
	run_xcodebuild -destination 'generic/platform=iOS' build
	BUILT="$OUT/DerivedData/Build/Products/Release-iphoneos/love.app"
fi
embed_game "$BUILT"
APP="$OUT/$NAME.app"
rm -rf "$APP"
ditto "$BUILT" "$APP"
echo "Built $APP"

[ $INSTALL = 1 ] || exit 0
if [ $SIM = 1 ]; then
	if ! xcrun simctl list devices booted | grep Booted >/dev/null; then
		DEVICE="${DEVICE:-$(xcrun simctl list devices available | sed -n 's/^ *iPhone[^(]*(\([0-9A-F-]*\)).*/\1/p' | tail -1)}"
		xcrun simctl boot "$DEVICE"
		open -a Simulator
	fi
	xcrun simctl install booted "$APP"
	[ $LAUNCH = 1 ] && xcrun simctl launch booted "$BUNDLE"
else
	if [ -z "$DEVICE" ]; then
		xcrun devicectl list devices --json-output "$OUT/devices.json" >/dev/null 2>&1 || true
		DEVICE="$(python3 -c '
import json, sys
for d in json.load(open(sys.argv[1]))["result"]["devices"]:
    if d.get("hardwareProperties", {}).get("reality") == "physical" and d.get("connectionProperties", {}).get("pairingState") == "paired":
        print(d["hardwareProperties"]["udid"]); break
' "$OUT/devices.json" 2>/dev/null || true)"
		[ -n "$DEVICE" ] || fail "no paired iPhone/iPad found (connect one, or pass --device <udid>)"
	fi
	xcrun devicectl device install app --device "$DEVICE" "$APP" >/dev/null
	echo "Installed on $DEVICE"
	[ $LAUNCH = 1 ] && xcrun devicectl device process launch --device "$DEVICE" --terminate-existing "$BUNDLE" >/dev/null
fi
exit 0

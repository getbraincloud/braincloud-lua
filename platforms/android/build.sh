#!/usr/bin/env bash
#  Builds a LÖVE game that uses the brainCloud Lua SDK as an Android APK by repackaging the
#  official LÖVE 11.5 APK (apktool) with your game, package name, label and icon. The SDK's
#  braincloud/native/android-arm64/ssl.so travels inside the game and loads like on desktop.
#
#  platforms/android/build.sh <game folder | game.love> --package <com.you.game> [options]
#    --name <name>            launcher label (default: game folder name)
#    --icon <png>             app icon, square
#    --version <x.y.z>        versionName (default 1.0)
#    --version-code <n>       versionCode (default 1)
#    --out <dir>              output folder (default ./build/android)
#    --keystore <file>        release keystore (default: ~/.android/debug.keystore)
#    --key-alias <alias>      key alias in --keystore (password from BC_KEYSTORE_PASS)
#    --install                install with adb on the connected device/emulator
#    --device <serial>        adb device to use
#    --launch                 install and launch
#  Needs Java 17+ and the Android SDK build-tools (ANDROID_HOME, else ~/Library/Android/sdk).
#  For Google Play (.aab), build LÖVE's love-android project with this game.love instead.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOVE_VERSION=11.5
APKTOOL_VERSION=2.10.0

GAME="" PKG="" NAME="" ICON="" VERSION=1.0 CODE=1 OUT="$PWD/build/android"
KEYSTORE="" ALIAS="" INSTALL=0 LAUNCH=0 DEVICE=""
while [ $# -gt 0 ]; do
	case "$1" in
		--package) PKG="$2"; shift ;;
		--name) NAME="$2"; shift ;;
		--icon) ICON="$2"; shift ;;
		--version) VERSION="$2"; shift ;;
		--version-code) CODE="$2"; shift ;;
		--out) OUT="$2"; shift ;;
		--keystore) KEYSTORE="$2"; shift ;;
		--key-alias) ALIAS="$2"; shift ;;
		--device) DEVICE="$2"; shift ;;
		--install) INSTALL=1 ;;
		--launch) INSTALL=1; LAUNCH=1 ;;
		-h|--help) sed -n '2,19p' "$0" | sed 's/^#  \{0,1\}//'; exit 0 ;;
		-*) echo "unknown option $1" >&2; exit 1 ;;
		*) GAME="$1" ;;
	esac
	shift
done

fail() { echo "error: $*" >&2; exit 1; }
[ -n "$GAME" ] && [ -e "$GAME" ] || fail "pass your game folder or .love file (see --help)"
[[ "$PKG" =~ ^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$ ]] || fail "--package must look like com.yourcompany.yourgame"
GAME="$(cd "$(dirname "$GAME")" && pwd)/$(basename "$GAME")"
[ -n "$NAME" ] || NAME="$(basename "${GAME%.love}")"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

# Tools: Java (JAVA_HOME, PATH, or Android Studio's), build-tools, apktool (downloaded)
JAVA="${JAVA_HOME:+$JAVA_HOME/bin/java}"
[ -n "$JAVA" ] || JAVA="$(command -v java || true)"
[ -n "$JAVA" ] && "$JAVA" -version >/dev/null 2>&1 || JAVA="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java"
[ -x "$JAVA" ] || fail "Java 17+ is required (set JAVA_HOME)"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
BT="$(ls -d "$SDK"/build-tools/* 2>/dev/null | sort -V | tail -1)"
[ -x "$BT/apksigner" ] || fail "Android SDK build-tools not found (set ANDROID_HOME)"
ADB="$SDK/platform-tools/adb"
[ -x "$ADB" ] || ADB="$(command -v adb || true)"

CACHE="${BRAINCLOUD_LUA_CACHE:-$HOME/Library/Caches/braincloud-lua}"
mkdir -p "$CACHE"
APKTOOL="$CACHE/apktool_$APKTOOL_VERSION.jar"
[ -f "$APKTOOL" ] || curl -fsSL -o "$APKTOOL" "https://github.com/iBotPeaches/Apktool/releases/download/v$APKTOOL_VERSION/apktool_$APKTOOL_VERSION.jar"
SRC="$CACHE/love-$LOVE_VERSION-android"
if [ ! -d "$SRC" ]; then
	echo "Downloading LÖVE $LOVE_VERSION for Android..."
	curl -fsSL -o "$CACHE/love-android.apk" "https://github.com/love2d/love/releases/download/$LOVE_VERSION/love-$LOVE_VERSION-android.apk"
	"$JAVA" -jar "$APKTOOL" d -f -q -o "$SRC" "$CACHE/love-android.apk"
	rm "$CACHE/love-android.apk"
fi

# Working copy: embed mode, your package/name/version/icon
TREE="$OUT/apk-src"
rsync -a --delete "$SRC/" "$TREE/"
MANIFEST="$TREE/AndroidManifest.xml"
# signature permission + provider authority must be unique per app, or a second LÖVE game won't install
sed -i '' -e "s/org\.love2d\.android\.DYNAMIC_RECEIVER/$PKG.DYNAMIC_RECEIVER/g" \
	-e "s/android:authorities=\"org\.love2d\.android\./android:authorities=\"$PKG./" \
	-e "s/LÖVE for Android/$(printf '%s' "$NAME" | sed 's/[&/\]/\\&/g')/g" "$MANIFEST"
# only the launcher: drop LÖVE's "open .love files" intent filters
perl -0pi -e 's#\s*<intent-filter>\s*<action android:name="android.intent.action.VIEW"/>.*?</intent-filter>##gs' "$MANIFEST"
sed -i '' 's#<bool name="embed">false</bool>#<bool name="embed">true</bool>#' "$TREE/res/values/bools.xml"
sed -i '' -e "s/renameManifestPackage: .*/renameManifestPackage: $PKG/" \
	-e "s/versionCode: .*/versionCode: $CODE/" -e "s/versionName: .*/versionName: $VERSION/" "$TREE/apktool.yml"
if [ -n "$ICON" ]; then
	for png in "$TREE"/res/drawable-*/love.png; do
		size="$(sips -g pixelWidth "$png" | awk '/pixelWidth/ {print $2}')"
		sips -s format png -z "$size" "$size" "$ICON" --out "$png" >/dev/null
	done
fi

# The game: only the Android native libraries are kept from braincloud/native
mkdir -p "$TREE/assets"
LOVEFILE="$TREE/assets/game.love"
if [ -d "$GAME" ]; then
	(cd "$GAME" && zip -qr -9 "$LOVEFILE" . -x '.git*' '*.DS_Store' 'build/*' '.braincloud/*' '.vscode/*' \
		'*braincloud/native/macos/*' '*braincloud/native/windows-*' '*braincloud/native/linux-*')
else
	cp "$GAME" "$LOVEFILE"
fi
unzip -Z1 "$LOVEFILE" "*native/android-arm64/ssl.so" >/dev/null 2>&1 || echo "warning: game has no braincloud/native/android-arm64/ssl.so; RTT and HTTPS won't work" >&2

echo "Packaging APK..."
SAFE="$(printf '%s' "$NAME" | tr -c 'A-Za-z0-9._-' '_')"
UNSIGNED="$OUT/$SAFE-unsigned.apk"
APK="$OUT/$SAFE.apk"
"$JAVA" -jar "$APKTOOL" b -q -o "$UNSIGNED" "$TREE" || fail "apktool build failed"
"$BT/zipalign" -p -f 4 "$UNSIGNED" "$OUT/$SAFE-aligned.apk"
rm "$UNSIGNED"

if [ -z "$KEYSTORE" ]; then
	KEYSTORE="$HOME/.android/debug.keystore" ALIAS=androiddebugkey
	export BC_KEYSTORE_PASS=android
	if [ ! -f "$KEYSTORE" ]; then
		mkdir -p "$(dirname "$KEYSTORE")"
		"$(dirname "$JAVA")/keytool" -genkeypair -keystore "$KEYSTORE" -storepass android -keypass android -alias androiddebugkey \
			-keyalg RSA -validity 10000 -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
	fi
fi
[ -n "$ALIAS" ] || fail "--key-alias is required with --keystore"
[ -n "${BC_KEYSTORE_PASS:-}" ] || fail "set BC_KEYSTORE_PASS to the keystore password"
"$BT/apksigner" sign --ks "$KEYSTORE" --ks-key-alias "$ALIAS" --ks-pass env:BC_KEYSTORE_PASS --out "$APK" "$OUT/$SAFE-aligned.apk"
rm -f "$OUT/$SAFE-aligned.apk" "$APK.idsig"
echo "Built $APK"

[ $INSTALL = 1 ] || exit 0
[ -n "$ADB" ] || fail "adb not found (Android SDK platform-tools)"
ADBD=("$ADB")
[ -n "$DEVICE" ] && ADBD+=(-s "$DEVICE")
"${ADBD[@]}" install -r "$APK" >/dev/null
echo "Installed $PKG"
if [ $LAUNCH = 1 ]; then
	"${ADBD[@]}" shell am start -S -n "$PKG/org.love2d.android.GameActivity" >/dev/null
fi
exit 0

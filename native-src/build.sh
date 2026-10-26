#!/usr/bin/env bash
#  Builds the native pack into braincloud/native/<platform>/:
#    ssl.so/.dll  - LuaSec 1.3.2 with OpenSSL 3 linked in statically (TLS sockets + HTTPS)
#    https.so     - lua-https (optional; LÖVE 12 has it built in as love.https)
#  Neither links a Lua library: they resolve Lua from the host (LÖVE's LuaJIT) at load time.
#
#    platforms/ios/lib/*/libbcssl.a - LuaSec + OpenSSL static, for the patched LÖVE iOS build
#
#
#  ./native-src/build.sh [macos] [linux-x64] [windows-x64] [ios] [android-arm64]     (default: all)
#  macOS host; linux uses Docker, windows uses mingw-w64 (brew install mingw-w64), ios uses Xcode,
#  android uses the NDK (ANDROID_NDK_ROOT, else the newest under ~/Library/Android/sdk/ndk).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${BC_NATIVE_WORK:-$ROOT/native-src/.work}"
OUT="$ROOT/braincloud/native"

OPENSSL_VERSION=3.3.2
LUASEC_TAG=v1.3.2
LOVE_VERSION=11.5

IOS_MIN=15.0
ANDROID_API=21

TARGETS=("$@")
[ ${#TARGETS[@]} -eq 0 ] && TARGETS=(macos linux-x64 windows-x64 ios android-arm64)

mkdir -p "$WORK"
cd "$WORK"

fetch() {
	[ -d openssl-$OPENSSL_VERSION ] || { curl -sL "https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VERSION/openssl-$OPENSSL_VERSION.tar.gz" | tar xz; }
	[ -d luasec ] || git clone -q --depth 1 --branch $LUASEC_TAG https://github.com/lunarmodules/luasec.git
	[ -d lua-https ] || git clone -q --depth 1 https://github.com/love2d/lua-https.git
	[ -d LuaJIT ] || git clone -q --depth 1 --branch v2.1 https://github.com/LuaJIT/LuaJIT.git
}

LUASEC_SRC="config.c context.c ec.c options.c ssl.c x509.c luasocket/buffer.c luasocket/io.c luasocket/timeout.c"

openssl_build() { # <target dir> <Configure target> [extra Configure args...]
	local dir="$1" target="$2"
	[ -f "$dir/lib/libssl.a" ] && return
	rm -rf "openssl-build-$target" && cp -R openssl-$OPENSSL_VERSION "openssl-build-$target"
	(cd "openssl-build-$target" && ./Configure "$target" no-shared no-tests no-docs -fPIC "${@:3}" --prefix="$dir" --libdir=lib >/dev/null && make -j8 >/dev/null && make install_sw >/dev/null)
}

build_macos() {
	local libs=()
	for arch in arm64 x86_64; do
		local target=darwin64-$arch-cc
		[ $arch = x86_64 ] && target=darwin64-x86_64-cc
		openssl_build "$WORK/openssl-mac-$arch" "$target"
		(cd luasec/src && clang -arch $arch -mmacosx-version-min=10.13 -O2 -fPIC -shared -undefined dynamic_lookup -DWITH_LUASOCKET \
			-I"$WORK/LuaJIT/src" -I"$WORK/openssl-mac-$arch/include" -I. -Iluasocket $LUASEC_SRC luasocket/usocket.c \
			"$WORK/openssl-mac-$arch/lib/libssl.a" "$WORK/openssl-mac-$arch/lib/libcrypto.a" -o "$WORK/ssl-$arch.so")
		libs+=("$WORK/ssl-$arch.so")
	done
	mkdir -p "$OUT/macos"
	lipo -create "${libs[@]}" -output "$OUT/macos/ssl.so"
	cmake -S lua-https -B https-mac -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13 \
		-DLUAJIT_INCLUDE_DIR="$WORK/LuaJIT/src" -DLUAJIT_LIBRARY=/usr/lib/libSystem.dylib -DCMAKE_MODULE_LINKER_FLAGS="-undefined dynamic_lookup" >/dev/null
	cmake --build https-mac -j8 >/dev/null
	cp https-mac/src/https.so "$OUT/macos/https.so"
	strip -x "$OUT/macos/ssl.so" "$OUT/macos/https.so"
	echo "macos: $(lipo -archs "$OUT/macos/ssl.so")"
}

build_linux() {
	mkdir -p "$OUT/linux-x64"
	docker run --rm --platform linux/amd64 -v "$WORK:/work" -v "$OUT/linux-x64:/out" ubuntu:20.04 bash -c "
		set -e
		export DEBIAN_FRONTEND=noninteractive
		apt-get update -qq >/dev/null && apt-get install -y -qq build-essential perl cmake libcurl4-openssl-dev >/dev/null
		cd /work
		if [ ! -f openssl-linux-x64/lib/libssl.a ]; then
			rm -rf ob && cp -R openssl-$OPENSSL_VERSION ob && cd ob
			./Configure linux-x86_64 no-shared no-tests no-docs -fPIC --prefix=/work/openssl-linux-x64 --libdir=lib >/dev/null && make -j8 >/dev/null && make install_sw >/dev/null
			cd /work
		fi
		cd luasec/src
		gcc -O2 -fPIC -shared -DWITH_LUASOCKET -I/work/LuaJIT/src -I/work/openssl-linux-x64/include -I. -Iluasocket $LUASEC_SRC luasocket/usocket.c \
			/work/openssl-linux-x64/lib/libssl.a /work/openssl-linux-x64/lib/libcrypto.a -ldl -lpthread -o /out/ssl.so
		cd /work
		cmake -S lua-https -B https-linux -DCMAKE_BUILD_TYPE=Release -DLUAJIT_INCLUDE_DIR=/work/LuaJIT/src -DLUAJIT_LIBRARY=/usr/lib/x86_64-linux-gnu/libc.so -DOPENSSL_ROOT_DIR=/work/openssl-linux-x64 >/dev/null
		cmake --build https-linux -j8 >/dev/null
		cp https-linux/src/https.so /out/https.so
		strip --strip-unneeded /out/ssl.so /out/https.so
	"
	echo "linux-x64: built"
}

build_windows() {
	local cross=x86_64-w64-mingw32
	local loveZip="$WORK/love-$LOVE_VERSION-win64.zip"
	[ -f "$loveZip" ] || curl -sL -o "$loveZip" "https://github.com/love2d/love/releases/download/$LOVE_VERSION/love-$LOVE_VERSION-win64.zip"
	[ -f "$WORK/lua51.dll" ] || unzip -q -j -o "$loveZip" "*/lua51.dll" -d "$WORK"
	if [ ! -f "$WORK/openssl-win-x64/lib/libssl.a" ]; then
		rm -rf ow && cp -R openssl-$OPENSSL_VERSION ow
		(cd ow && ./Configure mingw64 no-shared no-tests no-docs --cross-compile-prefix=$cross- --prefix="$WORK/openssl-win-x64" --libdir=lib >/dev/null && make -j8 >/dev/null && make install_sw >/dev/null)
	fi
	mkdir -p "$OUT/windows-x64"
	# links LÖVE's own lua51.dll, so the module shares the game's Lua state
	(cd luasec/src && $cross-gcc -O2 -shared -DWITH_LUASOCKET -DLUASOCKET_INET_PTON -D_WIN32_WINNT=0x0601 \
		-I"$WORK/LuaJIT/src" -I"$WORK/openssl-win-x64/include" -I. -Iluasocket $LUASEC_SRC luasocket/wsocket.c \
		"$WORK/openssl-win-x64/lib/libssl.a" "$WORK/openssl-win-x64/lib/libcrypto.a" "$WORK/lua51.dll" \
		-lws2_32 -lcrypt32 -luser32 -ladvapi32 -static-libgcc -o "$OUT/windows-x64/ssl.dll")
	$cross-strip --strip-unneeded "$OUT/windows-x64/ssl.dll"
	echo "windows-x64: built"
}

luasec_ios() { # <sdk> <arch> <openssl dir> <out .a>
	local sdk=$1 arch=$2 ossl=$3 out=$4
	local obj="$WORK/luasec-$sdk-$arch" target=$arch-apple-ios$IOS_MIN
	[ $sdk = iphonesimulator ] && target=$target-simulator
	rm -rf "$obj" && mkdir -p "$obj"
	for f in $LUASEC_SRC luasocket/usocket.c; do
		xcrun --sdk $sdk clang -target $target -O2 -fPIC -DWITH_LUASOCKET -Wno-deprecated-declarations \
			-I"$WORK/LuaJIT/src" -I"$ossl/include" -Iluasec/src -Iluasec/src/luasocket -c "luasec/src/$f" -o "$obj/$(echo $f | tr / _).o"
	done
	libtool -static -o "$out" "$obj"/*.o "$ossl/lib/libssl.a" "$ossl/lib/libcrypto.a" 2>/dev/null
}

# iOS can't load .so modules: a static lib the patched LÖVE iOS build links in (platforms/ios).
build_ios() {
	export IPHONEOS_DEPLOYMENT_TARGET=$IOS_MIN
	local lib="$ROOT/platforms/ios/lib"
	mkdir -p "$lib/iphoneos" "$lib/iphonesimulator"
	openssl_build "$WORK/openssl-ios-arm64" ios64-xcrun no-async
	luasec_ios iphoneos arm64 "$WORK/openssl-ios-arm64" "$WORK/libbcssl-iphoneos.a"
	local sims=()
	for arch in arm64 x86_64; do
		openssl_build "$WORK/openssl-iossim-$arch" iossimulator-$arch-xcrun no-async
		luasec_ios iphonesimulator $arch "$WORK/openssl-iossim-$arch" "$WORK/libbcssl-sim-$arch.a"
		sims+=("$WORK/libbcssl-sim-$arch.a")
	done
	strip -S -o "$lib/iphoneos/libbcssl.a" "$WORK/libbcssl-iphoneos.a"
	lipo -create "${sims[@]}" -output "$WORK/libbcssl-iphonesimulator.a"
	strip -S -o "$lib/iphonesimulator/libbcssl.a" "$WORK/libbcssl-iphonesimulator.a"
	echo "ios: $(lipo -archs "$lib/iphoneos/libbcssl.a") / simulator $(lipo -archs "$lib/iphonesimulator/libbcssl.a")"
}

# Links LÖVE's own liblove.so (LuaJIT is inside it), so the module shares the game's Lua state.
build_android() {
	local ndk="${ANDROID_NDK_ROOT:-$(ls -d "$HOME/Library/Android/sdk/ndk/"* 2>/dev/null | sort -V | tail -1)}"
	[ -d "$ndk" ] || { echo "android: install the NDK or set ANDROID_NDK_ROOT"; exit 1; }
	local tc="$ndk/toolchains/llvm/prebuilt/darwin-x86_64/bin"
	local apk="$WORK/love-$LOVE_VERSION-android.apk"
	[ -f "$apk" ] || curl -sL -o "$apk" "https://github.com/love2d/love/releases/download/$LOVE_VERSION/love-$LOVE_VERSION-android.apk"
	unzip -q -o -j "$apk" "lib/arm64-v8a/liblove.so" -d "$WORK/love-android-arm64"
	(export ANDROID_NDK_ROOT="$ndk" PATH="$tc:$PATH"; openssl_build "$WORK/openssl-android-arm64" android-arm64)
	mkdir -p "$OUT/android-arm64"
	(cd luasec/src && "$tc/aarch64-linux-android$ANDROID_API-clang" -O2 -fPIC -shared -DWITH_LUASOCKET -Wno-deprecated-declarations \
		-DluaL_setfuncs=bc_luaL_setfuncs -I"$WORK/LuaJIT/src" -I"$WORK/openssl-android-arm64/include" -I. -Iluasocket \
		$LUASEC_SRC luasocket/usocket.c "$ROOT/native-src/compat/setfuncs.c" \
		"$WORK/openssl-android-arm64/lib/libssl.a" "$WORK/openssl-android-arm64/lib/libcrypto.a" \
		-L"$WORK/love-android-arm64" -llove -o "$OUT/android-arm64/ssl.so")
	"$tc/llvm-strip" --strip-unneeded "$OUT/android-arm64/ssl.so"
	echo "android-arm64: built"
}

fetch
for t in "${TARGETS[@]}"; do
	case "$t" in
		macos) build_macos ;;
		linux-x64) build_linux ;;
		windows-x64) build_windows ;;
		ios) build_ios ;;
		android-arm64) build_android ;;
		*) echo "unknown target $t"; exit 1 ;;
	esac
done
[ -f "$OUT/cacert.pem" ] || curl -sL -o "$OUT/cacert.pem" https://curl.se/ca/cacert.pem
echo "Done: $OUT"

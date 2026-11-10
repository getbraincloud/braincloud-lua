# brainCloud Lua SDK

The [brainCloud](https://getbraincloud.com) client for Lua games: authentication, cloud data,
leaderboards, lobbies, chat, real-time events (RTT) and relay multiplayer.

- **LÖVE 11.4+ and LÖVE 12** (LuaJIT). Desktop: macOS, Windows, Linux.
- Plain **LuaJIT / Lua 5.1** with LuaSocket + LuaSec (servers, tools, other engines).
- Nothing blocks: requests run in the background and callbacks fire from `update()`.

## Install

1. Download `braincloud-lua-<version>.zip` from the [Releases](https://github.com/getbraincloud/braincloud-lua/releases) page.
2. Copy the `braincloud/` folder into your game, next to `main.lua`.

That's it: the folder includes the native networking pack for each desktop platform
(`braincloud/native/`), which LÖVE 11 needs for HTTPS and every LÖVE version needs for
real-time features.

## Connect your app

Run the setup tool from your game folder. It signs you in to brainCloud in the browser, lets
you pick or create an app, and writes `braincloud_config.lua`:

```sh
love path/to/braincloud-lua/tools/braincloud-setup.love .
```

`braincloud_config.lua` is added to your `.gitignore`. Rerun the tool to switch apps, or
`luajit tools/setup/cli.lua --refresh` in CI (with `BRAINCLOUD_APP_ID`,
`BRAINCLOUD_BUILDER_EMAIL`, `BRAINCLOUD_BUILDER_API_KEY`, `BRAINCLOUD_TEAM_ID`).

## Use it

```lua
local BrainCloud = require("braincloud")
local bc = BrainCloud.new()

function love.load()
	bc:init() -- reads braincloud_config.lua
	bc:authenticateAnonymous(function(ok, response)
		if ok then
			print("profile", response.data.profileId)
			bc.leaderboard:postScoreToLeaderboard("highscores", 1200, {}, function(ok2, r)
				print("posted", ok2)
			end)
		else
			print("login failed", response.status_message)
		end
	end)
end

function love.update()
	bc:update() -- required: pumps networking and fires callbacks
end
```

Every call ends with a callback `function(success, response)`; `response` is the server's
`{ status, data }` (or `{ status, reason_code, status_message }` on failure). Calls made in
the same frame are bundled into one request.

Without the setup tool you can initialize directly:
`bc:initialize(appId, appSecret, appVersion, serverUrl)`.

### Saved logins

The wrapper remembers the profile and anonymous ids (in LÖVE's save directory), so
`authenticateAnonymous` returns the same player next launch. `bc:logout(true)` forgets them.
`smartSwitchAuthenticate*` moves an anonymous player to a real login.

### Real-time (RTT)

```lua
bc.rttService:enableRTT(function()
	bc.rttService:registerRTTChatCallback(function(msg) print(msg.operation, msg.data) end)
end, function(err) print("RTT lost", err) end)
```

Lobby, chat, presence, messaging and event callbacks: `registerRTTLobbyCallback`,
`registerRTTChatCallback`, `registerRTTPresenceCallback`, and so on.

### Relay multiplayer

Join a lobby, wait for `ROOM_READY` on the lobby callback, then connect:

```lua
bc.relay:registerRelayCallback(function(netId, data) end)
bc.relay:connect(bc.relay.ConnectionType.UDP, {
	host = room.connectData.address,
	port = room.connectData.ports.udp,
	passcode = room.passcode,
	lobbyId = room.lobbyId,
}, onConnected, onFailed)
bc.relay:sendToAll("hello", true, false, bc.relay.CHANNEL_HIGH_PRIORITY_1)
```

WebSocket (`ws`, with `ssl = true` for wss), TCP and UDP are supported, with reliable and
ordered channels. See the CursorParty example in
[lua-examples](https://github.com/getbraincloud/lua-examples) for a full lobby → relay game.

## Platform notes

| | REST | RTT / secure WebSocket | Relay TCP / UDP / ws |
|---|---|---|---|
| LÖVE 12 | built in (`love.https`) | native pack | built in (LuaSocket) |
| LÖVE 11.4 / 11.5 | native pack | native pack | built in (LuaSocket) |
| Web (love.js) | browser `fetch` via the web bridge | browser WebSocket via the web bridge | `wss` only |
| iOS (LÖVE 11.5) | LuaSec, linked in from `platforms/ios` | LuaSec, linked in from `platforms/ios` | built in (LuaSocket) |
| Android (LÖVE 11.5) | native pack | native pack | built in (LuaSocket) |
| Plain LuaJIT | LuaSec | LuaSec | LuaSocket |

- The native pack ships for macOS (universal), Windows x64, Linux x64 and Android arm64. iOS
  uses its own LÖVE build (see [iOS](#ios) below).
- **Web builds** need one extra file on the page; see [Web](#web-lovejs) below.
- Inside a packaged `.love` or fused executable, LÖVE can't load native libraries directly,
  so the SDK copies them to the save directory on first run.

## Web (love.js)

[love.js](https://github.com/Davidobot/love.js) runs a LÖVE 11 game in the browser. Browsers don't
let Lua open network connections, so the SDK hands its requests to a small JavaScript file on the
page, `braincloud-web.js` (the "web bridge"). Your game code doesn't change: the SDK detects
`love.system.getOS() == "Web"` and switches over by itself.

You need Node.js 18+.

**1. Make a `.love` without the native pack** (browsers can't load it). From your game folder:

```sh
zip -9 -r ../MyGame.love . -x 'braincloud/native/*'
```

**2. Convert it** (`-c` = compatibility mode, works on any web host; `-m` = memory, raise it for big games):

```sh
npx -y love.js@11.4.1 -c -m 134217728 -t "My Game" ../MyGame.love ../MyGame-web
```

**3. Copy the web bridge next to `index.html`:**

```sh
cp braincloud/web/braincloud-web.js ../MyGame-web/
```

**4. Edit `MyGame-web/index.html` in two places.** Load the bridge just before `game.js`:

```html
<script type="text/javascript" src="braincloud-web.js"></script>
<script type="text/javascript" src="game.js"></script>
```

Then find `Love(Module);` (inside `applicationLoad`) and attach the bridge just before it:

```js
var applicationLoad = function () {
  braincloudWeb.attach(Module);
  Love(Module);
};
```

love.js writes a fresh `index.html` every time it runs, so redo step 4 after each conversion.

**5. Test it from a local web server** (opening `index.html` straight from disk doesn't work):

```sh
cd ../MyGame-web && npx -y http-server -p 8080 -c-1
```

Open http://localhost:8080 and click the page once (browsers mute audio until you do). To publish,
upload the whole folder to any static host (S3, itch.io as an HTML game, GitHub Pages, ...).

**If it doesn't work**, open the browser console (Chrome: Cmd+Option+J / Ctrl+Shift+J):

- `bc:init()` succeeds but login never calls back, and the console shows lines starting with
  `@@BCWEB@@`: the bridge isn't attached. Check steps 3 and 4.
- Out-of-memory error: raise `-m` in step 2 (e.g. `268435456`).
- Make sure `bc:update()` runs every frame; on web that's how replies come back.

Web limits: love.js is LÖVE 11 running plain Lua 5.1 (no LuaJIT `ffi`, no `love.thread`, no native
modules), saves live in the browser's storage.

## iOS

iOS apps can't load the native pack, so LuaSec + OpenSSL are linked into LÖVE itself. Add two things
to your LÖVE 11.5 iOS build:

- `platforms/ios/lib/<iphoneos|iphonesimulator>/libbcssl.a`: link it into the `love-ios` target.
- `platforms/ios/love-11.5-ios.patch`: apply it to the LÖVE source (`patch -p1`). It preloads
  `ssl.core`, `ssl.context`, `ssl.x509` and `ssl.config` from that library.

The [CursorParty example](https://github.com/getbraincloud/lua-examples) has a build script that
does this end to end (download, patch, sign, install): `platforms/ios/build.sh`.

## Android

The native pack includes `android-arm64`, so the SDK works in any LÖVE 11.5 Android build of your
game with nothing extra. Ship `braincloud/native/android-arm64/ssl.so` inside your game, as on
desktop. The [CursorParty example](https://github.com/getbraincloud/lua-examples) repackages the
official LÖVE APK in `platforms/android/build.sh`. Set `t.window.resizable = false` in `conf.lua`
on phones, or the game follows the device's rotation.

## Tests

```sh
BC_TEST_IDS=path/to/test_ids.txt luajit tests/run.lua [Leaderboard,Relay] [-t testName]
tests/love/run.sh path/to/test_ids.txt   # the same flows inside LÖVE
```

## License

Apache 2.0 — see [LICENSE](LICENSE). Bundled third-party code is listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

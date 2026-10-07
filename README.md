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
| Plain LuaJIT | LuaSec | LuaSec | LuaSocket |

- The native pack ships for macOS (universal), Windows x64 and Linux x64. Mobile builds
  aren't supported yet.
- **Web builds** ([love.js](https://github.com/Davidobot/love.js), compatibility mode): the
  SDK detects `love.system.getOS() == "Web"` and routes HTTP and WebSockets through the page.
  Include `braincloud/web/braincloud-web.js` in the love.js `index.html` before `game.js`, and
  call `braincloudWeb.attach(Module)` just before `Love(Module)`. Leave `braincloud/native/`
  out of the web `.love`. Relay connects with `ssl = true` to the room's `secureAddress` /
  `ports.wss`.
- Inside a packaged `.love` or fused executable, LÖVE can't load native libraries directly,
  so the SDK copies them to the save directory on first run.

## Tests

```sh
BC_TEST_IDS=path/to/test_ids.txt luajit tests/run.lua [Leaderboard,Relay] [-t testName]
tests/love/run.sh path/to/test_ids.txt   # the same flows inside LÖVE
```

## License

Apache 2.0 — see [LICENSE](LICENSE). Bundled third-party code is listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

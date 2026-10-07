# Third-party notices

The brainCloud Lua SDK is Apache 2.0. It bundles the following, each under its own license.

| Component | Where | License |
|---|---|---|
| [md5.lua](https://github.com/kikito/md5.lua) | `braincloud/lib/md5.lua` | MIT |
| [LuaSec](https://github.com/lunarmodules/luasec) 1.3.2 | `braincloud/lib/luasec/`, `braincloud/native/*/ssl.*` | MIT (`braincloud/lib/luasec/LICENSE`) |
| [OpenSSL](https://www.openssl.org) 3 | statically linked into `braincloud/native/*/ssl.*` | Apache 2.0 |
| [lua-https](https://github.com/love2d/lua-https) | `braincloud/native/*/https.*` | zlib |
| [Mozilla CA bundle](https://curl.se/docs/caextract.html) | `braincloud/native/cacert.pem` | MPL 2.0 |

LuaSocket (MIT) is not bundled: LÖVE includes it, and plain Lua installs it from LuaRocks.

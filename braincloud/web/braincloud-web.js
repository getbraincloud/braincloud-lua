// Page side of the brainCloud Lua SDK's browser bridge (love.js builds). Include this before
// love.js and call braincloudWeb.attach(Module) before Love(Module): Lua's print() lines that
// start with @@BCWEB@@ are commands (fetch / WebSocket); results are queued and written into
// the game's save directory when Lua polls, in the same frame.
(function () {
  var PREFIX = '@@BCWEB@@'
  var INBOX = 'bcweb_in.json'
  var dir = null
  var queue = []
  var sockets = {}

  function b64ToBytes (s) {
    var bin = atob(s || '')
    var out = new Uint8Array(bin.length)
    for (var i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i)
    return out
  }

  function bytesToB64 (bytes) {
    var bin = ''
    for (var i = 0; i < bytes.length; i += 0x8000) {
      bin += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000))
    }
    return btoa(bin)
  }

  // FS_createDataFile stores one byte per char, so keep the inbox pure ASCII
  function asciiJson (value) {
    return JSON.stringify(value).replace(/[\u007f-￿]/g, function (c) {
      return '\\u' + ('0000' + c.charCodeAt(0).toString(16)).slice(-4)
    })
  }

  function httpRequest (m) {
    var controller = typeof AbortController !== 'undefined' ? new AbortController() : null
    var timer = controller && setTimeout(function () { controller.abort() }, (m.timeout || 30) * 1000)
    var init = { method: m.method || 'GET', headers: m.headers || {}, signal: controller && controller.signal }
    if (m.body) init.body = b64ToBytes(m.body)
    fetch(m.url, init).then(function (res) {
      return res.arrayBuffer().then(function (buf) {
        // fetch already decompressed the body, so don't pass content-encoding on
        queue.push({ id: m.id, op: 'http', code: res.status, body: bytesToB64(new Uint8Array(buf)) })
      })
    }).catch(function (e) {
      queue.push({ id: m.id, op: 'http', code: 0, err: String(e && e.message || e) })
    }).finally(function () { if (timer) clearTimeout(timer) })
  }

  // Region ping: time an opaque request to the region's target over https.
  function ping (m) {
    var url = /^https?:\/\//.test(m.url) ? m.url.replace(/^http:/, 'https:') : 'https://' + m.url
    var start = performance.now()
    fetch(url, { mode: 'no-cors', cache: 'no-store' }).then(function () {
      var ms = Math.round(performance.now() - start)
      queue.push({ id: m.id, op: 'http', code: 200, body: btoa(String(ms)) })
    }).catch(function (e) {
      queue.push({ id: m.id, op: 'http', code: 0, err: String(e && e.message || e) })
    })
  }

  function wsOpen (m) {
    var ws
    try {
      ws = new WebSocket(m.url)
    } catch (e) {
      queue.push({ id: m.id, op: 'ws_close', code: 1006, reason: String(e && e.message || e) })
      return
    }
    ws.binaryType = 'arraybuffer'
    sockets[m.id] = ws
    ws.onopen = function () { queue.push({ id: m.id, op: 'ws_open' }) }
    ws.onmessage = function (e) {
      var binary = typeof e.data !== 'string'
      var bytes = binary ? new Uint8Array(e.data) : new TextEncoder().encode(e.data)
      queue.push({ id: m.id, op: 'ws_message', binary: binary, data: bytesToB64(bytes) })
    }
    ws.onerror = function () { queue.push({ id: m.id, op: 'ws_error', err: 'websocket error' }) }
    ws.onclose = function (e) {
      delete sockets[m.id]
      queue.push({ id: m.id, op: 'ws_close', code: e.code, reason: e.reason || '' })
    }
  }

  function wsSend (m) {
    var ws = sockets[m.id]
    if (!ws || ws.readyState !== 1) return
    var bytes = b64ToBytes(m.data)
    ws.send(m.binary ? bytes : new TextDecoder().decode(bytes))
  }

  function wsClose (m) {
    var ws = sockets[m.id]
    if (ws) {
      delete sockets[m.id]
      try { ws.close(m.code || 1000) } catch (e) {}
    }
  }

  function poll (Module) {
    if (!dir || queue.length === 0) return
    var text = asciiJson(queue)
    queue = []
    try { Module.FS_unlink(dir + '/' + INBOX) } catch (e) {}
    Module.FS_createDataFile(dir, INBOX, text, true, true)
  }

  function handle (Module, m) {
    switch (m.op) {
      case 'hello': dir = m.dir; break
      case 'poll': poll(Module); break
      case 'http': httpRequest(m); break
      case 'ping': ping(m); break
      case 'ws_open': wsOpen(m); break
      case 'ws_send': wsSend(m); break
      case 'ws_close': wsClose(m); break
    }
  }

  window.braincloudWeb = {
    attach: function (Module) {
      var prev = Module.print || console.log.bind(console)
      Module.print = function (text) {
        if (typeof text === 'string' && text.indexOf(PREFIX) === 0) {
          try {
            handle(Module, JSON.parse(text.slice(PREFIX.length)))
          } catch (e) {
            console.error('braincloud-web:', e)
          }
        } else {
          prev(text)
        }
      }
    }
  }
})()

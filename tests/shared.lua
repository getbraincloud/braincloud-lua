--- Shared test utilities: one wrapper/client for the run, fresh UserA/B/C, async await by
--- pumping wrapper:update(). Mirrors C# TestFixtureBase.

local socket = require("socket")
local BrainCloud = require("braincloud")

local TestUtils = {}
TestUtils.TIMEOUT = 20

local function loadIds(path)
	local ids = {}
	local f = assert(io.open(path, "r"), "missing test ids file: " .. path)
	for line in f:lines() do
		local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
		if k then
			ids[k] = v
		end
	end
	f:close()
	return ids
end

TestUtils.ids = loadIds(os.getenv("BC_TEST_IDS") or "test_ids.txt")

local wrapper = BrainCloud.new("tests")
local secrets = { [TestUtils.ids.appId] = TestUtils.ids.secret }
if TestUtils.ids.childAppId and TestUtils.ids.childSecret then
	secrets[TestUtils.ids.childAppId] = TestUtils.ids.childSecret
end
wrapper:initializeWithApps(TestUtils.ids.appId, secrets, TestUtils.ids.version, TestUtils.ids.serverUrl)
wrapper:getBCClient():setDebugEnabled(os.getenv("BC_TEST_DEBUG") == "1")
TestUtils.wrapper = wrapper
TestUtils.client = wrapper:getBCClient()

function TestUtils.uuid()
	return TestUtils.client.platform.uuid()
end

--- Pumps networking for `seconds`.
function TestUtils.wait(seconds)
	local deadline = socket.gettime() + (seconds or 0.05)
	repeat
		wrapper:update()
		socket.sleep(0.005)
	until socket.gettime() >= deadline
end

--- Runs fn(done) and pumps until done(success, result) fires.
function TestUtils.await(tag, fn, timeout)
	local finished, success, result = false, nil, nil
	fn(function(s, r)
		if not finished then
			finished, success, result = true, s, r
		end
	end)
	local deadline = socket.gettime() + (timeout or TestUtils.TIMEOUT)
	while not finished do
		if socket.gettime() > deadline then
			error("TIMEOUT waiting for: " .. tag, 0)
		end
		wrapper:update()
		socket.sleep(0.005)
	end
	return success, result
end

--- Pumps until predicate() is truthy.
function TestUtils.waitFor(tag, predicate, timeout)
	local deadline = socket.gettime() + (timeout or TestUtils.TIMEOUT)
	while not predicate() do
		if socket.gettime() > deadline then
			error("TIMEOUT waiting for: " .. tag, 0)
		end
		wrapper:update()
		socket.sleep(0.005)
	end
end

function TestUtils.describe(r)
	if type(r) ~= "table" then
		return tostring(r)
	end
	return string.format("status=%s reason=%s %s", tostring(r.status), tostring(r.reason_code), tostring(r.status_message or ""))
end

function TestUtils.assertOk(tag, s, r)
	assert(s, tag .. " failed: " .. TestUtils.describe(r))
	return r
end

function TestUtils.assertFail(tag, s, r, status, reasonCode)
	assert(not s, tag .. " should have failed")
	if status then
		assert(r and r.status == status, tag .. ": expected status " .. status .. ", got " .. TestUtils.describe(r))
	end
	if reasonCode then
		assert(r and r.reason_code == reasonCode, tag .. ": expected reason " .. reasonCode .. ", got " .. TestUtils.describe(r))
	end
end

-- gtest-style output, matching the cpp client. BC_TEST_VERBOSE=1 adds tracebacks; NO_COLOR disables colour.
local useColor = os.getenv("NO_COLOR") == nil
local function paint(code, text)
	return useColor and ("\27[" .. code .. "m" .. text .. "\27[0m") or text
end
TestUtils.paint = paint
TestUtils.GREEN, TestUtils.RED, TestUtils.YELLOW = "32", "31", "33"
TestUtils.verbose = os.getenv("BC_TEST_VERBOSE") == "1"

function TestUtils.nowMs()
	return socket.gettime() * 1000
end

--- Ends the current test as skipped (reported, not counted as pass or fail).
function TestUtils.skip(reason)
	error({ skip = reason }, 0)
end

--- Returns status ("ok" | "failed" | "skipped"), message, traceback.
function TestUtils.runTest(fn)
	local trace
	local ok, err = xpcall(fn, function(e)
		if type(e) ~= "table" then
			trace = debug.traceback("", 2)
		end
		return e
	end)
	if ok then
		return "ok"
	end
	if type(err) == "table" and err.skip then
		return "skipped", err.skip
	end
	return "failed", tostring(err), trace
end

-- TEST USERS

TestUtils.users = nil
TestUtils.TEST_USER_OPP_PROFILE_ID = nil

local function makeUser(client, name)
	local id = name .. "_Lua-" .. tostring(math.random(1, 2 ^ 30))
	local user = { id = id, password = id, email = id .. "@bctestuser.com" }
	client.authentication:clearSavedSession()

	local s, r = TestUtils.await("CreateUser " .. name, function(cb)
		client.authentication:authenticateUniversal(user.id, user.password, true, cb)
	end)
	TestUtils.assertOk("CreateUser " .. name, s, r)
	user.profileId = r.data.profileId

	if r.data.newUser == "true" or r.data.newUser == true then
		TestUtils.await("EnableMatchMaking", function(cb)
			client.matchMaking:enableMatchMaking(cb)
		end)
		TestUtils.await("UpdateUserName", function(cb)
			client.playerState:updateUserName(user.id, cb)
		end)
		TestUtils.await("UpdateContactEmail", function(cb)
			client.playerState:updateContactEmail("braincloudunittest@gmail.com", cb)
		end)
	end

	TestUtils.await("Logout " .. name, function(cb)
		client.playerState:logout(cb)
	end)
	client.authentication:clearSavedSession()
	return user
end

function TestUtils.ensureUsers(client)
	if TestUtils.users then
		return TestUtils.users
	end
	TestUtils.users = {
		A = makeUser(client, "UserA"),
		B = makeUser(client, "UserB"),
		C = makeUser(client, "UserC"),
	}
	TestUtils.TEST_USER_OPP_PROFILE_ID = TestUtils.users.B.profileId
	return TestUtils.users
end

function TestUtils.authenticateAs(client, userKey)
	local user = TestUtils.ensureUsers(client)[userKey or "A"]
	client.authentication:clearSavedSession()
	-- back to the parent app after any child-profile switch
	client.appId = TestUtils.ids.appId
	local s, r = TestUtils.await("Authenticate " .. (userKey or "A"), function(cb)
		client.authentication:authenticateUniversal(user.id, user.password, true, cb)
	end)
	return TestUtils.assertOk("Authenticate " .. (userKey or "A"), s, r)
end

--- options.authPerTest (default true): authenticate UserA before every test, like C# [SetUp].
function TestUtils.buildRunner(testName, _, buildTestsFn, options)
	options = options or {}
	local authPerTest = options.authPerTest ~= false

	return function()
		local results = {}
		local client = TestUtils.client

		TestUtils.ensureUsers(client)
		TestUtils.authenticateAs(client, "A")

		local serviceTests = buildTestsFn(client, wrapper)

		local function run(filter)
			local selected = {}
			for _, test in ipairs(serviceTests) do
				if not filter or test.name:lower():find(filter:lower(), 1, true) then
					selected[#selected + 1] = test
				end
			end
			local plural = #selected == 1 and "test" or "tests"
			print(paint(TestUtils.GREEN, "[----------] ") .. string.format("%d %s from %s", #selected, plural, testName))

			local serviceStart = TestUtils.nowMs()
			for _, test in ipairs(selected) do
				local full = testName .. "." .. test.name
				print(paint(TestUtils.GREEN, "[ RUN      ] ") .. full)
				local started = TestUtils.nowMs()
				local status, msg, trace
				if authPerTest then
					local authOk, authErr = pcall(TestUtils.authenticateAs, client, "A")
					if not authOk then
						status, msg = "failed", "setup auth: " .. tostring(authErr)
					end
				end
				if not status then
					status, msg, trace = TestUtils.runTest(test.fn)
				end
				local ms = math.floor(TestUtils.nowMs() - started + 0.5)

				if status == "ok" then
					print(paint(TestUtils.GREEN, "[       OK ] ") .. string.format("%s (%d ms)", full, ms))
				elseif status == "skipped" then
					print(paint(TestUtils.YELLOW, "[  SKIPPED ] ") .. string.format("%s (%d ms): %s", full, ms, msg))
				else
					print("    " .. msg)
					if TestUtils.verbose and trace then
						print(trace)
					end
					print(paint(TestUtils.RED, "[  FAILED  ] ") .. string.format("%s (%d ms)", full, ms))
				end
				results[#results + 1] = { name = full, status = status, ms = ms }
			end
			local total = math.floor(TestUtils.nowMs() - serviceStart + 0.5)
			print(paint(TestUtils.GREEN, "[----------] ") .. string.format("%d %s from %s (%d ms total)\n", #selected, plural, testName, total))
		end

		return { name = testName, tests = serviceTests, run = run, results = results }
	end
end

return TestUtils

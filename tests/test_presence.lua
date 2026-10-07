--- Test_Presence.lua
--- Server integration smoke tests for Presence service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Presence", nil, function(client)
	local presence = client.presence
	assert(presence, "Presence module missing")

	local tests = {
		{
			name = "ForcePush",
			fn = function()
				local s, res = TestUtils.await("ForcePush", function(cb)
					presence:forcePush(cb)
				end)
				assert(res ~= nil, "ForcePush did not return a response")
			end,
		},

		{
			name = "GetPresenceOfFriends",
			fn = function()
				local s, res = TestUtils.await("GetPresenceOfFriends", function(cb)
					presence:getPresenceOfFriends("all", false, cb)
				end)
				assert(res ~= nil, "GetPresenceOfFriends did not return a response")
			end,
		},

		{
			name = "GetPresenceOfGroup",
			fn = function()
				local s, res = TestUtils.await("GetPresenceOfGroup", function(cb)
					presence:getPresenceOfGroup("", false, cb)
				end)
				assert(res ~= nil, "GetPresenceOfGroup did not return a response")
			end,
		},

		{
			name = "GetPresenceOfUsers",
			fn = function()
				local s, res = TestUtils.await("GetPresenceOfUsers", function(cb)
					presence:getPresenceOfUsers({}, false, cb)
				end)
				assert(res ~= nil, "GetPresenceOfUsers did not return a response")
			end,
		},

		{
			name = "RegisterListenersForFriends",
			fn = function()
				local s, res = TestUtils.await("RegisterListenersForFriends", function(cb)
					presence:registerListenersForFriends("all", false, cb)
				end)
				assert(res ~= nil, "RegisterListenersForFriends did not return a response")
			end,
		},

		{
			name = "RegisterListenersForGroup",
			fn = function()
				local s, res = TestUtils.await("RegisterListenersForGroup", function(cb)
					--- permissive smoke test using empty group id
					presence:registerListenersForGroup("", false, cb)
				end)
				assert(res ~= nil, "RegisterListenersForGroup did not return a response")
			end,
		},

		{
			name = "RegisterListenersForProfiles",
			fn = function()
				local s, res = TestUtils.await("RegisterListenersForProfiles", function(cb)
					presence:registerListenersForProfiles({}, false, cb)
				end)
				assert(res ~= nil, "RegisterListenersForProfiles did not return a response")
			end,
		},

		{
			name = "SetVisibility",
			fn = function()
				local s, res = TestUtils.await("SetVisibility", function(cb)
					presence:setVisibility(true, cb)
				end)
				assert(res ~= nil, "SetVisibility did not return a response")
			end,
		},

		{
			name = "StopListening",
			fn = function()
				local s, res = TestUtils.await("StopListening", function(cb)
					presence:stopListening(cb)
				end)
				assert(res ~= nil, "StopListening did not return a response")
			end,
		},

		{
			name = "UpdateActivity",
			fn = function()
				local s, res = TestUtils.await("UpdateActivity", function(cb)
					presence:updateActivity({ activity = "idle" }, cb)
				end)
				assert(res ~= nil, "UpdateActivity did not return a response")
			end,
		},
	}

	return tests
end)

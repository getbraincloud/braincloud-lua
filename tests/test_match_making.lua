--- Test_MatchMaking.lua
--- Server integration tests for MatchMaking service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("MatchMaking", nil, function(client)
	local mm = client.matchMaking
	assert(mm, "MatchMaking module missing")

	local tests = {
		{
			name = "Read",
			fn = function()
				local s, res = TestUtils.await("Read", function(cb)
					mm:read(cb)
				end)
				assert(res ~= nil, "Read did not return a response")
				assert(res.status == 200, "Not a good status")
			end,
		},

		{
			name = "SetPlayerRating",
			fn = function()
				local s, res = TestUtils.await("SetPlayerRating", function(cb)
					mm:setPlayerRating(1500, cb)
				end)
				assert(res ~= nil, "SetPlayerRating did not return a response")
				assert(res.status == 200, "Not a good status")
			end,
		},

		{
			name = "ResetPlayerRating",
			fn = function()
				local s, res = TestUtils.await("ResetPlayerRating", function(cb)
					mm:resetPlayerRating(cb)
				end)
				assert(res ~= nil, "ResetPlayerRating did not return a response")
				assert(res.status == 200, "Not a good status")
			end,
		},

		{
			name = "IncrementPlayerRating",
			fn = function()
				local s, res = TestUtils.await("IncrementPlayerRating", function(cb)
					mm:incrementPlayerRating(10, cb)
				end)
				assert(res ~= nil, "IncrementPlayerRating did not return a response")
				assert(res.data.lastMatch, "Missing lastMatch data")
			end,
		},

		{
			name = "DecrementPlayerRating",
			fn = function()
				local s, res = TestUtils.await("DecrementPlayerRating", function(cb)
					mm:decrementPlayerRating(5, cb)
				end)
				assert(res ~= nil, "DecrementPlayerRating did not return a response")
				assert(res.data.lastMatch, "Missing lastMatch data")
			end,
		},

		{
			name = "TurnShieldOn",
			fn = function()
				local s, res = TestUtils.await("TurnShieldOn", function(cb)
					mm:turnShieldOn(cb)
				end)
				assert(res ~= nil, "TurnShieldOn did not return a response")
				assert(res.status == 200, "Not a good status")
			end,
		},

		{
			name = "TurnShieldOnFor",
			fn = function()
				local s, res = TestUtils.await("TurnShieldOnFor", function(cb)
					mm:turnShieldOnFor(60, cb)
				end)
				assert(res ~= nil, "TurnShieldOnFor did not return a response")
				assert(res.status == 200, "Not a good status")
			end,
		},

		{
			name = "TurnShieldOff",
			fn = function()
				local s, res = TestUtils.await("TurnShieldOff", function(cb)
					mm:turnShieldOff(cb)
				end)
				assert(res ~= nil, "TurnShieldOff did not return a response")
				assert(res.status == 200, "Not a good status")
			end,
		},

		{
			name = "IncrementShieldOnFor",
			fn = function()
				local s, res = TestUtils.await("IncrementShieldOnFor", function(cb)
					mm:incrementShieldOnFor(15, cb)
				end)
				assert(res ~= nil, "IncrementShieldOnFor did not return a response")
				assert(res.data.shieldExpiry, "Missing shieldExpiry data")
			end,
		},

		{
			name = "GetShieldExpiry",
			fn = function()
				local s, res = TestUtils.await("GetShieldExpiry", function(cb)
					mm:getShieldExpiry(nil, cb)
				end)
				assert(res ~= nil, "GetShieldExpiry did not return a response")
				assert(res.data.shieldExpiry, "Missing shieldExpiry data")
			end,
		},

		{
			name = "FindPlayers",
			fn = function()
				local s, res = TestUtils.await("FindPlayers", function(cb)
					mm:findPlayers(50, 10, cb)
				end)
				assert(res ~= nil, "FindPlayers did not return a response")
				assert(res.data.matchesFound, "Missing matchesFound data")
			end,
		},

		{
			name = "FindPlayersWithAttributes",
			fn = function()
				local s, res = TestUtils.await("FindPlayersWithAttributes", function(cb)
					mm:findPlayersWithAttributes(50, 10, { region = "NA" }, cb)
				end)
				assert(res ~= nil, "FindPlayersWithAttributes did not return a response")

				assert(res.data.matchesFound, "Missing matchesFound data")
			end,
		},

		{
			name = "FindPlayersUsingFilter",
			fn = function()
				local s, res = TestUtils.await("FindPlayersUsingFilter", function(cb)
					mm:findPlayersUsingFilter(50, 10, { someParam = true }, cb)
				end)
				assert(res ~= nil, "FindPlayersUsingFilter did not return a response")
				assert(res.data.matchesFound, "Missing matchesFound data")
			end,
		},

		{
			name = "FindPlayersWithAttributesUsingFilter",
			fn = function()
				local s, res = TestUtils.await("FindPlayersWithAttributesUsingFilter", function(cb)
					mm:findPlayersWithAttributesUsingFilter(50, 10, { skill = 100 }, { extra = 1 }, cb)
				end)
				assert(res ~= nil, "FindPlayersWithAttributesUsingFilter did not return a response")
				assert(res.data.matchesFound, "Missing matchesFound data")
			end,
		},

		{
			name = "EnableMatchMaking",
			fn = function()
				local s, res = TestUtils.await("EnableMatchMaking", function(cb)
					mm:enableMatchMaking(cb)
				end)
				assert(res ~= nil, "EnableMatchMaking did not return a response")
				assert(res.status == 200, "Not a good status")
			end,
		},

		{
			name = "DisableMatchMaking",
			fn = function()
				local s, res = TestUtils.await("DisableMatchMaking", function(cb)
					mm:disableMatchMaking(cb)
				end)
				assert(res ~= nil, "DisableMatchMaking did not return a response")
				assert(res.status == 200, "Not a good status")
			end,
		},
	}

	return tests
end)

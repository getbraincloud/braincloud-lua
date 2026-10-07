--- Test_Lobby.lua
--- Server integration tests for Lobby service
--- Mirrors C++ TestBCLobby.cpp

local TestUtils    = require("tests.shared")


--- Lobby type configured in the brainCloud dashboard for app 20001 (internal)
local LOBBY_TYPE = "READY_START_V2"

--- Standard matchmaking algorithm (mirrors C++ ranged-absolute usage)
local ALGO = {
	strategy  = "ranged-absolute",
	alignment = "center",
	ranges    = { 1000 },
}

--- Criteria used for GetLobbyInstances
local CRITERIA = { rating = { min = 1, max = 1000 } }

--- Config overrides used by CreateLobbyWithConfig
local CONFIG_OVERRIDES = {
	teams = {
		{ code = "reserved", minUsers = 0, maxUsers = 1, autoAssign = false },
		{ code = "all",      minUsers = 6, maxUsers = 6, autoAssign = true  },
	},
}

return TestUtils.buildRunner("Lobby", nil, function(client)
	local lobby = client.lobby
	assert(lobby, "Lobby module missing")

	local createdLobbyId = nil
	local cancelEntryId  = nil   -- captured from FindOrCreateLobby for CancelFindRequest

	--- Helper: assert a call expected to FAIL (wrong lobby id, missing params, etc.)
	local function assertFail(tag, s, res, expectedReasonCode)
		assert(not s, tag .. " should have returned an error but succeeded")
		if expectedReasonCode then
			local rc = res and res.reason_code or (res and res.data and res.data.reason_code)
			assert(rc == expectedReasonCode,
				tag .. " expected reason_code " .. tostring(expectedReasonCode) .. " got " .. tostring(rc))
		end
	end

	local tests = {

		--- ── Regions & Pings ──────────────────────────────────────────────────

		{
			name = "PingRegions",
			fn = function()
				-- Without pings fetched first, WithPingData calls must fail (MISSING_REQUIRED_PARAMETER = 40358)
				local s, res = TestUtils.await("FindOrCreateLobbyWithPingData_NoPings", function(cb)
					lobby:findOrCreateLobbyWithPingData(LOBBY_TYPE, 0, 1, ALGO, nil, {}, {}, true, nil, "all", cb)
				end)
				assertFail("FindOrCreateLobbyWithPingData_NoPings", s, res, 40358)

				-- Fetch regions
				local s2, res2 = TestUtils.await("GetRegionsForLobbies", function(cb)
					lobby:getRegionsForLobbies({ LOBBY_TYPE }, cb)
				end)
				assert(s2, "GetRegionsForLobbies failed: " .. tostring(res2))

				-- Ping twice (mirrors C++ which checks no caching and non-zero totals)
				local s3, res3 = TestUtils.await("PingRegions #1", function(cb)
					lobby:pingRegions(cb)
				end)
				assert(s3, "PingRegions #1 failed: " .. tostring(res3))

				local s4, res4 = TestUtils.await("PingRegions #2", function(cb)
					lobby:pingRegions(cb)
				end)
				assert(s4, "PingRegions #2 failed: " .. tostring(res4))

				-- Verify ping totals are non-zero (mirrors C++ total > 0 check)
				local pingData = res4 and res4.data
				local total = 0
				if pingData then
					for _, v in pairs(pingData) do
						total = total + (type(v) == "number" and v or 0)
					end
				end
				assert(total > 0, "All ping values are 0 — expected at least one non-zero region ping")

				-- Now all WithPingData variants should succeed
				local s5 = TestUtils.await("FindOrCreateLobbyWithPingData", function(cb)
					lobby:findOrCreateLobbyWithPingData(LOBBY_TYPE, 0, 1, ALGO, nil, {}, {}, true, nil, "all", cb)
				end)
				assert(s5, "FindOrCreateLobbyWithPingData failed after pings fetched")

				local s6 = TestUtils.await("FindLobbyWithPingData", function(cb)
					lobby:findLobbyWithPingData(LOBBY_TYPE, 0, 1, ALGO, nil, {}, true, nil, "all", cb)
				end)
				assert(s6, "FindLobbyWithPingData failed after pings fetched")

				local s7 = TestUtils.await("CreateLobbyWithPingData", function(cb)
					lobby:createLobbyWithPingData(LOBBY_TYPE, 0, {}, true, nil, "all", {}, cb)
				end)
				assert(s7, "CreateLobbyWithPingData failed after pings fetched")

				local s8 = TestUtils.await("CreateLobbyWithConfigAndPingData", function(cb)
					lobby:createLobbyWithConfigAndPingData(LOBBY_TYPE, 0, {}, true, nil, "all", {}, CONFIG_OVERRIDES, cb)
				end)
				assert(s8, "CreateLobbyWithConfigAndPingData failed after pings fetched")

				-- JoinLobby with wrong id must still fail even with ping data
				local s9, res9 = TestUtils.await("JoinLobbyWithPingData_WrongId", function(cb)
					lobby:joinLobbyWithPingData("wrongLobbyId", true, nil, "all", {}, cb)
				end)
				assertFail("JoinLobbyWithPingData_WrongId", s9, res9)
			end,
		},

		--- ── CreateLobby ─────────────────────────────────────────────────────

		{
			name = "CreateLobby",
			fn = function()
				local s, res = TestUtils.await("CreateLobby", function(cb)
					lobby:createLobby(LOBBY_TYPE, 0, {}, true, nil, "all", {}, cb)
				end)
				assert(s, "CreateLobby failed: " .. tostring(res))
				if res and res.data and res.data.lobbyId then
					createdLobbyId = res.data.lobbyId
				end
			end,
		},

		{
			name = "CreateLobbyWithConfig",
			fn = function()
				local s, res = TestUtils.await("CreateLobbyWithConfig", function(cb)
					lobby:createLobbyWithConfig(LOBBY_TYPE, 0, {}, true, nil, "all", {}, CONFIG_OVERRIDES, cb)
				end)
				assert(s, "CreateLobbyWithConfig failed: " .. tostring(res))
				if res and res.data and res.data.lobbyId and not createdLobbyId then
					createdLobbyId = res.data.lobbyId
				end
			end,
		},

		--- ── FindLobby ───────────────────────────────────────────────────────

		{
			name = "FindLobby",
			fn = function()
				local s, res = TestUtils.await("FindLobby", function(cb)
					lobby:findLobby(LOBBY_TYPE, 0, 1, ALGO, nil, {}, true, nil, "all", cb)
				end)
				assert(s, "FindLobby failed: " .. tostring(res))
			end,
		},

		--- ── FindOrCreateLobby (captures entryId for CancelFindRequest) ─────

		{
			name = "FindOrCreateLobby",
			fn = function()
				local s, res = TestUtils.await("FindOrCreateLobby", function(cb)
					lobby:findOrCreateLobby(LOBBY_TYPE, 0, 1, ALGO, nil, {}, {}, true, nil, "all", cb)
				end)
				assert(s, "FindOrCreateLobby failed: " .. tostring(res))
				if res and res.data then
					cancelEntryId = res.data.entryId or cancelEntryId
					if res.data.lobbyId and not createdLobbyId then
						createdLobbyId = res.data.lobbyId
					end
				end
			end,
		},

		--- ── CancelFindRequest (mirrors C++ which captures real entryId) ────

		{
			name = "CancelFindRequest",
			fn = function()
				-- Issue a fresh FindOrCreateLobby to guarantee a fresh entryId
				local s, res = TestUtils.await("FindOrCreateLobby_ForCancel", function(cb)
					lobby:findOrCreateLobby(LOBBY_TYPE, 0, 1, ALGO, nil, {}, {}, true, nil, "all", cb)
				end)
				local entryId = res and res.data and res.data.entryId or ""
				assert(entryId ~= "" or not s, "FindOrCreateLobby returned success but no entryId")

				local s2, res2 = TestUtils.await("CancelFindRequest", function(cb)
					lobby:cancelFindRequest(LOBBY_TYPE, entryId, cb)
				end)
				assert(s2, "CancelFindRequest failed: " .. tostring(res2))
			end,
		},

		--- ── GetLobbyData (expect fail — mirrors C++ LOBBY_NOT_FOUND) ───────

		{
			name = "GetLobbyData_WrongId",
			fn = function()
				local s, res = TestUtils.await("GetLobbyData_WrongId", function(cb)
					lobby:getLobbyData("wrongLobbyId", cb)
				end)
				assertFail("GetLobbyData_WrongId", s, res)
			end,
		},

		--- ── GetLobbyInstances ───────────────────────────────────────────────

		{
			name = "GetLobbyInstances",
			fn = function()
				local s, res = TestUtils.await("GetLobbyInstances", function(cb)
					lobby:getLobbyInstances(LOBBY_TYPE, CRITERIA, cb)
				end)
				assert(s, "GetLobbyInstances failed: " .. tostring(res))
			end,
		},

		{
			name = "GetLobbyInstancesWithPingData",
			fn = function()
				-- Pings must have been fetched in the PingRegions test above
				local criteriaWithPing = { rating = CRITERIA.rating, ping = { max = 100 } }
				local s, res = TestUtils.await("GetLobbyInstancesWithPingData", function(cb)
					lobby:getLobbyInstancesWithPingData(LOBBY_TYPE, criteriaWithPing, cb)
				end)
				assert(s, "GetLobbyInstancesWithPingData failed: " .. tostring(res))
			end,
		},

		--- ── Lobby operations with wrong ids (expect fail) ─────────────────

		{
			name = "LeaveLobby_WrongId",
			fn = function()
				local s, res = TestUtils.await("LeaveLobby_WrongId", function(cb)
					lobby:leaveLobby("wrongLobbyId", cb)
				end)
				assertFail("LeaveLobby_WrongId", s, res)
			end,
		},

		{
			name = "JoinLobby_WrongId",
			fn = function()
				local s, res = TestUtils.await("JoinLobby_WrongId", function(cb)
					lobby:joinLobby("wrongLobbyId", true, nil, "all", {}, cb)
				end)
				assertFail("JoinLobby_WrongId", s, res)
			end,
		},

		{
			name = "RemoveMember_WrongId",
			fn = function()
				local s, res = TestUtils.await("RemoveMember_WrongId", function(cb)
					lobby:removeMember("wrongLobbyId", "wrongConId", cb)
				end)
				assertFail("RemoveMember_WrongId", s, res)
			end,
		},

		{
			name = "SendSignal_WrongId",
			fn = function()
				local s, res = TestUtils.await("SendSignal_WrongId", function(cb)
					lobby:sendSignal("wrongLobbyId", { msg = "test" }, cb)
				end)
				assertFail("SendSignal_WrongId", s, res)
			end,
		},

		{
			name = "SwitchTeam_WrongId",
			fn = function()
				local s, res = TestUtils.await("SwitchTeam_WrongId", function(cb)
					lobby:switchTeam("wrongLobbyId", "all", cb)
				end)
				assertFail("SwitchTeam_WrongId", s, res)
			end,
		},

		{
			name = "UpdateReady_WrongId",
			fn = function()
				local s, res = TestUtils.await("UpdateReady_WrongId", function(cb)
					lobby:updateReady("wrongLobbyId", true, {}, cb)
				end)
				assertFail("UpdateReady_WrongId", s, res)
			end,
		},

		{
			name = "UpdateSettings_WrongId",
			fn = function()
				local s, res = TestUtils.await("UpdateSettings_WrongId", function(cb)
					lobby:updateSettings("wrongLobbyId", { msg = "test" }, cb)
				end)
				assertFail("UpdateSettings_WrongId", s, res)
			end,
		},

		--- ── Cleanup: leave any lobby we created ────────────────────────────

		{
			name = "LeaveLobby_Cleanup",
			fn = function()
				if not createdLobbyId then return end
				local s, res = TestUtils.await("LeaveLobby_Cleanup", function(cb)
					lobby:leaveLobby(createdLobbyId, cb)
				end)
				-- Best effort — don't fail if lobby already gone
			end,
		},
	}

	return tests
end)

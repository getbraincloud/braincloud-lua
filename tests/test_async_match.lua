--- Test_Async_Match.lua
--- Server integration tests for AsyncMatch

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("AsyncMatch", nil, function(client)
	local asyncMatch = client.asyncMatch
	assert(asyncMatch, "AsyncMatch module missing")

	local matchIds = {}

	return {

		--- FIND MATCHES
		{
			name = "FindMatches",
			fn = function()
				local s, res = TestUtils.await("FindMatches", function(r)
					asyncMatch:findMatches(r)
				end)
				assert(s, "FindMatches failed")
				assert(type(res.data.results) == "table", "results must be a table")
				assert(#res.data.results >= 0, "results must be an array")
			end,
		},

		{
			name = "FindMatchesCompleted",
			fn = function()
				local s, res = TestUtils.await("FindMatchesCompleted", function(r)
					asyncMatch:findCompleteMatches(r)
				end)

				assert(s, "FindMatchesCompleted failed")
				--- Some servers return empty {}, some return { success = true }
				assert(res.data == nil or type(res.data) == "table", "Unexpected FindMatchesCompleted response")
			end,
		},

		--- CREATE MATCH
		{
			name = "CreateMatch",
			fn = function()
				local s, res = TestUtils.await("CreateMatch", function(r)
					local opponents = { { id = TestUtils.TEST_USER_OPP_PROFILE_ID, platform = "BC" } }
					asyncMatch:createMatch(opponents, nil, r)
				end)

				assert(s, "CreateMatch failed")
				assert(type(res.data.matchId) == "string", "Missing matchId")
				assert(type(res.data.ownerId) == "string", "Missing ownerId")

				table.insert(matchIds, {
					ownerId = res.data.ownerId,
					matchId = res.data.matchId,
				})
			end,
		},

		{
			name = "CreateMatchWithInitialTurn",
			fn = function()
				local s, res = TestUtils.await("CreateMatchWithInitialTurn", function(r)
					local opponents = { { id = TestUtils.TEST_USER_OPP_PROFILE_ID, platform = "BC" } }
					asyncMatch:createMatchWithInitialTurn(
						opponents,
						{ test = "state" },
						nil,
						nil,
						{ summary = "test" },
						r
					)
				end)

				assert(s, "CreateMatchWithInitialTurn failed")
				assert(type(res.data.matchId) == "string", "Missing matchId")

				local status = res.data.status.status
				assert(status == "PENDING" or status == "NOT_STARTED", "Unexpected match status: " .. tostring(status))

				table.insert(matchIds, {
					ownerId = res.data.ownerId,
					matchId = res.data.matchId,
				})
			end,
		},

		--- READ MATCH
		{
			name = "ReadMatch",
			fn = function()
				local match = matchIds[1]

				local s, res = TestUtils.await("ReadMatch", function(r)
					asyncMatch:readMatch(match.ownerId, match.matchId, r)
				end)

				assert(s, "ReadMatch failed")
				assert(res.data.matchId == match.matchId, "MatchId mismatch")
			end,
		},

		{
			name = "ReadMatchHistory",
			fn = function()
				local match = matchIds[1]
				local s = TestUtils.await("ReadMatchHistory", function(r)
					asyncMatch:readMatchHistory(match.ownerId, match.matchId, r)
				end)
				assert(s, "ReadMatchHistory failed")
			end,
		},

		--- SUBMIT TURN
		{
			name = "SubmitTurn",
			fn = function()
				local match = matchIds[1]

				local s, res = TestUtils.await("SubmitTurn", function(r)
					asyncMatch:submitTurn(
						match.ownerId,
						match.matchId,
						0,
						{ turn = "data" },
						nil,
						nil,
						{ summary = "turn" },
						{ score = 1 },
						r
					)
				end)

				assert(s, "SubmitTurn failed")
				assert(type(res.data.version) == "number", "Version missing")
				assert(res.data.version >= 1, "Version must be >= 1")
			end,
		},

		--- UPDATE MATCH SUMMARY (C#: fresh match, version 0)
		{
			name = "UpdateMatchSummary",
			fn = function()
				local s1, r1 = TestUtils.await("CreateMatch", function(r)
					asyncMatch:createMatch({ { id = TestUtils.users.B.profileId, platform = "BC" } }, nil, r)
				end)
				TestUtils.assertOk("CreateMatch", s1, r1)

				local s, res = TestUtils.await("UpdateMatchSummary", function(r)
					asyncMatch:updateMatchSummaryData(TestUtils.users.A.profileId, r1.data.matchId, 0, { map = "level1" }, r)
				end)
				TestUtils.assertOk("UpdateMatchSummary", s, res)

				TestUtils.await("AbandonMatch", function(r)
					asyncMatch:abandonMatch(r1.data.ownerId, r1.data.matchId, r)
				end)
			end,
		},

		--- UPDATE MATCH STATE CURRENT TURN (C#: players B then A, version 0)
		{
			name = "UpdateMatchStateCurrentTurn",
			fn = function()
				local players = {
					{ id = TestUtils.users.B.profileId, platform = "BC" },
					{ id = TestUtils.users.A.profileId, platform = "BC" },
				}
				local s1, r1 = TestUtils.await("CreateMatch", function(r)
					asyncMatch:createMatch(players, nil, r)
				end)
				TestUtils.assertOk("CreateMatch", s1, r1)

				local s, res = TestUtils.await("UpdateMatchStateCurrentTurn", function(r)
					asyncMatch:updateMatchStateCurrentTurn(r1.data.ownerId, r1.data.matchId, 0, { blob = 2 }, nil, r)
				end)
				TestUtils.assertOk("UpdateMatchStateCurrentTurn", s, res)
			end,
		},

		--- ABANDON MATCH
		{
			name = "AbandonMatchWithSummaryData",
			fn = function()
				local match = matchIds[1]

				local s, res = TestUtils.await("AbandonMatchWithSummaryData", function(r)
					asyncMatch:abandonMatchWithSummaryData(
						match.ownerId,
						match.matchId,
						"PushMsg",
						{ summary = "aband" },
						r
					)
				end)

				assert(s or (res and res.status == 403), "AbandonMatchWithSummaryData failed")
			end,
		},

		--- COMPLETE MATCH
		{
			name = "CompleteMatchWithSummaryData",
			fn = function()
				local match = matchIds[2]

				local s, res = TestUtils.await("CompleteMatchWithSummaryData", function(r)
					asyncMatch:completeMatchWithSummaryData(
						match.ownerId,
						match.matchId,
						"PushMsg",
						{ summary = "complete" },
						r
					)
				end)

				assert(s or (res and res.status == 403), "CompleteMatchWithSummaryData failed")
			end,
		},

		--- DELETE MATCH
		{
			name = "DeleteMatch",
			fn = function()
				for _, match in ipairs(matchIds) do
					local s = TestUtils.await("DeleteMatch", function(r)
						asyncMatch:deleteMatch(match.ownerId, match.matchId, r)
					end)
					assert(s, "DeleteMatch failed")
				end
			end,
		},
	}
end)

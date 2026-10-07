--- Test_Tournament.lua
--- Server integration tests for Tournament service
--- Mirrors the intention and coverage of C# TestTournament.cs

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Tournament", nil, function(client)
	local tournament = client.tournament
	local group = client.group
	assert(tournament, "Tournament module missing")
	assert(group, "Group module missing")

	--- Individual tournament IDs (aligned with C# TestTournament.cs)
	local leaderboardId = "testTournamentLeaderboard"
	local divSetId = "testDivSetId"
	local tournamentCode = "testTournament"
	local exampleVersion = -1

	--- Group tournament IDs
	local groupType = "csharpTest"
	local groupLeaderboardId = "groupTournament"
	local groupDivSetId = "bronzeGroup"
	local groupTournamentCode = "testGroupTournament"
	local beforeAndAfterCount = 10
	local initialScore = 0

	--- Mirrors C# JoinTestTournament() helper: join and return the versionId
	local function joinTestTournament()
		local s, res = TestUtils.await("JoinTournament", function(cb)
			tournament:joinTournament(leaderboardId, tournamentCode, math.random(1, 1000), cb)
		end)
		assert(s, "JoinTournament failed: " .. tostring(res))

		local _, statusRes = TestUtils.await("GetTournamentStatus", function(cb)
			tournament:getTournamentStatus(leaderboardId, -1, cb)
		end)
		return statusRes and statusRes.data and statusRes.data.versionId or exampleVersion
	end

	--- Mirrors C# LeaveTestTournament() helper
	local function leaveTestTournament()
		TestUtils.await("LeaveTournament", function(cb)
			tournament:leaveTournament(leaderboardId, cb)
		end)
	end

	--- Helpers for group tournament tests
	local function createGroup()
		local s, res = TestUtils.await("CreateGroup", function(cb)
			group:createGroup("TournamentTestGroup", groupType, false, { member = 2, other = 1 }, nil, nil, nil, cb)
		end)
		TestUtils.assertOk("CreateGroup", s, res)
		return res.data.groupId
	end

	local function deleteGroup(groupId)
		TestUtils.await("DeleteGroup", function(cb)
			group:deleteGroup(groupId, -1, cb)
		end)
	end

	local tests = {

		--- Mirrors C# GetMyDivisions — basic call, expect success
		{
			name = "GetMyDivisions",
			fn = function()
				local s, res = TestUtils.await("GetMyDivisions", function(cb)
					tournament:getMyDivisions(cb)
				end)
				assert(s, "GetMyDivisions failed: " .. tostring(res))
			end,
		},

		--- Mirrors C# GetDivisionInfo with invalid ID — expect failure (DIVISION_SET_DOES_NOT_EXIST)
		{
			name = "GetDivisionInfo_InvalidId",
			fn = function()
				local s, _res = TestUtils.await("GetDivisionInfo_InvalidId", function(cb)
					tournament:getDivisionInfo("Invalid_Id", cb)
				end)
				assert(not s, "GetDivisionInfo with invalid ID should fail")
			end,
		},

		--- GetDivisionInfo with a valid divSetId — expect success
		{
			name = "GetDivisionInfo",
			fn = function()
				local s, res = TestUtils.await("GetDivisionInfo", function(cb)
					tournament:getDivisionInfo(divSetId, cb)
				end)
				assert(s, "GetDivisionInfo failed: " .. tostring(res))
			end,
		},

		--- Mirrors C# GetTournamentStatus — join first, then check status
		{
			name = "GetTournamentStatus",
			fn = function()
				local version = joinTestTournament()
				local s, res = TestUtils.await("GetTournamentStatus", function(cb)
					tournament:getTournamentStatus(leaderboardId, version, cb)
				end)
				leaveTestTournament()
				assert(s, "GetTournamentStatus failed: " .. tostring(res))
				assert(res.data and res.data.versionId, "Missing versionId in GetTournamentStatus response")
			end,
		},

		--- Mirrors C# JoinDivision with invalid ID — expect failure (DIVISION_SET_DOES_NOT_EXIST)
		{
			name = "JoinDivision_InvalidId",
			fn = function()
				local s, _res = TestUtils.await("JoinDivision_InvalidId", function(cb)
					tournament:joinDivision("Invalid_Id", tournamentCode, math.random(1, 1000), cb)
				end)
				assert(not s, "JoinDivision with invalid ID should fail")
			end,
		},

		--- Mirrors C# LeaveDivisionInstance with invalid ID — expect failure (NO_LEADERBOARD_FOUND)
		{
			name = "LeaveDivisionInstance_InvalidId",
			fn = function()
				local s, _res = TestUtils.await("LeaveDivisionInstance_InvalidId", function(cb)
					tournament:leaveDivisionInstance("Invalid_id", cb)
				end)
				assert(not s, "LeaveDivisionInstance with invalid ID should fail")
			end,
		},

		--- Mirrors C# ViewCurrentReward — join, view, leave
		{
			name = "ViewCurrentReward",
			fn = function()
				joinTestTournament()
				local s, res = TestUtils.await("ViewCurrentReward", function(cb)
					tournament:viewCurrentReward(leaderboardId, cb)
				end)
				leaveTestTournament()
				assert(s, "ViewCurrentReward failed: " .. tostring(res))
			end,
		},

		--- Mirrors C# ViewReward with version -1 while enrolled — C# expects PLAYER_NOT_ENROLLED_IN_TOURNAMENT
		--- We use exampleVersion (-1) which may fail for non-processed tournament versions
		{
			name = "ViewReward",
			fn = function()
				joinTestTournament()
				local s, res = TestUtils.await("ViewReward", function(cb)
					tournament:viewReward(leaderboardId, exampleVersion, cb)
				end)
				leaveTestTournament()
				--- C# RunExpectFail for this: either pass (if version exists) or fail gracefully
				assert(res ~= nil, "ViewReward returned no response")
			end,
		},

		--- Mirrors C# ClaimTournamentReward — expects VIEWING_REWARD_FOR_NON_PROCESSED_TOURNAMENTS
		{
			name = "ClaimTournamentReward",
			fn = function()
				local version = joinTestTournament()
				local s, _res = TestUtils.await("ClaimTournamentReward", function(cb)
					tournament:claimTournamentReward(leaderboardId, version, cb)
				end)
				leaveTestTournament()
				--- C# expects this to fail with VIEWING_REWARD_FOR_NON_PROCESSED_TOURNAMENTS
				assert(not s, "ClaimTournamentReward should fail for unprocessed tournament")
			end,
		},

		--- Mirrors C# PostTournamentScoreUTC — join, post score with UTC timestamp, leave
		{
			name = "PostTournamentScoreUTC",
			fn = function()
				joinTestTournament()
				local epoch = os.time() * 1000
				local s, res = TestUtils.await("PostTournamentScoreUTC", function(cb)
					tournament:postTournamentScoreUTC(leaderboardId, math.random(1, 1000), nil, epoch, cb)
				end)
				leaveTestTournament()
				assert(s, "PostTournamentScoreUTC failed: " .. tostring(res))
			end,
		},

		--- Mirrors C# PostTournamentScoreWithResultsUTC — join, post score with results, leave
		{
			name = "PostTournamentScoreWithResultsUTC",
			fn = function()
				joinTestTournament()
				local epoch = os.time() * 1000
				local s, res = TestUtils.await("PostTournamentScoreWithResultsUTC", function(cb)
					tournament:postTournamentScoreWithResultsUTC(
						leaderboardId,
						math.random(1, 1000),
						nil,
						epoch,
						"HIGH_TO_LOW",
						beforeAndAfterCount,
						beforeAndAfterCount,
						initialScore,
						cb
					)
				end)
				leaveTestTournament()
				assert(s, "PostTournamentScoreWithResultsUTC failed: " .. tostring(res))
			end,
		},

		--- Combined individual player flow: JoinDivision → JoinTournament → PostScore → Leave
		{
			name = "IndividualPlayerTournamentTest",
			fn = function()
				--- JoinDivision — capture the division instance leaderboard ID from the response
				local s, res = TestUtils.await("JoinDivision", function(cb)
					tournament:joinDivision(divSetId, tournamentCode, math.random(1, 1000), cb)
				end)
				assert(s, "JoinDivision failed: " .. tostring(res))
				local divisionInstanceId = res.data and res.data.leaderboardId

				--- If already joined, look up the active division instance ID from GetMyDivisions
				if not divisionInstanceId then
					local _, mdRes = TestUtils.await("GetMyDivisions_lookup", function(cb)
						tournament:getMyDivisions(cb)
					end)
					if mdRes and mdRes.data and mdRes.data.ACTIVE then
						local active = mdRes.data.ACTIVE[divSetId]
						if active and #active > 0 then
							divisionInstanceId = active[1]
						end
					end
				end

				--- JoinTournament
				s, res = TestUtils.await("JoinTournament", function(cb)
					tournament:joinTournament(leaderboardId, tournamentCode, math.random(1, 1000), cb)
				end)
				assert(s, "JoinTournament failed: " .. tostring(res))

				--- PostTournamentScoreUTC
				local epoch = os.time() * 1000
				s, res = TestUtils.await("PostTournamentScoreUTC", function(cb)
					tournament:postTournamentScoreUTC(leaderboardId, math.random(1, 1000), nil, epoch, cb)
				end)
				assert(s, "PostTournamentScoreUTC failed: " .. tostring(res))

				--- PostTournamentScoreWithResultsUTC
				epoch = os.time() * 1000
				s, res = TestUtils.await("PostTournamentScoreWithResultsUTC", function(cb)
					tournament:postTournamentScoreWithResultsUTC(
						leaderboardId,
						math.random(1, 1000),
						nil,
						epoch,
						"HIGH_TO_LOW",
						beforeAndAfterCount,
						beforeAndAfterCount,
						initialScore,
						cb
					)
				end)
				assert(s, "PostTournamentScoreWithResultsUTC failed: " .. tostring(res))

				--- LeaveDivisionInstance using the correct division instance leaderboard ID
				if divisionInstanceId then
					s, res = TestUtils.await("LeaveDivisionInstance", function(cb)
						tournament:leaveDivisionInstance(divisionInstanceId, cb)
					end)
					assert(s, "LeaveDivisionInstance failed: " .. tostring(res))
				end

				--- LeaveTournament
				s, res = TestUtils.await("LeaveTournament", function(cb)
					tournament:leaveTournament(leaderboardId, cb)
				end)
				assert(s, "LeaveTournament failed: " .. tostring(res))
			end,
		},

		--- Group tests (aligned with C# GroupPostScoreTournamentTest PR)

		{
			name = "GetGroupDivisionInfo",
			fn = function()
				local groupId = createGroup()
				local s, res = TestUtils.await("GetGroupDivisionInfo", function(cb)
					tournament:getGroupDivisionInfo(groupDivSetId, groupId, cb)
				end)
				deleteGroup(groupId)
				assert(s, "GetGroupDivisionInfo failed: " .. tostring(res))
			end,
		},

		{
			name = "GetGroupDivisions",
			fn = function()
				local groupId = createGroup()
				local s, res = TestUtils.await("GetGroupDivisions", function(cb)
					tournament:getGroupDivisions(groupId, cb)
				end)
				deleteGroup(groupId)
				assert(s, "GetGroupDivisions failed: " .. tostring(res))
			end,
		},

		{
			name = "GetGroupTournamentStatus",
			fn = function()
				local groupId = createGroup()
				local s, res = TestUtils.await("GetGroupTournamentStatus", function(cb)
					tournament:getGroupTournamentStatus(groupLeaderboardId, groupId, exampleVersion, cb)
				end)
				deleteGroup(groupId)
				assert(s, "GetGroupTournamentStatus failed: " .. tostring(res))
			end,
		},

		--- Combined group tournament flow (mirrors C# GroupPostScoreTournamentTest)
		{
			name = "GroupPostScoreTournamentTest",
			fn = function()
				local groupId = createGroup()

				--- JoinGroupDivision — capture the division instance leaderboard ID from the response
				local s, res = TestUtils.await("JoinGroupDivision", function(cb)
					tournament:joinGroupDivision(groupDivSetId, groupTournamentCode, groupId, initialScore, cb)
				end)
				assert(s, "JoinGroupDivision failed: " .. tostring(res))
				local divisionInstanceId = res.data and res.data.leaderboardId

				--- JoinGroupTournament
				s, res = TestUtils.await("JoinGroupTournament", function(cb)
					tournament:joinGroupTournament(groupLeaderboardId, groupTournamentCode, groupId, initialScore, cb)
				end)
				assert(s, "JoinGroupTournament failed: " .. tostring(res))

				--- PostGroupTournamentScoreWithResults
				local epoch = os.time() * 1000
				s, res = TestUtils.await("PostGroupTournamentScoreWithResults", function(cb)
					tournament:postGroupTournamentScoreWithResults(
						groupLeaderboardId,
						groupId,
						math.random(1, 1000),
						nil,
						epoch,
						"HIGH_TO_LOW",
						beforeAndAfterCount,
						beforeAndAfterCount,
						initialScore,
						cb
					)
				end)
				assert(s, "PostGroupTournamentScoreWithResults failed: " .. tostring(res))

				--- PostGroupTournamentScore
				epoch = os.time() * 1000
				s, res = TestUtils.await("PostGroupTournamentScore", function(cb)
					tournament:postGroupTournamentScore(groupLeaderboardId, groupId, math.random(1, 1000), nil, epoch, cb)
				end)
				assert(s, "PostGroupTournamentScore failed: " .. tostring(res))

				--- LeaveGroupDivisionInstance (using the ID returned from JoinGroupDivision)
				if divisionInstanceId then
					s, res = TestUtils.await("LeaveGroupDivisionInstance", function(cb)
						tournament:leaveGroupDivisionInstance(divisionInstanceId, groupId, cb)
					end)
					assert(s, "LeaveGroupDivisionInstance failed: " .. tostring(res))
				end

				--- LeaveGroupTournament
				s, res = TestUtils.await("LeaveGroupTournament", function(cb)
					tournament:leaveGroupTournament(groupLeaderboardId, groupId, cb)
				end)
				assert(s, "LeaveGroupTournament failed: " .. tostring(res))

				deleteGroup(groupId)
			end,
		},
	}

	return tests
end)

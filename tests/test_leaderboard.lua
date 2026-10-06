--- Test_Leaderboard.lua
--- Server integration tests for BrainCloud Leaderboard
--- Mirrors C# TestLeaderboard.cs (same leaderboard ids on app 20001)

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Leaderboard", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")

	local leaderboard = client.leaderboard
	local group = client.group
	local SortOrder = leaderboard.SortOrder
	local LeaderboardType = leaderboard.LeaderboardType
	local RotationType = leaderboard.RotationType

	local GLOBAL_LB = "testLeaderboard"
	local SOCIAL_LB = "testSocialLeaderboard"
	local DYNAMIC_LB = "csTestDynamicLeaderboard"
	local GROUP_LB = "groupLeaderboardConfig"
	local MISSING_LB = "nonExistentLeaderboard"

	local function call(tag, fn)
		local s, r = TestUtils.await(tag, fn)
		return TestUtils.assertOk(tag, s, r)
	end

	local function inFiveDaysMs()
		return (os.time() + 5 * 24 * 60 * 60) * 1000
	end

	local function profileIds()
		return { TestUtils.users.A.profileId, TestUtils.users.B.profileId }
	end

	local function postGlobalScore()
		call("PostScoreToLeaderboard", function(cb)
			leaderboard:postScoreToLeaderboard(GLOBAL_LB, 10, { testDataKey = 400 }, cb)
		end)
	end

	local function postDynamic(leaderboardType, rotationResetUTC)
		call("PostScoreToDynamicLeaderboardUTC", function(cb)
			leaderboard:postScoreToDynamicLeaderboardUTC(
				DYNAMIC_LB,
				100,
				{ testDataKey = 400 },
				leaderboardType,
				RotationType.WEEKLY,
				rotationResetUTC,
				5,
				cb
			)
		end)
	end

	-- runs fn(groupId) against a throwaway "test" group, then deletes it
	local function withGroup(name, fn)
		local r = call("CreateGroup", function(cb)
			group:createGroup(name, "test", false, nil, nil, nil, nil, cb)
		end)
		local groupId = r.data.groupId
		local ok, err = pcall(fn, groupId)
		TestUtils.await("DeleteGroup", function(cb)
			group:deleteGroup(groupId, -1, cb)
		end)
		if not ok then
			error(err, 0)
		end
	end

	local function test(name, fn)
		return { name = name, fn = fn }
	end

	return {
		--- SOCIAL
		test("GetSocialLeaderboard", function()
			call("GetSocialLeaderboard", function(cb)
				leaderboard:getSocialLeaderboard(GLOBAL_LB, true, cb)
			end)
		end),
		test("GetSocialLeaderboardIfExists", function()
			call("GetSocialLeaderboardIfExists", function(cb)
				leaderboard:getSocialLeaderboardIfExists(GLOBAL_LB, true, cb)
			end)
			call("GetSocialLeaderboardIfExists missing", function(cb)
				leaderboard:getSocialLeaderboardIfExists(MISSING_LB, true, cb)
			end)
		end),
		test("GetSocialLeaderboardByVersion", function()
			call("GetSocialLeaderboardByVersion", function(cb)
				leaderboard:getSocialLeaderboardByVersion(GLOBAL_LB, true, 0, cb)
			end)
		end),
		test("GetSocialLeaderboardByVersionIfExists", function()
			call("GetSocialLeaderboardByVersionIfExists", function(cb)
				leaderboard:getSocialLeaderboardByVersionIfExists(GLOBAL_LB, true, 0, cb)
			end)
			call("GetSocialLeaderboardByVersionIfExists missing", function(cb)
				leaderboard:getSocialLeaderboardByVersionIfExists(MISSING_LB, true, 0, cb)
			end)
		end),
		test("GetMultiSocialLeaderboard", function()
			postGlobalScore()
			postDynamic(LeaderboardType.HIGH_VALUE, inFiveDaysMs())
			call("GetMultiSocialLeaderboard", function(cb)
				leaderboard:getMultiSocialLeaderboard({ GLOBAL_LB, DYNAMIC_LB }, 10, true, cb)
			end)
		end),

		--- POST / REMOVE
		test("PostScoreToLeaderboard", postGlobalScore),
		test("RemovePlayerScore", function()
			postGlobalScore()
			call("RemovePlayerScore", function(cb)
				leaderboard:removePlayerScore(GLOBAL_LB, -1, cb)
			end)
		end),

		--- GLOBAL
		test("GetGlobalLeaderboardPageHigh", function()
			call("GetGlobalLeaderboardPage", function(cb)
				leaderboard:getGlobalLeaderboardPage(GLOBAL_LB, SortOrder.HIGH_TO_LOW, 0, 10, cb)
			end)
		end),
		test("GetGlobalLeaderboardPageLow", function()
			call("GetGlobalLeaderboardPage", function(cb)
				leaderboard:getGlobalLeaderboardPage(GLOBAL_LB, SortOrder.LOW_TO_HIGH, 0, 10, cb)
			end)
		end),
		test("GetGlobalLeaderboardPageFail", function()
			local s, r = TestUtils.await("GetGlobalLeaderboardPage missing", function(cb)
				leaderboard:getGlobalLeaderboardPage("thisDoesNotExistLeaderboard", SortOrder.HIGH_TO_LOW, 0, 10, cb)
			end)
			TestUtils.assertFail("GetGlobalLeaderboardPage missing", s, r, 500, 40499)
		end),
		test("GetGlobalLeaderboardPageIfExists", function()
			call("GetGlobalLeaderboardPageIfExists", function(cb)
				leaderboard:getGlobalLeaderboardPageIfExists(GLOBAL_LB, SortOrder.HIGH_TO_LOW, 0, 10, cb)
			end)
			call("GetGlobalLeaderboardPageIfExists missing", function(cb)
				leaderboard:getGlobalLeaderboardPageIfExists(MISSING_LB, SortOrder.HIGH_TO_LOW, 0, 10, cb)
			end)
		end),
		test("GetGlobalLeaderboardPageByVersion", function()
			call("GetGlobalLeaderboardPageByVersion", function(cb)
				leaderboard:getGlobalLeaderboardPageByVersion(GLOBAL_LB, SortOrder.HIGH_TO_LOW, 0, 10, 1, cb)
			end)
		end),
		test("GetGlobalLeaderboardPageByVersionIfExists", function()
			call("GetGlobalLeaderboardPageByVersionIfExists", function(cb)
				leaderboard:getGlobalLeaderboardPageByVersionIfExists(GLOBAL_LB, SortOrder.HIGH_TO_LOW, 0, 10, 1, cb)
			end)
			call("GetGlobalLeaderboardPageByVersionIfExists missing", function(cb)
				leaderboard:getGlobalLeaderboardPageByVersionIfExists(MISSING_LB, SortOrder.HIGH_TO_LOW, 0, 10, 1, cb)
			end)
		end),
		test("GetGlobalLeaderboardVersions", function()
			call("GetGlobalLeaderboardVersions", function(cb)
				leaderboard:getGlobalLeaderboardVersions(GLOBAL_LB, cb)
			end)
		end),
		test("GetGlobalLeaderboardView", function()
			call("GetGlobalLeaderboardView", function(cb)
				leaderboard:getGlobalLeaderboardView(GLOBAL_LB, SortOrder.HIGH_TO_LOW, 5, 5, cb)
			end)
		end),
		test("GetGlobalLeaderboardViewIfExists", function()
			call("GetGlobalLeaderboardViewIfExists", function(cb)
				leaderboard:getGlobalLeaderboardViewIfExists(GLOBAL_LB, SortOrder.HIGH_TO_LOW, 5, 5, cb)
			end)
			call("GetGlobalLeaderboardViewIfExists missing", function(cb)
				leaderboard:getGlobalLeaderboardViewIfExists(MISSING_LB, SortOrder.HIGH_TO_LOW, 5, 5, cb)
			end)
		end),
		test("GetGlobalLeaderboardViewByVersion", function()
			call("GetGlobalLeaderboardViewByVersion", function(cb)
				leaderboard:getGlobalLeaderboardViewByVersion(GLOBAL_LB, SortOrder.HIGH_TO_LOW, 5, 5, 1, cb)
			end)
		end),
		test("GetGlobalLeaderboardViewByVersionIfExists", function()
			call("GetGlobalLeaderboardViewByVersionIfExists", function(cb)
				leaderboard:getGlobalLeaderboardViewByVersionIfExists(GLOBAL_LB, SortOrder.HIGH_TO_LOW, 5, 5, 1, cb)
			end)
			call("GetGlobalLeaderboardViewByVersionIfExists missing", function(cb)
				leaderboard:getGlobalLeaderboardViewByVersionIfExists(MISSING_LB, SortOrder.HIGH_TO_LOW, 5, 5, 1, cb)
			end)
		end),
		test("GetGlobalLeaderboardEntryCount", function()
			call("GetGlobalLeaderboardEntryCount", function(cb)
				leaderboard:getGlobalLeaderboardEntryCount(GLOBAL_LB, cb)
			end)
		end),
		test("GetGlobalLeaderboardEntryCountByVersion", function()
			call("GetGlobalLeaderboardEntryCountByVersion", function(cb)
				leaderboard:getGlobalLeaderboardEntryCountByVersion(GLOBAL_LB, 1, cb)
			end)
		end),
		test("ListAllLeaderboards", function()
			call("ListAllLeaderboards", function(cb)
				leaderboard:listAllLeaderboards(cb)
			end)
		end),

		--- DYNAMIC
		test("PostScoreToDynamicLeaderboardHighValue", function()
			postDynamic(LeaderboardType.HIGH_VALUE, inFiveDaysMs())
		end),
		test("PostScoreToDynamicLeaderboardLowValue", function()
			postDynamic(LeaderboardType.LOW_VALUE, inFiveDaysMs())
		end),
		test("PostScoreToDynamicLeaderboardCumulative", function()
			postDynamic(LeaderboardType.CUMULATIVE, inFiveDaysMs())
		end),
		test("PostScoreToDynamicLeaderboardLastValue", function()
			postDynamic(LeaderboardType.LAST_VALUE, inFiveDaysMs())
		end),
		test("PostScoreToDynamicLeaderboardNullRotationTime", function()
			postDynamic(LeaderboardType.HIGH_VALUE, nil)
		end),
		test("PostScoreToDynamicLeaderboardDays", function()
			call("PostScoreToDynamicLeaderboardDaysUTC", function(cb)
				leaderboard:postScoreToDynamicLeaderboardDaysUTC(
					DYNAMIC_LB .. "_days",
					100,
					{ testDataKey = 400 },
					LeaderboardType.HIGH_VALUE,
					inFiveDaysMs(),
					5,
					3,
					cb
				)
			end)
		end),
		test("PostScoreToDynamicLeaderboardUsingConfig", function()
			local configJson = {
				leaderboardType = "HIGH_VALUE",
				rotationType = "DAYS",
				numDaysToRotate = "4",
				resetAt = inFiveDaysMs(),
				retainedCount = 2,
			}
			call("PostScoreToDynamicLeaderboardUsingConfig", function(cb)
				leaderboard:postScoreToDynamicLeaderboardUsingConfig(DYNAMIC_LB, 10, { nickname = "CSharpTester" }, configJson, cb)
			end)
		end),

		--- PLAYER SCORES
		test("GetPlayersSocialLeaderboard", function()
			call("GetPlayersSocialLeaderboard", function(cb)
				leaderboard:getPlayersSocialLeaderboard(SOCIAL_LB, profileIds(), cb)
			end)
		end),
		test("GetPlayersSocialLeaderboardIfExists", function()
			call("GetPlayersSocialLeaderboardIfExists", function(cb)
				leaderboard:getPlayersSocialLeaderboardIfExists(SOCIAL_LB, profileIds(), cb)
			end)
			call("GetPlayersSocialLeaderboardIfExists missing", function(cb)
				leaderboard:getPlayersSocialLeaderboardIfExists(MISSING_LB, profileIds(), cb)
			end)
		end),
		test("GetPlayersSocialLeaderboardByVersion", function()
			call("GetPlayersSocialLeaderboardByVersion", function(cb)
				leaderboard:getPlayersSocialLeaderboardByVersion(SOCIAL_LB, profileIds(), 0, cb)
			end)
		end),
		test("GetPlayersSocialLeaderboardByVersionIfExists", function()
			call("GetPlayersSocialLeaderboardByVersionIfExists", function(cb)
				leaderboard:getPlayersSocialLeaderboardByVersionIfExists(SOCIAL_LB, profileIds(), 0, cb)
			end)
			call("GetPlayersSocialLeaderboardByVersionIfExists missing", function(cb)
				leaderboard:getPlayersSocialLeaderboardByVersionIfExists(MISSING_LB, profileIds(), 0, cb)
			end)
		end),
		test("GetPlayerScore", function()
			postGlobalScore()
			call("GetPlayerScore", function(cb)
				leaderboard:getPlayerScore(GLOBAL_LB, -1, cb)
			end)
		end),
		test("GetPlayerScores", function()
			postGlobalScore()
			call("GetPlayerScores", function(cb)
				leaderboard:getPlayerScores(GLOBAL_LB, -1, 4, cb)
			end)
		end),
		test("GetPlayerScoresFromLeaderboards", function()
			postGlobalScore()
			postDynamic(LeaderboardType.HIGH_VALUE, inFiveDaysMs())
			call("GetPlayerScoresFromLeaderboards", function(cb)
				leaderboard:getPlayerScoresFromLeaderboards({ GLOBAL_LB, DYNAMIC_LB }, cb)
			end)
		end),

		--- GROUP
		test("PostScoreToDynamicGroupLeaderboardUTC", function()
			withGroup("a-group-id", function(groupId)
				call("PostScoreToDynamicGroupLeaderboardUTC", function(cb)
					leaderboard:postScoreToDynamicGroupLeaderboardUTC(
						DYNAMIC_LB .. "_HIGH_VALUE_" .. math.random(1, 2 ^ 30),
						groupId,
						100,
						{ testDataKey = 400 },
						LeaderboardType.HIGH_VALUE,
						RotationType.WEEKLY,
						inFiveDaysMs(),
						5,
						cb
					)
				end)
			end)
		end),
		test("GetGroupSocialLeaderboard", function()
			withGroup("testLBGroup", function(groupId)
				call("GetGroupSocialLeaderboard", function(cb)
					leaderboard:getGroupSocialLeaderboard(SOCIAL_LB, groupId, cb)
				end)
			end)
		end),
		test("GetGroupSocialLeaderboardByVersion", function()
			withGroup("testLBGroup", function(groupId)
				call("GetGroupSocialLeaderboardByVersion", function(cb)
					leaderboard:getGroupSocialLeaderboardByVersion(SOCIAL_LB, groupId, 0, cb)
				end)
			end)
		end),
		test("PostScoreToGroupLeaderboard", function()
			withGroup("testGroup", function(groupId)
				call("PostScoreToGroupLeaderboard", function(cb)
					leaderboard:postScoreToGroupLeaderboard(GROUP_LB, groupId, 0, { testy = 400 }, cb)
				end)
			end)
		end),
		test("RemoveGroupScore", function()
			withGroup("testGroup", function(groupId)
				call("PostScoreToGroupLeaderboard", function(cb)
					leaderboard:postScoreToGroupLeaderboard(GROUP_LB, groupId, 100, { testy = 400 }, cb)
				end)
				call("RemoveGroupScore", function(cb)
					leaderboard:removeGroupScore(GROUP_LB, groupId, -1, cb)
				end)
			end)
		end),
		test("GetGroupLeaderboardView", function()
			withGroup("testGroup", function(groupId)
				call("GetGroupLeaderboardView", function(cb)
					leaderboard:getGroupLeaderboardView(GROUP_LB, groupId, SortOrder.HIGH_TO_LOW, 5, 5, cb)
				end)
			end)
		end),
		test("GetGroupLeaderboardViewByVersion", function()
			withGroup("testLBGroup", function(groupId)
				call("GetGroupLeaderboardViewByVersion", function(cb)
					leaderboard:getGroupLeaderboardViewByVersion(GROUP_LB, groupId, 1, SortOrder.HIGH_TO_LOW, 5, 5, cb)
				end)
			end)
		end),

		--- CLEANUP
		test("DeleteDynamicLeaderboards", function()
			call("CleanupLeaderboards", function(cb)
				client.script:runScript("CleanupLeaderboards", { leaderboardId = DYNAMIC_LB }, cb)
			end)
		end),
	}
end)

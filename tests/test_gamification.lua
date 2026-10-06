--- Test_Gamification.lua
--- Server integration tests for Gamification service (with type-based asserts)

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Gamification", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")
	local gamification = client.gamification
	assert(gamification, "Gamification module missing")

	local tests = {
		--- 1. ReadAllGamification
		{
			name = "ReadAllGamification",
			fn = function()
				local s, res = TestUtils.await("ReadAllGamification", function(r)
					gamification:readAllGamification(r)
				end)
				assert(s, "ReadAllGamification failed")
				assert(type(res.data.achievements) == "table", "Expected achievements table")
				assert(type(res.data.xp) == "table", "Expected xp table")
				assert(type(res.data.quests) == "table", "Expected quests table")
			end,
		},

		--- 2. AwardAchievements
		{
			name = "AwardAchievements",
			fn = function()
				local s, res = TestUtils.await("AwardAchievements", function(r)
					gamification:awardAchievements({ "testAchievement" }, r)
				end)
				assert(s, "AwardAchievements failed")
				assert(type(res.data.achievements) == "table", "Expected achievements table")
			end,
		},

		--- 3. ReadAchievedAchievements
		{
			name = "ReadAchievedAchievements",
			fn = function()
				local s, res = TestUtils.await("ReadAchievedAchievements", function(r)
					gamification:readAchievedAchievements(r)
				end)
				assert(s, "ReadAchievedAchievements failed")
				assert(type(res.data.achievements) == "table", "Expected achievements table")
			end,
		},

		--- 4. ReadXPLevelsMetaData
		{
			name = "ReadXPLevelsMetaData",
			fn = function()
				local s, res = TestUtils.await("ReadXPLevelsMetaData", function(r)
					gamification:readXPLevelsMetaData(r)
				end)
				assert(s, "ReadXPLevelsMetaData failed")
				assert(type(res.data.xp_levels) == "table", "Expected levels table")
			end,
		},

		--- 5. ReadAchievements
		{
			name = "ReadAchievements",
			fn = function()
				local s, res = TestUtils.await("ReadAchievements", function(r)
					gamification:readAchievements(r)
				end)
				assert(s, "ReadAchievements failed")
				assert(type(res.data.achievements) == "table", "Expected achievements table")
			end,
		},

		--- 6. ReadMilestones
		{
			name = "ReadMilestones",
			fn = function()
				local s, res = TestUtils.await("ReadMilestones", function(r)
					gamification:readMilestones(r)
				end)
				assert(s, "ReadMilestones failed")
				assert(type(res.data.milestones) == "table", "Expected milestones table")
			end,
		},

		--- 7. ReadMilestonesByCategory
		{
			name = "ReadMilestonesByCategory",
			fn = function()
				local s, res = TestUtils.await("ReadMilestonesByCategory", function(r)
					gamification:readMilestonesByCategory("default", r)
				end)
				assert(s, "ReadMilestonesByCategory failed")
				assert(type(res.data.milestones) == "table", "Expected milestones table")
			end,
		},

		--- 8. ReadCompletedMilestones
		{
			name = "ReadCompletedMilestones",
			fn = function()
				local s, res = TestUtils.await("ReadCompletedMilestones", function(r)
					gamification:readCompletedMilestones(r)
				end)
				assert(s, "ReadCompletedMilestones failed")
				assert(type(res.data.milestones) == "table", "Expected milestones table")
			end,
		},

		--- 9. ReadInProgressMilestones
		{
			name = "ReadInProgressMilestones",
			fn = function()
				local s, res = TestUtils.await("ReadInProgressMilestones", function(r)
					gamification:readInProgressMilestones(r)
				end)
				assert(s, "ReadInProgressMilestones failed")
				assert(type(res.data.milestones) == "table", "Expected milestones table")
			end,
		},

		--- 10. ReadQuests
		{
			name = "ReadQuests",
			fn = function()
				local s, res = TestUtils.await("ReadQuests", function(r)
					gamification:readQuests(r)
				end)
				assert(s, "ReadQuests failed")
				assert(type(res.data.quests) == "table", "Expected quests table")
			end,
		},

		--- 11. ReadQuestsByCategory
		{
			name = "ReadQuestsByCategory",
			fn = function()
				local s, res = TestUtils.await("ReadQuestsByCategory", function(r)
					gamification:readQuestsByCategory("default", r)
				end)
				assert(s, "ReadQuestsByCategory failed")
				assert(type(res.data.quests) == "table", "Expected quests table")
			end,
		},

		--- 12. ReadCompletedQuests
		{
			name = "ReadCompletedQuests",
			fn = function()
				local s, res = TestUtils.await("ReadCompletedQuests", function(r)
					gamification:readCompletedQuests(r)
				end)
				assert(s, "ReadCompletedQuests failed")
				assert(type(res.data.quests) == "table", "Expected quests table")
			end,
		},

		--- 13. ReadInProgressQuests
		{
			name = "ReadInProgressQuests",
			fn = function()
				local s, res = TestUtils.await("ReadInProgressQuests", function(r)
					gamification:readInProgressQuests(r)
				end)
				assert(s, "ReadInProgressQuests failed")
				assert(type(res.data.quests) == "table", "Expected quests table")
			end,
		},

		--- 14. ReadNotStartedQuests
		{
			name = "ReadNotStartedQuests",
			fn = function()
				local s, res = TestUtils.await("ReadNotStartedQuests", function(r)
					gamification:readNotStartedQuests(r)
				end)
				assert(s, "ReadNotStartedQuests failed")
				assert(type(res.data.quests) == "table", "Expected quests table")
			end,
		},

		--- 15. ReadQuestsWithStatus
		{
			name = "ReadQuestsWithStatus",
			fn = function()
				local s, res = TestUtils.await("ReadQuestsWithStatus", function(r)
					gamification:readQuestsWithStatus(r)
				end)
				assert(s, "ReadQuestsWithStatus failed")
				assert(type(res.data.quests) == "table", "Expected quests table")
			end,
		},

		--- 16. ReadQuestsWithBasicPercentage
		{
			name = "ReadQuestsWithBasicPercentage",
			fn = function()
				local s, res = TestUtils.await("ReadQuestsWithBasicPercentage", function(r)
					gamification:readQuestsWithBasicPercentage(r)
				end)
				assert(s, "ReadQuestsWithBasicPercentage failed")
				assert(type(res.data.quests) == "table", "Expected quests table")
				for _, q in ipairs(res.data.quests) do
					assert(type(q.percentage) == "number", "Expected percentage number")
				end
			end,
		},

		--- 17. ReadQuestsWithComplexPercentage
		{
			name = "ReadQuestsWithComplexPercentage",
			fn = function()
				local s, res = TestUtils.await("ReadQuestsWithComplexPercentage", function(r)
					gamification:readQuestsWithComplexPercentage(r)
				end)
				assert(s, "ReadQuestsWithComplexPercentage failed")
				assert(type(res.data.quests) == "table", "Expected quests table")
				for _, q in ipairs(res.data.quests) do
					assert(type(q.percentage) == "number", "Expected percentage number")
				end
			end,
		},
	}

	return tests
end)

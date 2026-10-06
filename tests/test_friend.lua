--- Test_Friend.lua (Enhanced Assertions)

local TestUtils = require("tests.shared")

local client = nil

local function allowedFailure(res)
	if not res or not res.status then
		return false
	end

	local okCodes = {
		[client.reasonCodes.INVALID_EXT_AUTH_TYPE] = true,
		[client.reasonCodes.INVALID_PARAMETER_VALUE] = true,
	}

	return okCodes[res.reason_code] == true
end

return TestUtils.buildRunner("Friend", nil, function(runnerClient)
	client = runnerClient
	assert(client, "[TEST] brainCloud client not created")
	local friend = client.friend
	assert(friend, "Friend module missing")
	-- UserA's universal credential, same as C#
	local profileId = TestUtils.users.A.profileId
	local externalId = TestUtils.users.A.id

	--- TEST SUITE

	local tests = {

		--- 1. GetProfileInfoForCredential
		{
			name = "GetProfileInfoForCredential",
			fn = function()
				local s, res = TestUtils.await("GetProfileInfoForCredential", function(r)
					friend:getProfileInfoForCredential(externalId, "Universal", r)
				end)

				assert(s or allowedFailure(res), "Unexpected GetProfileInfoForCredential failure")

				if s then
					assert(res.data.playerId == TestUtils.users.A.profileId, "Expected UserA playerId")
				end
			end,
		},

		--- 2. GetProfileInfoForCredentialIfExists
		{
			name = "GetProfileInfoForCredentialIfExists",
			fn = function()
				local s, res = TestUtils.await("GetProfileInfoForCredentialIfExists", function(r)
					friend:getProfileInfoForCredentialIfExists(externalId, "Universal", r)
				end)

				assert(s or allowedFailure(res), "Unexpected GetProfileInfoForCredentialIfExists failure")
			end,
		},

		--- 3. GetProfileInfoForExternalAuthId
		{
			name = "GetProfileInfoForExternalAuthId",
			fn = function()
				local s, res = TestUtils.await("GetProfileInfoForExternalAuthId", function(r)
					friend:getProfileInfoForExternalAuthId("fake", "facebook", r)
				end)

				--- External auth often is not configured → allow 400/403/404
				assert(s or allowedFailure(res), "Unexpected GetProfileInfoForExternalAuthId failure")
			end,
		},

		--- 4. GetProfileInfoForExternalAuthIdIfExists
		{
			name = "GetProfileInfoForExternalAuthIdIfExists",
			fn = function()
				local s, res = TestUtils.await("GetProfileInfoForExternalAuthIdIfExists", function(r)
					friend:getProfileInfoForExternalAuthIdIfExists("fake", "facebook", r)
				end)

				assert(s or allowedFailure(res), "Unexpected GetProfileInfoForExternalAuthIdIfExists failure")
			end,
		},

		--- 5. GetExternalIdForProfileId
		{
			name = "GetExternalIdForProfileId",
			fn = function()
				local s, res = TestUtils.await("GetExternalIdForProfileId", function(r)
					friend:getExternalIdForProfileId(profileId, "Universal", r)
				end)

				assert(s or allowedFailure(res), "Unexpected GetExternalIdForProfileId failure")

				if s then
					assert(type(res.data.externalId) == "string", "Missing externalId")
				end
			end,
		},

		--- 11. AddFriends
		{
			name = "AddFriends",
			fn = function()
				local s, res = TestUtils.await("AddFriends", function(r)
					friend:addFriends({ TestUtils.TEST_USER_OPP_PROFILE_ID }, r)
				end)

				assert(s or allowedFailure(res), "Unexpected AddFriends failure")
			end,
		},

		--- 12. AddFriendsFromPlatform
		{
			name = "AddFriendsFromPlatform",
			fn = function()
				local s, res = TestUtils.await("AddFriendsFromPlatform", function(r)
					friend:addFriendsFromPlatform(client.friend.FRIEND_PLATFORM.Facebook, "ADD", {}, r)
				end)

				assert(s or allowedFailure(res), "Unexpected AddFriendsFromPlatform failure")
			end,
		},

		--- 6. ReadFriendEntity
		{
			name = "ReadFriendEntity",
			fn = function()
				local s, res = TestUtils.await("ReadFriendEntity", function(r)
					friend:readFriendEntity(TestUtils.TEST_USER_OPP_PROFILE_ID, "testEntityId", r)
				end)

				assert(s or allowedFailure(res), "Unexpected ReadFriendEntity failure")

				if s and res.data.entity ~= nil then
					assert(type(res.data.entityId) == "string", "Missing entityId")
				end
			end,
		},

		--- 7. ReadFriendsEntities
		{
			name = "ReadFriendsEntities",
			fn = function()
				local s, res = TestUtils.await("ReadFriendsEntities", function(r)
					friend:readFriendsEntities("testEntityType", r)
				end)

				assert(s or allowedFailure(res), "Unexpected ReadFriendsEntities failure")

				if s then
					assert(type(res.data.results) == "table", "Missing entities table")
				end
			end,
		},

		--- 8. ReadFriendUserState
		{
			name = "ReadFriendUserState",
			fn = function()
				local s, res = TestUtils.await("ReadFriendUserState", function(r)
					friend:readFriendUserState(TestUtils.TEST_USER_OPP_PROFILE_ID, r)
				end)

				assert(s or allowedFailure(res), "Unexpected ReadFriendUserState failure")

				if s then
					assert(type(res.data.playerName) == "string", "Missing playerName")
				end
			end,
		},

		--- 9. ListFriends
		{
			name = "ListFriends",
			fn = function()
				local s, res = TestUtils.await("ListFriends", function(r)
					friend:listFriends(client.friend.FRIEND_PLATFORM.Steam, true, r)
				end)

				assert(s or allowedFailure(res), "Unexpected ListFriends failure")

				if s then
					assert(type(res.data.friends) == "table", "Missing friends list")
				end
			end,
		},

		--- 10. GetMySocialInfo
		{
			name = "GetMySocialInfo",
			fn = function()
				local s, res = TestUtils.await("GetMySocialInfo", function(r)
					friend:getMySocialInfo(client.friend.FRIEND_PLATFORM.Steam, true, r)
				end)

				assert(s or allowedFailure(res), "Unexpected GetMySocialInfo failure")

				if s then
					assert(type(res.data.name) == "string", "Missing playerName")
				end
			end,
		},

		--- 13. RemoveFriends
		{
			name = "RemoveFriends",
			fn = function()
				local s, res = TestUtils.await("RemoveFriends", function(r)
					friend:removeFriends({ TestUtils.TEST_USER_OPP_PROFILE_ID }, r)
				end)

				assert(s or allowedFailure(res), "Unexpected RemoveFriends failure")
			end,
		},

		--- 14. GetSummaryDataForProfileId
		{
			name = "GetSummaryDataForProfileId",
			fn = function()
				local s, res = TestUtils.await("GetSummaryDataForProfileId", function(r)
					friend:getSummaryDataForProfileId(profileId, r)
				end)

				assert(s or allowedFailure(res), "Unexpected GetSummaryDataForProfileId failure")

				if s then
					assert(type(res.data.summary) == "table" or res.data.summary == nil, "Invalid summary data")
				end
			end,
		},

		--- 15. GetUsersOnlineStatus
		{
			name = "GetUsersOnlineStatus",
			fn = function()
				local s, res = TestUtils.await("GetUsersOnlineStatus", function(r)
					friend:getUsersOnlineStatus({ profileId }, r)
				end)

				assert(s or allowedFailure(res), "Unexpected GetUsersOnlineStatus failure")

				if s then
					assert(type(res.data.onlineStatus) == "table", "Missing users table")
				end
			end,
		},

		--- 16. FindUsersByExactName
		{
			name = "FindUsersByExactName",
			fn = function()
				local s, res = TestUtils.await("FindUsersByExactName", function(r)
					friend:findUsersByExactName("bitHead22", 10, r)
				end)

				assert(s or allowedFailure(res), "Unexpected FindUsersByExactName failure")
			end,
		},

		--- 17. FindUsersBySubstrName
		{
			name = "FindUsersBySubstrName",
			fn = function()
				local s, res = TestUtils.await("FindUsersBySubstrName", function(r)
					friend:findUsersBySubstrName("bitHead", 10, r)
				end)

				assert(s or allowedFailure(res), "Unexpected FindUsersBySubstrName failure")
			end,
		},

		--- 18. FindUsersByNameStartingWith
		{
			name = "FindUsersByNameStartingWith",
			fn = function()
				local s, res = TestUtils.await("FindUsersByNameStartingWith", function(r)
					friend:findUsersByNameStartingWith("bit", 10, r)
				end)

				assert(s or allowedFailure(res), "Unexpected FindUsersByNameStartingWith failure")
			end,
		},

		--- 19. FindUsersByUniversalIdStartingWith
		{
			name = "FindUsersByUniversalIdStartingWith",
			fn = function()
				local s, res = TestUtils.await("FindUsersByUniversalIdStartingWith", function(r)
					friend:findUsersByUniversalIdStartingWith("bit", 10, r)
				end)

				assert(s or allowedFailure(res), "Unexpected FindUsersByUniversalIdStartingWith failure")
			end,
		},

		--- 20. FindUserByExactUniversalId
		{
			name = "FindUserByExactUniversalId",
			fn = function()
				local s, res = TestUtils.await("FindUserByExactUniversalId", function(r)
					friend:findUserByExactUniversalId("bitHeadDude", r)
				end)

				assert(s or allowedFailure(res), "Unexpected FindUserByExactUniversalId failure")
			end,
		},
	}

	return tests
end)

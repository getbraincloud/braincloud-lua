--- Test_PlayerState.lua
--- Comprehensive server integration tests for BrainCloud PlayerState

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("PlayerState", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")

	local playerState = client.playerState
	assert(playerState, "[TEST] PlayerState module missing")

	--- Define all tests
	local tests = {

		{
			name = "UpdateUserName",
			fn = function()
				local s, response = TestUtils.await("UpdateUserName", function(r)
					playerState:updateUserName("test_user", r)
				end)
				assert(s, " failed")
				assert(response.data.playerName == "test_user", "PlayerName not updated correctly")
			end,
		},
		{
			name = "ReadUserState",
			fn = function()
				local s, response = TestUtils.await("ReadUserState", function(r)
					playerState:readUserState(r)
				end)
				assert(s, " failed")
				assert(response.data.playerName, "Missing playerName")
				assert(response.data.profileId, "Missing profileId")
				assert(type(response.data.statistics) == "table", "Statistics not returned")
			end,
		},
		{
			name = "GetAttributes",
			fn = function()
				local s, response = TestUtils.await("GetAttributes", function(r)
					playerState:getAttributes(r)
				end)
				assert(s, " failed")
				assert(type(response.data.attributes) == "table", "Attributes not returned")
			end,
		},
		{
			name = "UpdateAttributes",
			fn = function()
				local attributes = { level = "" .. math.random(1, 100) }
				local s, response = TestUtils.await("UpdateAttributes", function(r)
					playerState:updateAttributes(attributes, false, r)
				end)
				assert(s, " failed")
				assert(
					response.status == 200 or response.data.attributes.level == attributes.level,
					"Attribute not updated correctly"
				)
			end,
		},
		{
			name = "RemoveAttributes",
			fn = function()
				local attributes = { "level" }
				local s, response = TestUtils.await("RemoveAttributes", function(r)
					playerState:removeAttributes(attributes, r)
				end)
				assert(s, " failed")
				assert(response.status == 200, "RemoveAttributes did not return 200 status")
			end,
		},
		{
			name = "UpdateUserPictureUrl",
			fn = function()
				local url = "https://example.com/avatar.png"
				local s, response = TestUtils.await("UpdateUserPictureUrl", function(r)
					playerState:updateUserPictureUrl(url, r)
				end)
				assert(s, " failed")
				assert(response.data.playerPictureUrl == url, "Picture URL not updated correctly")
			end,
		},
		{
			name = "UpdateContactEmail",
			fn = function()
				local email = "test@example.com"
				local s, response = TestUtils.await("UpdateContactEmail", function(r)
					playerState:updateContactEmail(email, r)
				end)
				assert(s, " failed")
				assert(response.data.contactEmail == email, "Contact email not updated correctly")
			end,
		},
		{
			name = "ClearUserStatus",
			fn = function()
				local s, response = TestUtils.await("ClearUserStatus", function(r)
					playerState:clearUserStatus("testStatus", r)
				end)
				assert(s, " failed")
				assert(response.status == 200, "ClearUserStatus did not return 200 status")
			end,
		},
		{
			name = "ExtendUserStatus",
			fn = function()
				local s, response = TestUtils.await("ExtendUserStatus", function(r)
					playerState:extendUserStatus("testStatus", 60, { extra = "data" }, r)
				end)
				assert(s, " failed")
				assert(response.data.statusName == "testStatus", "Status name incorrect")
				assert(response.data.details and response.data.details.extra == "data", "Status details incorrect")
			end,
		},
		{
			name = "SetUserStatus",
			fn = function()
				local s, response = TestUtils.await("SetUserStatus", function(r)
					playerState:setUserStatus("testStatus", 120, { extra = "data" }, r)
				end)
				assert(s, " failed")
				assert(response.data.testStatus.statusName == "testStatus", "Status name incorrect ")
				assert(
					response.data.testStatus.details and response.data.testStatus.details.extra == "data",
					"Status details incorrect"
				)
			end,
		},
		{
			name = "GetUserStatus",
			fn = function()
				local s, response = TestUtils.await("GetUserStatus", function(r)
					playerState:getUserStatus("testStatus", r)
				end)
				assert(s, "GetUserStatus failed")
				assert(response.data.testStatus.statusName == "testStatus", "Status name incorrect ")
				assert(
					response.data.testStatus.details and response.data.testStatus.details.extra == "data",
					"Status details incorrect"
				)
			end,
		},
		{
			name = "UpdateTimeZoneOffset",
			fn = function()
				local s, response = TestUtils.await("UpdateTimeZoneOffset", function(r)
					playerState:updateTimeZoneOffset(0, r)
				end)
				assert(s, " failed")
				assert(response.data.timeZoneOffset == 0, "TimeZoneOffset not updated correctly")
			end,
		},
		{
			name = "UpdateLanguageCode",
			fn = function()
				local s, response = TestUtils.await("UpdateLanguageCode", function(r)
					playerState:updateLanguageCode("en", r)
				end)
				assert(s, " failed")
				assert(response.data.languageCode == "en", "Language code not updated correctly")
			end,
		},
		--{
		---    name = "ResetUser",
		---    fn = function()
		---        local s = TestUtils.await("ResetUser", function(r)
		---            playerState:resetUser(r)
		---        end)
		---        assert(s, "failed")
		---    end
		--},
		--{
		---    name = "DeleteUser",
		---    fn = function()
		---        local s = TestUtils.await("DeleteUser", function(r)
		---            playerState:deleteUser(r)
		---        end)
		---        assert(s, "failed")
		---    end
		--},
		--{
		---    name = "Logout",
		---    fn = function()
		---        local s = TestUtils.await("Logout", function(r)
		---            playerState:logout(r)
		---        end)
		---        assert(s, "failed")
		---    end
		--},
	}

	return tests
end)

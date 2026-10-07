--- Test_Authentication.lua
--- Server integration tests for BrainCloud Authentication
--- Mirrors the intention and coverage of C# TestAuthenticate.cs
local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Authentication", nil, function(client, wrapper)
	assert(client, "[TEST] brainCloud client not created")

	local auth = client.authentication
	assert(auth, "[TEST] Missing authentication module")

	local userA = TestUtils.users.A
	local TEST_UNIVERSAL_USERNAME = userA.id
	local TEST_UNIVERSAL_PASSWORD = userA.password
	local TEST_EMAIL = userA.email
	local TEST_EMAIL_PASSWORD = userA.password
	-- C# resets email passwords against this shared email identity
	local RESET_EMAIL = "braincloudunittest@gmail.com"

	local function authAsResetEmail()
		-- a different identity; the saved UserA profileId would be rejected
		auth:clearSavedSession()
		local s, r = TestUtils.await("AuthResetEmail", function(ready)
			auth:authenticateEmailPassword(RESET_EMAIL, RESET_EMAIL, true, ready)
		end)
		TestUtils.assertOk("AuthResetEmail", s, r)
	end

	local function authAsUserA()
		TestUtils.authenticateAs(client, "A")
	end

	--- Define all tests
	return {
		--- Mirrors C# anonymous ID uniqueness check
		{
			name = "Anonymous ID Uniqueness Test",
			fn = function()
				local guids = {}
				local duplicateFound = false
				local NUM_TESTS = 1000

				for _ = 1, NUM_TESTS do
					local id = auth:generateAnonymousId()
					if guids[id] then
						duplicateFound = true
						break
					else
						guids[id] = true
					end
				end

				assert(not duplicateFound, "Duplicate GUIDs detected in Anonymous ID generation")
			end,
		},

		--- Mirrors C# Logout + clearSavedSession before fresh auth tests
		{
			name = "Logout",
			fn = function()
				local s, r = TestUtils.await("Logout", function(ready)
					auth:logout(ready)
				end)
				assert(s, "Logout failed: " .. TestUtils.describe(r))
				auth:clearSavedSession()
			end,
		},

		--- Mirrors C# TestAuthenticateAnonymous — create new user, then delete (clean state)
		{
			name = "Anonymous Authentication",
			fn = function()
				auth:initialize(auth:generateAnonymousId(), auth:generateAnonymousId())
				auth:clearSavedProfileId()

				local s, r = TestUtils.await("AuthenticateAnonymous", function(ready)
					auth:authenticateAnonymous(true, ready)
				end)
				assert(s, "AuthenticateAnonymous failed: " .. TestUtils.describe(r))
				assert(r.data.profileId, "Missing profileId")
				assert(r.data.sessionId, "Missing sessionId")

				--- Delete the newly created user to keep the environment clean
				local sd, _rd = TestUtils.await("DeleteUser", function(ready)
					client:sendRequest("playerState", "FULL_PLAYER_RESET", {}, ready)
				end)
				assert(sd, "FULL_PLAYER_RESET failed")
				auth:clearSavedSession()
			end,
		},

		--- Mirrors C# TestAuthenticateUniversal
		{
			name = "Universal Authentication",
			fn = function()
				local s, r = TestUtils.await("AuthenticateUniversal", function(ready)
					auth:authenticateUniversal(TEST_UNIVERSAL_USERNAME, TEST_UNIVERSAL_PASSWORD, true, ready)
				end)
				assert(s, "AuthenticateUniversal failed: " .. TestUtils.describe(r))
				assert(r.data.profileId, "Missing profileId")
				assert(r.data.sessionId, "Missing sessionId")
			end,
		},

		--- Mirrors C# TestAuthenticateEmailPassword
		{
			name = "EmailPassword Authentication",
			fn = function()
				local _, _r = TestUtils.await("Logout", function(ready)
					auth:logout(ready)
				end)

				auth:clearSavedSession()
				local s, r = TestUtils.await("AuthenticateEmailPassword", function(ready)
					auth:authenticateEmailPassword(TEST_EMAIL, TEST_EMAIL_PASSWORD, true, ready)
				end)
				assert(s, "AuthenticateEmailPassword failed: " .. TestUtils.describe(r))
				assert(r.data.profileId, "Missing profileId")
				assert(r.data.sessionId, "Missing sessionId")
			end,
		},

		--- Mirrors C# TestResetEmailPassword
		{
			name = "ResetEmailPassword",
			fn = function()
				authAsResetEmail()
				local s, r = TestUtils.await("ResetEmailPassword", function(ready)
					auth:resetEmailPassword(RESET_EMAIL, ready)
				end)
				assert(s, "ResetEmailPassword failed: " .. TestUtils.describe(r))
			end,
		},

		--- Mirrors C# TestResetEmailPasswordWithExpiry
		{
			name = "ResetEmailPasswordWithExpiry",
			fn = function()
				authAsResetEmail()
				local s, r = TestUtils.await("ResetEmailPasswordWithExpiry", function(ready)
					auth:resetEmailPasswordWithExpiry(RESET_EMAIL, 1, ready)
				end)
				assert(s, "ResetEmailPasswordWithExpiry failed: " .. TestUtils.describe(r))
			end,
		},

		--- Mirrors C# TestResetEmailPasswordAdvanced (expects failure — invalid fromAddress)
		{
			name = "ResetEmailPasswordAdvanced",
			fn = function()
				local serviceParams = {
					fromAddress = "fromAddress",
					fromName = "fromName",
					replyToAddress = "replyToAddress",
					replyToName = "replyToName",
					templateId = "8f14c77d-61f4-4966-ab6d-0bee8b13d090",
					subject = "subject",
					body = "Body goes here",
					substitutions = { [":name"] = "John Doe", [":resetLink"] = "www.dummyLink.io" },
					categories = { "category1", "category2" },
				}
				authAsResetEmail()
				local s, r = TestUtils.await("ResetEmailPasswordAdvanced", function(ready)
					auth:resetEmailPasswordAdvanced(RESET_EMAIL, serviceParams, ready)
				end)
				--- C++ mirrors: runExpectFail(HTTP_BAD_REQUEST, INVALID_FROM_ADDRESS)
				assert(not s, "ResetEmailPasswordAdvanced should fail with invalid fromAddress")
			end,
		},

		--- Mirrors C# TestResetEmailPasswordAdvancedWithExpiry (expects failure)
		{
			name = "ResetEmailPasswordAdvancedWithExpiry",
			fn = function()
				local serviceParams = {
					fromAddress = "fromAddress",
					fromName = "fromName",
					replyToAddress = "replyToAddress",
					replyToName = "replyToName",
					templateId = "8f14c77d-61f4-4966-ab6d-0bee8b13d090",
					subject = "subject",
					body = "Body goes here",
					substitutions = { [":name"] = "John Doe", [":resetLink"] = "www.dummyLink.io" },
					categories = { "category1", "category2" },
				}
				authAsResetEmail()
				local s, r = TestUtils.await("ResetEmailPasswordAdvancedWithExpiry", function(ready)
					auth:resetEmailPasswordAdvancedWithExpiry(RESET_EMAIL, serviceParams, 1, ready)
				end)
				--- C++ mirrors: runExpectFail(HTTP_BAD_REQUEST, INVALID_FROM_ADDRESS)
				assert(not s, "ResetEmailPasswordAdvancedWithExpiry should fail with invalid fromAddress")
			end,
		},

		--- Mirrors C# TestResetUniversalIdPassword
		{
			name = "ResetUniversalIdPassword",
			fn = function()
				authAsUserA()
				local s, r = TestUtils.await("ResetUniversalIdPassword", function(ready)
					auth:resetUniversalIdPassword(TEST_UNIVERSAL_USERNAME, ready)
				end)
				assert(s, "ResetUniversalIdPassword failed: " .. TestUtils.describe(r))
			end,
		},

		--- Mirrors C# TestResetUniversalIdPasswordWithExpiry
		{
			name = "ResetUniversalIdPasswordWithExpiry",
			fn = function()
				authAsUserA()
				local s, r = TestUtils.await("ResetUniversalIdPasswordWithExpiry", function(ready)
					auth:resetUniversalIdPasswordWithExpiry(TEST_UNIVERSAL_USERNAME, 1, ready)
				end)
				assert(s, "ResetUniversalIdPasswordWithExpiry failed: " .. TestUtils.describe(r))
			end,
		},

		--- Mirrors C# TestResetUniversalIdPasswordAdvanced
		{
			name = "ResetUniversalIdPasswordAdvanced",
			fn = function()
				local serviceParams = {
					templateId = "8f14c77d-61f4-4966-ab6d-0bee8b13d090",
					substitutions = { [":name"] = "John Doe", [":resetLink"] = "www.dummyLink.io" },
					categories = { "category1", "category2" },
				}
				authAsUserA()
				local s, r = TestUtils.await("ResetUniversalIdPasswordAdvanced", function(ready)
					auth:resetUniversalIdPasswordAdvanced(TEST_UNIVERSAL_USERNAME, serviceParams, ready)
				end)
				assert(s, "ResetUniversalIdPasswordAdvanced failed: " .. TestUtils.describe(r))
			end,
		},

		--- Mirrors C# TestResetUniversalIdPasswordAdvancedWithExpiry
		{
			name = "ResetUniversalIdPasswordAdvancedWithExpiry",
			fn = function()
				local serviceParams = {
					templateId = "8f14c77d-61f4-4966-ab6d-0bee8b13d090",
					substitutions = { [":name"] = "John Doe", [":resetLink"] = "www.dummyLink.io" },
					categories = { "category1", "category2" },
				}
				authAsUserA()
				local s, r = TestUtils.await("ResetUniversalIdPasswordAdvancedWithExpiry", function(ready)
					auth:resetUniversalIdPasswordAdvancedWithExpiry(TEST_UNIVERSAL_USERNAME, serviceParams, 1, ready)
				end)
				assert(s, "ResetUniversalIdPasswordAdvancedWithExpiry failed: " .. TestUtils.describe(r))
			end,
		},

		--- Mirrors C# GetServerVersion
		{
			name = "GetServerVersion",
			fn = function()
				local s, r = TestUtils.await("GetServerVersion", function(ready)
					auth:getServerVersion(ready)
				end)
				TestUtils.assertOk("GetServerVersion", s, r)
				assert(r.data.serverVersion, "Missing serverVersion in response")
			end,
		},

		--- Mirrors C# TestAuthenticateAdvanced — re-auth with the previous credentials
		{
			name = "Retry Previous Authenticate",
			fn = function()
				local s, r = TestUtils.await("RetryPreviousAuthenticate", function(ready)
					auth:retryPreviousAuthenticate(ready)
				end)
				assert(s, "RetryPreviousAuthenticate failed: " .. TestUtils.describe(r))
				assert(r.data.profileId, "Missing profileId")
				assert(r.data.sessionId, "Missing sessionId")
			end,
		},

		--- Mirrors C# TestAuthenticateHandoff (requires cloud script "createHandoffId")
		{
			name = "AuthenticateHandoff",
			fn = function()
				local s1, r1 = TestUtils.await("AuthUniversalForHandoff", function(ready)
					auth:authenticateUniversal(TEST_UNIVERSAL_USERNAME, TEST_UNIVERSAL_PASSWORD, true, ready)
				end)
				assert(s1, "Auth for handoff failed: " .. TestUtils.describe(r1))

				local s2, r2 = TestUtils.await("RunHandoffScript", function(ready)
					client:sendRequest("script", "RUN", { scriptName = "createHandoffId", scriptData = {} }, ready)
				end)
				assert(s2, "createHandoffId script failed")

				local handoffId = r2.data and r2.data.response and r2.data.response.handoffId
				local handoffToken = r2.data and r2.data.response and r2.data.response.securityToken
				assert(handoffId and handoffToken, "Missing handoffId or securityToken from script response")

				local s3, r3 = TestUtils.await("AuthenticateHandoff", function(ready)
					auth:authenticateHandoff(handoffId, handoffToken, ready)
				end)
				assert(s3, "AuthenticateHandoff failed: " .. tostring(r3))
				assert(r3.data.profileId, "Missing profileId after handoff auth")
			end,
		},

		--- Mirrors C# TestAuthenticateSettopHandoff (requires cloud script "CreateSettopHandoffCode")
		{
			name = "AuthenticateSettopHandoff",
			fn = function()
				local s1, r1 = TestUtils.await("AuthUniversalForSettop", function(ready)
					auth:authenticateUniversal(TEST_UNIVERSAL_USERNAME, TEST_UNIVERSAL_PASSWORD, true, ready)
				end)
				assert(s1, "Auth for settop handoff failed: " .. TestUtils.describe(r1))

				local s2, r2 = TestUtils.await("RunSettopScript", function(ready)
					client:sendRequest("script", "RUN", { scriptName = "CreateSettopHandoffCode", scriptData = {} }, ready)
				end)
				assert(s2, "CreateSettopHandoffCode script failed")

				local handoffCode = r2.data and r2.data.response and r2.data.response.handoffCode
				assert(handoffCode, "Missing handoffCode from script response")

				local s3, r3 = TestUtils.await("AuthenticateSettopHandoff", function(ready)
					auth:authenticateSettopHandoff(handoffCode, ready)
				end)
				assert(s3, "AuthenticateSettopHandoff failed: " .. tostring(r3))
				assert(r3.data.profileId, "Missing profileId after settop handoff auth")
			end,
		},

		--- Mirrors JS authenticateEpicGames() with invalid token
		{
			name = "AuthenticateEpicGames Invalid Token",
			fn = function()
				local s, r = TestUtils.await("AuthenticateEpicGames", function(ready)
					auth:authenticateEpicGames("invalidEpicAccountId", "invalidAuthIdToken", true, ready)
				end)
				assert(not s, "AuthenticateEpicGames should fail with an invalid token")
				assert(r and r.status == 403, "Expected 403, got " .. tostring(r and r.status))
				assert(r.reason_code == client.reasonCodes.TOKEN_DOES_NOT_MATCH_USER,
					"Expected TOKEN_DOES_NOT_MATCH_USER, got " .. tostring(r.reason_code))
			end,
		},

		--- Platform auths without real tokens: the call must reach the server and be rejected
		{
			name = "Authenticate Oculus/PSN/Nintendo Invalid Token",
			fn = function()
				for _, method in ipairs({ "authenticateOculus", "authenticatePlaystationNetwork", "authenticateNintendo" }) do
					assert(auth[method], "Missing Authentication:" .. method)
					local s, r = TestUtils.await(method, function(ready)
						auth[method](auth, "invalidAccountId", "invalidToken", true, ready)
					end)
					assert(not s, method .. " should fail with an invalid token")
					assert(r and r.status and r.status ~= 200, method .. " did not get a server error response")
				end
			end,
		},

		{
			name = "Wrapper AuthenticateEpicGames Invalid Token",
			fn = function()
				local s, r = TestUtils.await("WrapperAuthenticateEpicGames", function(ready)
					wrapper:authenticateEpicGames("invalidEpicAccountId", "invalidAuthIdToken", true, ready)
				end)
				assert(not s, "Wrapper authenticateEpicGames should fail with an invalid token")
				assert(r and r.status == 403, "Expected 403, got " .. tostring(r and r.status))
			end,
		},

		{
			name = "Wrapper Anonymous Resumes Saved Profile",
			fn = function()
				wrapper:resetStoredProfileId()
				local s1, r1 = TestUtils.await("WrapperAnon1", function(ready)
					wrapper:authenticateAnonymous(ready)
				end)
				TestUtils.assertOk("WrapperAnon1", s1, r1)
				assert(wrapper:getStoredProfileId() == r1.data.profileId, "Stored profileId not saved")
				local s2, r2 = TestUtils.await("WrapperAnon2", function(ready)
					wrapper:authenticateAnonymous(ready)
				end)
				TestUtils.assertOk("WrapperAnon2", s2, r2)
				assert(r2.data.profileId == r1.data.profileId, "Anonymous login did not resume the saved profile")
				TestUtils.await("DeleteAnon", function(ready)
					client.playerState:deleteUser(ready)
				end)
				wrapper:resetStoredProfileId()
				wrapper:resetStoredAnonymousId()
				auth:clearSavedSession()
			end,
		},

		{
			name = "Wrapper SmartSwitchAuthenticateUniversal",
			fn = function()
				local s1, r1 = TestUtils.await("AuthUniversalForSmartSwitch", function(ready)
					auth:authenticateUniversal(TEST_UNIVERSAL_USERNAME, TEST_UNIVERSAL_PASSWORD, true, ready)
				end)
				assert(s1, "Auth before smart switch failed: " .. TestUtils.describe(r1))

				local s2, r2 = TestUtils.await("SmartSwitchAuthenticateUniversal", function(ready)
					wrapper:smartSwitchAuthenticateUniversal(TEST_UNIVERSAL_USERNAME, TEST_UNIVERSAL_PASSWORD, true, ready)
				end)
				assert(s2, "SmartSwitchAuthenticateUniversal failed: " .. tostring(r2 and r2.reason_code))
				assert(r2.data.profileId, "Missing profileId after smart switch")
			end,
		},

		--- TODO: auth facebook, apple, gamecenter, google, steam, twitter (platform-specific)
		{
			name = "Bad Signature Rejected",
			fn = function()
				local good = client._appProfiles[client.appId]
				client._appProfiles[client.appId] = require("braincloud.lib.profile").fromValue("not-the-value")
				auth:clearSavedSession()
				local s, r = TestUtils.await("BadSig", function(ready)
					auth:authenticateUniversal(TEST_UNIVERSAL_USERNAME, TEST_UNIVERSAL_PASSWORD, true, ready)
				end)
				client._appProfiles[client.appId] = good
				assert(not s, "Auth with a bad signature should fail")
				assert(r and r.status == 403, "Expected 403, got " .. TestUtils.describe(r))
			end,
		},
	}
end, { authPerTest = false })

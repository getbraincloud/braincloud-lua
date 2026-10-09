--- Test_Identity.lua
--- Server integration tests for BrainCloud Identity
--- Mirrors the intention and coverage of C# TestIdentity.cs

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Identity", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")
	local identity = client.identity
	assert(identity, "Identity module missing")
	local AuthType = client.authentication.AuthType

	local function generateUniversalId()
		return (TestUtils.uuid():gsub("-", ""))
	end
	local function generateEmailId()
		return generateUniversalId() .. "@bctestuser.com"
	end

	local testCases = {}

	--- Round trips that must succeed (same as C#)
	local roundTrips = {
		{ name = "Universal", attach = "attachUniversalIdentity", detach = "detachUniversalIdentity", newId = generateUniversalId },
		{ name = "Email", attach = "attachEmailIdentity", detach = "detachEmailIdentity", newId = generateEmailId },
	}
	for _, rt in ipairs(roundTrips) do
		table.insert(testCases, {
			name = rt.name .. " Attach/Detach",
			fn = function()
				-- fresh anonymous profile: UserA already has a Universal identity
				client.authentication:clearSavedSession()
				TestUtils.assertOk("AnonForAttach", TestUtils.await("AnonForAttach", function(cb)
					client.authentication:authenticateAnonymous(true, cb)
				end))
				local externalId = rt.newId()
				local s1, r1 = TestUtils.await(rt.name .. "Attach", function(cb)
					identity[rt.attach](identity, externalId, TestUtils.uuid(), cb)
				end)
				assert(s1, rt.name .. " Attach failed: " .. tostring(r1 and r1.reason_code))
				local s2, r2 = TestUtils.await(rt.name .. "Detach", function(cb)
					identity[rt.detach](identity, externalId, true, cb)
				end)
				assert(s2, rt.name .. " Detach failed: " .. tostring(r2 and r2.reason_code))
				TestUtils.await("DeleteAnon", function(cb)
					client.playerState:deleteUser(cb)
				end)
			end,
		})
	end

	table.insert(testCases, {
		name = "AttachAdvancedIdentity/DetachAdvancedIdentity",
		fn = function()
			local externalId = generateEmailId()
			local ids = { externalId = externalId, authenticationToken = TestUtils.uuid() }
			local s1, r1 = TestUtils.await("AttachAdvancedIdentity", function(cb)
				identity:attachAdvancedIdentity(AuthType.EMAIL, ids, nil, cb)
			end)
			assert(s1, "AttachAdvancedIdentity failed: " .. tostring(r1 and r1.reason_code))
			local s2, r2 = TestUtils.await("DetachAdvancedIdentity", function(cb)
				identity:detachAdvancedIdentity(AuthType.EMAIL, externalId, true, nil, cb)
			end)
			assert(s2, "DetachAdvancedIdentity failed: " .. tostring(r2 and r2.reason_code))
		end,
	})

	table.insert(testCases, {
		name = "AttachAdvancedIdentity Invalid AuthType",
		fn = function()
			local ids = { externalId = generateUniversalId(), authenticationToken = TestUtils.uuid() }
			local s, r = TestUtils.await("AttachAdvancedIdentityInvalid", function(cb)
				identity:attachAdvancedIdentity("UNKNOWN", ids, nil, cb)
			end)
			assert(not s, "Expected failure for invalid auth type")
			assert(r and r.status == 403, "Expected 403, got " .. tostring(r and r.status))
			assert(r.reason_code == client.reasonCodes.INVALID_AUTHENTICATION_TYPE,
				"Expected INVALID_AUTHENTICATION_TYPE, got " .. tostring(r.reason_code))
		end,
	})

	--- Third-party providers: no real platform tokens, so each call must reach the server and be rejected
	local providers = {
		{ name = "Facebook", attach = "attachFacebookIdentity", merge = "mergeFacebookIdentity", detach = "detachFacebookIdentity" },
		{ name = "FacebookLimited", attach = "attachFacebookLimitedIdentity", merge = "mergeFacebookLimitedIdentity", detach = "detachFacebookLimitedIdentity" },
		{ name = "Ultra", attach = "attachUltraIdentity", merge = "mergeUltraIdentity", detach = "detachUltraIdentity" },
		{ name = "Steam", attach = "attachSteamIdentity", merge = "mergeSteamIdentity", detach = "detachSteamIdentity" },
		{ name = "Google", attach = "attachGoogleIdentity", merge = "mergeGoogleIdentity", detach = "detachGoogleIdentity" },
		{ name = "GoogleOpenId", attach = "attachGoogleOpenIdIdentity", merge = "mergeGoogleOpenIdIdentity", detach = "detachGoogleOpenIdIdentity" },
		{ name = "Apple", attach = "attachAppleIdentity", merge = "mergeAppleIdentity", detach = "detachAppleIdentity" },
		{ name = "EpicGames", attach = "attachEpicGamesIdentity", merge = "mergeEpicGamesIdentity", detach = "detachEpicGamesIdentity" },
		{ name = "Oculus", attach = "attachOculusIdentity", merge = "mergeOculusIdentity", detach = "detachOculusIdentity" },
		{ name = "PlaystationNetwork", attach = "attachPlaystationNetworkIdentity", merge = "mergePlaystationNetworkIdentity", detach = "detachPlaystationNetworkIdentity" },
		{ name = "Nintendo", attach = "attachNintendoIdentity", merge = "mergeNintendoIdentity", detach = "detachNintendoIdentity" },
		{ name = "GameCenter", attach = "attachGameCenterIdentity", merge = "mergeGameCenterIdentity", detach = "detachGameCenterIdentity", noToken = true },
		{ name = "Twitter", attach = "attachTwitterIdentity", merge = "mergeTwitterIdentity", detach = "detachTwitterIdentity", secret = "invalidSecret" },
		{ name = "Parse", attach = "attachParseIdentity", merge = "mergeParseIdentity", detach = "detachParseIdentity" },
	}

	local function expectRejected(tag, s, r)
		assert(not s, tag .. " should be rejected with invalid credentials")
		assert(r and r.status and r.status ~= 200, tag .. " did not get a server error response")
	end

	for _, p in ipairs(providers) do
		local externalId = "invalid" .. p.name .. "Id"
		local token = "invalid" .. p.name .. "Token"

		local function withCreds(fn, cb)
			if p.noToken then
				fn(identity, externalId, cb)
			elseif p.secret then
				fn(identity, externalId, token, p.secret, cb)
			else
				fn(identity, externalId, token, cb)
			end
		end

		for _, op in ipairs({ "attach", "merge" }) do
			local fn = identity[p[op]]
			table.insert(testCases, {
				name = p.name .. " " .. op .. " Invalid Credentials",
				fn = function()
					assert(fn, "Missing Identity:" .. p[op])
					local s, r = TestUtils.await(p[op], function(cb)
						withCreds(fn, cb)
					end)
					expectRejected(p[op], s, r)
				end,
			})
		end

		local detachFn = identity[p.detach]
		table.insert(testCases, {
			name = p.name .. " detach Not Attached",
			fn = function()
				assert(detachFn, "Missing Identity:" .. p.detach)
				local s, r = TestUtils.await(p.detach, function(cb)
					detachFn(identity, externalId, true, cb)
				end)
				expectRejected(p.detach, s, r)
			end,
		})
	end

	--- Additional Identity Operations (C# TestIdentity flow: child app + peer app from the ids file)
	local user = TestUtils.users.A
	local childAppId = TestUtils.ids.childAppId
	local peerName = TestUtils.ids.peerName or "peerapp"
	local parentLevel = TestUtils.ids.parentLevelName or "Master"

	local function ok(tag, fn)
		return TestUtils.assertOk(tag, TestUtils.await(tag, fn))
	end

	local extraTests = {
		{
			name = "GetIdentities",
			fn = function()
				ok("GetIdentities", function(cb)
					identity:getIdentities(cb)
				end)
			end,
		},
		{
			name = "GetIdentityStatus",
			fn = function()
				ok("GetIdentityStatus", function(cb)
					identity:getIdentityStatus(AuthType.UNIVERSAL, nil, cb)
				end)
			end,
		},
		{
			name = "GetExpiredIdentities",
			fn = function()
				ok("GetExpiredIdentities", function(cb)
					identity:getExpiredIdentities(cb)
				end)
			end,
		},
		{
			name = "RefreshIdentity Invalid Token",
			fn = function()
				local s, r = TestUtils.await("RefreshIdentity", function(cb)
					identity:refreshIdentity(user.id, "notTheToken", AuthType.UNIVERSAL, cb)
				end)
				expectRejected("RefreshIdentity", s, r)
			end,
		},
		{
			name = "ChangeEmailIdentity Unknown Email",
			fn = function()
				local s, r = TestUtils.await("ChangeEmailIdentity", function(cb)
					identity:changeEmailIdentity(generateEmailId(), "pass", generateEmailId(), true, cb)
				end)
				expectRejected("ChangeEmailIdentity", s, r)
			end,
		},
		{
			name = "SwitchToChildAndParent",
			fn = function()
				local r = ok("SwitchToSingletonChildProfile", function(cb)
					identity:switchToSingletonChildProfile(childAppId, true, cb)
				end)
				assert(r.data.parentProfileId or r.data.profileId, "no child profile in response")
				ok("SwitchToParentProfile", function(cb)
					identity:switchToParentProfile(parentLevel, cb)
				end)
			end,
		},
		{
			name = "GetChildProfiles",
			fn = function()
				ok("GetChildProfiles", function(cb)
					identity:getChildProfiles(true, cb)
				end)
			end,
		},
		{
			name = "DetachAndAttachParent",
			fn = function()
				ok("SwitchToChild", function(cb)
					identity:switchToSingletonChildProfile(childAppId, true, cb)
				end)
				ok("DetachParent", function(cb)
					identity:detachParent(cb)
				end)
				ok("AttachParentWithIdentity", function(cb)
					identity:attachParentWithIdentity(user.id, user.password, AuthType.UNIVERSAL, nil, true, cb)
				end)
			end,
		},
		{
			name = "AttachAndDetachPeer",
			fn = function()
				ok("AttachPeerProfile", function(cb)
					identity:attachPeerProfile(peerName, user.id .. "_peer", user.password, AuthType.UNIVERSAL, nil, true, cb)
				end)
				ok("GetPeerProfiles", function(cb)
					identity:getPeerProfiles(cb)
				end)
				ok("DetachPeer", function(cb)
					identity:detachPeer(peerName, cb)
				end)
			end,
		},
		{
			name = "InitWithChildAppsConfig",
			fn = function()
				local ids = TestUtils.ids
				if not (childAppId and ids.childSecret) then
					TestUtils.skip("no childAppId/childSecret in the ids file")
				end
				-- shaped like a setup-tool config with one child app
				local md5 = require("braincloud.lib.md5")
				local function profileOf(value)
					return function(payload)
						return md5.sumhexa(payload .. value)
					end
				end
				local parentProfile = profileOf(ids.secret)
				package.loaded.braincloud_config_children = {
					appId = ids.appId,
					serverUrl = ids.serverUrl,
					appVersion = ids.version,
					appProfile = parentProfile,
					appProfiles = { [ids.appId] = parentProfile, [childAppId] = profileOf(ids.childSecret) },
					childAppIds = { childAppId },
				}
				local wrapper = TestUtils.wrapper
				local okRun, err = pcall(function()
					assert(wrapper:init("braincloud_config_children"), "init() failed")
					assert(client._appProfiles[childAppId], "child profile not loaded")
					local list = wrapper:getChildAppIdList()
					assert(#list == 1 and list[1] == childAppId, "getChildAppIdList: " .. table.concat(list, ","))
					list[1] = "changed"
					assert(wrapper:getChildAppIdList()[1] == childAppId, "getChildAppIdList returned its own table")
					TestUtils.authenticateAs(client, "A")
					ok("SwitchToSingletonChildProfile", function(cb)
						identity:switchToSingletonChildProfile(childAppId, true, cb)
					end)
				end)
				package.loaded.braincloud_config_children = nil
				wrapper:initializeWithApps(ids.appId, { [ids.appId] = ids.secret, [childAppId] = ids.childSecret }, ids.version, ids.serverUrl)
				assert(okRun, err)
				local manual = wrapper:getChildAppIdList()
				assert(#manual == 1 and manual[1] == childAppId, "manual initializeWithApps child list")
			end,
		},
	}
	--- Combine test cases
	for _, t in ipairs(extraTests) do
		table.insert(testCases, t)
	end
	return testCases
end)

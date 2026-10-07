--- Test_PushNotification.lua
--- Server integration smoke tests for PushNotification service
local TestUtils = require("tests.shared")


return TestUtils.buildRunner("PushNotification", nil, function(client)
	local pn = client.pushNotification
	local group = client.group
	local groupId = nil
	assert(pn, "PushNotification module missing")

	local tests = {
		{
			name = "DeregisterAll",
			fn = function()
				local s, res = TestUtils.await("DeregisterAll", function(cb)
					pn:deregisterAllPushNotificationDeviceTokens(cb)
				end)
				assert(res ~= nil, "DeregisterAll did not return a response")
			end,
		},

		{
			name = "SendSimple",
			fn = function()
				local s, res = TestUtils.await("SendSimple", function(cb)
					pn:sendSimplePushNotification(client.profileId or "", "hello", cb)
				end)
				assert(res ~= nil, "SendSimple did not return a response")
			end,
		},

		{
			name = "SendRaw",
			fn = function()
				local s, res = TestUtils.await("SendRaw", function(cb)
					pn:sendRawPushNotification(client.profileId or "", {
						notification = {
							body = "content of message",
							title = "message title",
						},
						data = {
							customfield1 = "customValue1",
							customfield2 = "customValue2",
						},
						priority = "normal",
					}, {
						aps = {
							alert = {
								body = "content of message",
								title = "message title",
							},
							badge = 0,
							sound = "gggg",
						},
					}, { template = "content of message" }, cb)
				end)
				assert(res ~= nil, "SendRaw did not return a response")
			end,
		},

		{
			name = "RegisterDevice",
			fn = function()
				local s, res = TestUtils.await("RegisterDevice", function(cb)
					pn:registerPushNotificationDeviceToken("IOS", "unittest-token-123", cb)
				end)
				assert(res ~= nil, "RegisterDevice did not return a response")
			end,
		},

		{
			name = "DeregisterDevice",
			fn = function()
				local s, res = TestUtils.await("DeregisterDevice", function(cb)
					pn:deregisterPushNotificationDeviceToken("IOS", "unittest-token-123", cb)
				end)
				assert(res ~= nil, "DeregisterDevice did not return a response")
			end,
		},

		{
			name = "SendRich",
			fn = function()
				local s, res = TestUtils.await("SendRich", function(cb)
					pn:sendRichPushNotification(client.profileId or "", 2, cb)
				end)
				assert(res ~= nil, "SendRich did not return a response")
			end,
		},

		{
			name = "SendRichWithParams",
			fn = function()
				local s, res = TestUtils.await("SendRichWithParams", function(cb)
					pn:sendRichPushNotificationWithParams(client.profileId or "", 2, { [0] = "unit" }, cb)
				end)
				assert(res ~= nil, "SendRichWithParams did not return a response")
			end,
		},

		{
			name = "SendTemplatedToGroup",
			fn = function()
				local s, res = TestUtils.await("CreateGroup", function(cb)
					--- name, groupType, acl, data, isOpenGroup, callback
					group:createGroup("TestGroupName", "test", false, { member = 2, other = 1 }, { score = 100 }, nil, nil, cb)
				end)
				assert(s, "CreateGroup failed")
				assert(res.data and res.data.groupId, "CreateGroup missing res.data.groupId")
				groupId = res.data.groupId

				local s, res = TestUtils.await("SendTemplatedToGroup", function(cb)
					pn:sendTemplatedPushNotificationToGroup(groupId, 2, nil, cb)
				end)
				assert(res ~= nil, "SendTemplatedToGroup did not return a response")
			end,
		},

		{
			name = "SendNormalized",
			fn = function()
				local s, res = TestUtils.await("SendNormalized", function(cb)
					pn:sendNormalizedPushNotification(
						client.profileId or "",
						{ alert = { body = "hi" } },
						{ custom = 1 },
						cb
					)
				end)
				assert(res ~= nil, "SendNormalized did not return a response")
			end,
		},

		{
			name = "SendRawBatch",
			fn = function()
				local s, res = TestUtils.await("SendRawBatch", function(cb)
					pn:sendRawPushNotificationBatch({ client.profileId or "" }, {
						notification = {
							body = "content of message",
							title = "message title",
						},
						data = {
							customfield1 = "customValue1",
							customfield2 = "customValue2",
						},
						priority = "normal",
					}, {
						aps = {
							alert = {
								body = "content of message",
								title = "message title",
							},
							badge = 0,
							sound = "gggg",
						},
					}, { template = "content of message" }, cb)
				end)
				assert(res ~= nil, "SendRawBatch did not return a response")
			end,
		},

		{
			name = "SendRawToGroup",
			fn = function()
				local s, res = TestUtils.await("SendRawToGroup", function(cb)
					pn:sendRawPushNotificationToGroup(groupId, {
						notification = {
							body = "content of message",
							title = "message title",
						},
						data = {
							customfield1 = "customValue1",
							customfield2 = "customValue2",
						},
						priority = "normal",
					}, {
						aps = {
							alert = {
								body = "content of message",
								title = "message title",
							},
							badge = 0,
							sound = "gggg",
						},
					}, { template = "content of message" }, cb)
				end)
				assert(res ~= nil, "SendRawToGroup did not return a response")

				local s, res = TestUtils.await("DeleteGroup", function(cb)
					group:deleteGroup(groupId, -1, cb)
				end)
			end,
		},

		{
			name = "ScheduleNormalizedMinutes",
			fn = function()
				local s, res = TestUtils.await("ScheduleNormalizedMinutes", function(cb)
					pn:scheduleNormalizedPushNotificationMinutes(
						client.profileId or "",
						{ alert = { body = "hi" } },
						nil,
						1,
						cb
					)
				end)
				assert(res ~= nil, "ScheduleNormalizedMinutes did not return a response")
			end,
		},
	}

	return tests
end)

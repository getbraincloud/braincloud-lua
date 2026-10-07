--- Test_Messaging.lua
--- Server integration tests for Messaging service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Messaging", nil, function(client)
	local messaging = client.messaging
	assert(messaging, "Messaging module missing")

	local exampleText = "Test message from integration test"
	local exampleContent = { subject = "Test", text = "Hello from test" }

	local tests = {
		{
			name = "GetMessageBoxes",
			fn = function()
				local s, res = TestUtils.await("GetMessageBoxes", function(cb)
					messaging:getMessageboxes(cb)
				end)
				assert(res ~= nil, "GetMessageBoxes did not return a response")
			end,
		},

		{
			name = "GetMessageCounts",
			fn = function()
				local s, res = TestUtils.await("GetMessageCounts", function(cb)
					messaging:getMessageCounts(cb)
				end)
				assert(res ~= nil, "GetMessageCounts did not return a response")
			end,
		},

		{
			name = "SendMessageSimple",
			fn = function()
				local target = { client.profileId } --- send to self
				local s, res = TestUtils.await("SendMessageSimple", function(cb)
					messaging:sendMessageSimple(target, exampleText, cb)
				end)
				assert(res ~= nil, "SendMessageSimple did not return a response")
			end,
		},

		{
			name = "SendMessage",
			fn = function()
				local target = { client.profileId }
				local s, res = TestUtils.await("SendMessage", function(cb)
					messaging:sendMessage(target, exampleContent, cb)
				end)
				assert(res ~= nil, "SendMessage did not return a response")
			end,
		},

		{
			name = "GetMessages",
			fn = function()
				--- attempt to read messages in inbox (may return empty)
				local s, res = TestUtils.await("GetMessages", function(cb)
					messaging:getMessages("inbox", {}, false, cb)
				end)
				assert(res ~= nil, "GetMessages did not return a response")
			end,
		},

		{
			name = "GetMessagesPage",
			fn = function()
				local s, res = TestUtils.await("GetMessagesPage", function(cb)
					messaging:getMessagesPage({
						pagination = {
							rowsPerPage = 10,
							pageNumber = 1,
						},
						searchCriteria = {
							msgbox = "inbox",
							read = false,
						},
						sortCriteria = {
							mbCr = 1,
							mbUp = -1,
						},
					}, cb)
				end)
				assert(res ~= nil, "GetMessagesPage did not return a response")
			end,
		},

		{
			name = "MarkMessagesRead",
			fn = function()
				--- best-effort: mark no messages (empty set) - primarily validating the call succeeds
				local s, res = TestUtils.await("MarkMessagesRead", function(cb)
					messaging:markMessagesRead("inbox", {}, cb)
				end)
				assert(res ~= nil, "MarkMessagesRead did not return a response")
			end,
		},

		{
			name = "DeleteMessages",
			fn = function()
				local s, res = TestUtils.await("DeleteMessages", function(cb)
					messaging:deleteMessages("inbox", {}, cb)
				end)
				assert(res ~= nil, "DeleteMessages did not return a response")
			end,
		},
	}

	return tests
end)

--- Test_Chat.lua
--- Server integration tests for Chat
local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Chat", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")
	local chat = client.chat
	assert(chat, "Chat module missing")

	local testChannelId = nil
	local postedMsgId = nil
	local postedVersion = nil

	local tests = {

		--- 1. GetChannelId (global channel "valid", same as C#)
		{
			name = "GetChannelId",
			fn = function()
				local s, res = TestUtils.await("GetChannelId", function(r)
					chat:getChannelId("gl", "valid", r)
				end)

				assert(s, "GetChannelId failed")
				assert(res.data.channelId, "Missing returned channelId")
				testChannelId = res.data.channelId
			end,
		},

		--- 2. ChannelConnect
		{
			name = "ChannelConnect",
			fn = function()
				assert(testChannelId, "No channelId from GetChannelId")

				local s, res = TestUtils.await("ChannelConnect", function(r)
					chat:channelConnect(testChannelId, 10, r)
				end)

				assert(s, "ChannelConnect failed")
				assert(res.data.messages, "Expected messages array in connect response")
			end,
		},

		--- 3. PostChatMessage
		{
			name = "PostChatMessage",
			fn = function()
				local s, res = TestUtils.await("PostChatMessage", function(r)
					chat:postChatMessage(testChannelId, { text = "Hello from Lua test!" }, true, r)
				end)

				assert(s, "PostChatMessage failed")
				assert(res.data.msgId, "Missing msgId")

				postedMsgId = res.data.msgId
				postedVersion = 0
			end,
		},

		--- 3b. PostChatMessageSimple
		{
			name = "PostChatMessageSimple",
			fn = function()
				local s, res = TestUtils.await("PostChatMessageSimple", function(r)
					chat:postChatMessageSimple(testChannelId, "Simple text message!", true, r)
				end)

				assert(s, "PostChatMessageSimple failed")
				assert(res.data.msgId, "Missing msgId from simple post")
			end,
		},

		--- 3c. GetSubscribedChannels
		{
			name = "GetSubscribedChannels",
			fn = function()
				local s, res = TestUtils.await("GetSubscribedChannels", function(r)
					chat:getSubscribedChannels("all", r)
				end)

				assert(s, "GetSubscribedChannels failed")
				assert(res.data.channels, "Expected channels list")
				assert(type(res.data.channels) == "table", "channels should be an array/table")
			end,
		},

		--- 4. GetChatMessage
		{
			name = "GetChatMessage",
			fn = function()
				assert(postedMsgId, "No posted message ID")

				local s, res = TestUtils.await("GetChatMessage", function(r)
					chat:getChatMessage(testChannelId, postedMsgId, r)
				end)

				assert(s, "GetChatMessage failed")
				assert(res.data.content.text, "Missing message")
				postedVersion = res.data.ver
			end,
		},

		--- 5. GetRecentChatMessages
		{
			name = "GetRecentChatMessages",
			fn = function()
				local s, res = TestUtils.await("GetRecentChatMessages", function(r)
					chat:getRecentChatMessages(testChannelId, 10, r)
				end)

				assert(s, "GetRecentChatMessages failed")
				assert(res.data.messages, "Missing messages list")
			end,
		},

		--- 6. UpdateChatMessage
		{
			name = "UpdateChatMessage",
			fn = function()
				assert(postedMsgId, "No posted message ID")
				assert(postedVersion, "Missing version")

				local s, res = TestUtils.await("UpdateChatMessage", function(r)
					chat:updateChatMessage(
						testChannelId,
						postedMsgId,
						postedVersion,
						{ text = "Updated message text!" },
						r
					)
				end)

				assert(s, "UpdateChatMessage failed")

				postedVersion = postedVersion + 1
			end,
		},

		--- 7. DeleteChatMessage
		{
			name = "DeleteChatMessage",
			fn = function()
				assert(postedMsgId, "No posted message ID")

				local s = TestUtils.await("DeleteChatMessage", function(r)
					chat:deleteChatMessage(testChannelId, postedMsgId, postedVersion, r)
				end)

				assert(s, "DeleteChatMessage failed")
			end,
		},

		--- 8. ChannelDisconnect
		{
			name = "ChannelDisconnect",
			fn = function()
				local s = TestUtils.await("ChannelDisconnect", function(r)
					chat:channelDisconnect(testChannelId, r)
				end)

				assert(s, "ChannelDisconnect failed")
			end,
		},
	}
	return tests
end)

--- Test_Profanity.lua
--- Server integration smoke tests for Profanity service
local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Profanity", nil, function(client)
	local profanity = client.profanity
	assert(profanity, "Profanity module missing")

	local tests = {
		{
			name = "ProfanityCheck",
			fn = function()
				local s, res = TestUtils.await("ProfanityCheck", function(cb)
					profanity:profanityCheck("hello", "en", true, true, true, cb)
				end)
				assert(res ~= nil, "ProfanityCheck did not return a response")
				assert(res.data.foundCount, "Missing foundCount")
			end,
		},

		{
			name = "ProfanityReplaceText",
			fn = function()
				local s, res = TestUtils.await("ProfanityReplaceText", function(cb)
					profanity:profanityReplaceText(
						"bad stuff fuck shit cock penis ass",
						"*",
						nil,
						false,
						false,
						false,
						cb
					)
				end)
				assert(res ~= nil, "ProfanityReplaceText did not return a response")
				assert(res.data.foundCount, "Missing foundCount")
			end,
		},

		{
			name = "ProfanityIdentifyBadWords",
			fn = function()
				local s, res = TestUtils.await("ProfanityIdentifyBadWords", function(cb)
					profanity:profanityIdentifyBadWords(
						"some text fuck shit cock penis ass",
						nil,
						false,
						false,
						false,
						cb
					)
				end)
				assert(res ~= nil, "ProfanityIdentifyBadWords did not return a response")
				assert(res.data.foundCount, "Missing foundCount")
			end,
		},
	}

	return tests
end)

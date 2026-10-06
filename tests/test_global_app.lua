--- Test_BCGlobalApp.lua
--- Server integration tests for BCGlobalApp service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("GlobalApp", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")
	local globalApp = client.globalApp
	assert(globalApp, "BCGlobalApp module missing")

	local tests = {

		--- 1. ReadProperties
		{
			name = "ReadProperties",
			fn = function()
				local s, res = TestUtils.await("ReadProperties", function(r)
					globalApp:readProperties(r)
				end)
				assert(s, "ReadProperties failed")
				assert(type(res.data) == "table", "Expected data table")
			end,
		},

		--- 2. ReadSelectedProperties
		{
			name = "ReadSelectedProperties",
			fn = function()
				local s, res = TestUtils.await("ReadSelectedProperties", function(r)
					globalApp:readSelectedProperties({ "testProperty1", "testProperty2" }, r)
				end)
				assert(s, "ReadSelectedProperties failed")

				assert(type(res.data) == "table", "Expected data table")
			end,
		},

		--- 3. ReadPropertiesInCategories
		{
			name = "ReadPropertiesInCategories",
			fn = function()
				local s, res = TestUtils.await("ReadPropertiesInCategories", function(r)
					globalApp:readPropertiesInCategories({ "CategoryA", "CategoryB" }, r)
				end)
				assert(s, "ReadPropertiesInCategories failed")

				assert(type(res.data) == "table", "Expected data table")
			end,
		},
	}

	return tests
end)

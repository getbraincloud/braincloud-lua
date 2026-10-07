--- Test_UserItems.lua
--- Server integration smoke tests for UserItems service
local TestUtils = require("tests.shared")


return TestUtils.buildRunner("UserItems", nil, function(client)
	local ui = client.userItems
	assert(ui, "UserItems module missing")

	--- example placeholders; replace with real ids in your environment for meaningful tests

	local exampleItem = "sword001"
	local exampleBundleItem = "equipmentBundle"
	local exampleContext = { pageOffset = 0, pageSize = 10 }
	local exampleProfile = TestUtils.TEST_USER_OPP_PROFILE_ID
	local exampleVersion = 1
	local exampleShop = "shop"
	local localItemId = ""

	local tests = {
		{
			--- not recommended from the client,
			--- for sanity of the test suite this is being called
			name = "AwardUserItem",
			fn = function()
				local s, res = TestUtils.await("AwardUserItem", function(cb)
					ui:awardUserItem(exampleItem, 1, true, cb)
				end)
				assert(res ~= nil, "AwardUserItem did not return a response")

				for itemId, defID in pairs(res.data.items) do
					localItemId = itemId
					break --- just take the first one
				end

				assert(localItemId, "No items in dictionary")
			end,
		},

		{
			name = "GetUserItem",
			fn = function()
				local s, res = TestUtils.await("GetUserItem", function(cb)
					ui:getUserItem(localItemId, true, cb)
				end)
				assert(res ~= nil, "GetUserItem did not return a response")
			end,
		},

		{
			name = "GetUserItemsPage",
			fn = function()
				local s, res = TestUtils.await("GetUserItemsPage", function(cb)
					ui:getUserItemsPage({ pageOffset = 0, pageSize = 10 }, true, cb)
				end)
				assert(res ~= nil, "GetUserItemsPage did not return a response")
				exampleContext = res.data.context
			end,
		},

		{
			name = "GetUserItemsPageOffset",
			fn = function()
				local s, res = TestUtils.await("GetUserItemsPageOffset", function(cb)
					ui:getUserItemsPageOffset(exampleContext, 0, true, cb)
				end)
				assert(res ~= nil, "GetUserItemsPageOffset did not return a response")
			end,
		},

		{
			name = "GiveUserItemTo",
			fn = function()
				local s, res = TestUtils.await("GiveUserItemTo", function(cb)
					ui:giveUserItemTo(exampleProfile, localItemId, exampleVersion, 1, true, cb)
				end)
				assert(res ~= nil, "GiveUserItemTo did not return a response")
				assert(res.data.item, "GiveUserItemTo did not return a item")
			end,
		},

		{
			--- not recommended from the client,
			--- for sanity of the test suite this is being called
			name = "AwardUserItemWithOptions",
			fn = function()
				local s, res = TestUtils.await("AwardUserItemWithOptions", function(cb)
					ui:awardUserItemWithOptions(exampleItem, 1, true, {}, cb)
				end)
				assert(res ~= nil, "AwardUserItem did not return a response")

				for itemId in pairs(res.data.items) do
					localItemId = itemId
					exampleVersion = res.data.items[itemId].version
					break --- just take the first one
				end

				assert(localItemId, "No items in dictionary")
			end,
		},

		{
			name = "SellUserItem",
			fn = function()
				local s, res = TestUtils.await("SellUserItem", function(cb)
					ui:sellUserItem(localItemId, exampleVersion, 1, exampleShop, true, cb)
				end)
				assert(res ~= nil, "SellUserItem did not return a response")
			end,
		},

		{
			name = "PurchaseUserItem",
			fn = function()
				local s, res = TestUtils.await("PurchaseUserItem", function(cb)
					ui:purchaseUserItem(exampleItem, 1, exampleShop, true, cb)
				end)
				assert(res ~= nil, "PurchaseUserItem did not return a response")
			end,
		},
		{
			name = "PurchaseUserItemWithOptions",
			fn = function()
				local s, res = TestUtils.await("PurchaseUserItemWithOptions", function(cb)
					ui:purchaseUserItemWithOptions(exampleItem, 1, exampleShop, true, {}, cb)
				end)
				assert(res ~= nil, "PurchaseUserItem did not return a response")
			end,
		},
		{
			name = "ReceiveUserItemFrom",
			fn = function()
				local s, res = TestUtils.await("ReceiveUserItemFrom", function(cb)
					ui:receiveUserItemFrom(exampleProfile, localItemId, cb)
				end)
				assert(res ~= nil, "ReceiveUserItemFrom did not return a response")
			end,
		},

		{
			--- not recommended from the client,
			--- for sanity of the test suite this is being called
			name = "AwardUserItem3",
			fn = function()
				local s, res = TestUtils.await("AwardUserItem3", function(cb)
					ui:awardUserItem(exampleItem, 1, true, cb)
				end)
				assert(res ~= nil, "AwardUserItem did not return a response")

				for itemId in pairs(res.data.items) do
					localItemId = itemId
					exampleVersion = res.data.items[itemId].version
					break --- just take the first one
				end

				assert(localItemId, "No items in dictionary")
			end,
		},
		{
			name = "UpdateUserItemData",
			fn = function()
				local s, res = TestUtils.await("UpdateUserItemData", function(cb)
					ui:updateUserItemData(localItemId, exampleVersion, { foo = "bar" }, cb)
				end)
				assert(res ~= nil, "UpdateUserItemData did not return a response")
				assert(res.data.item.version, "Missing version")
				exampleVersion = res.data.item.version
			end,
		},

		{
			name = "UseUserItem",
			fn = function()
				local s, res = TestUtils.await("UseUserItem", function(cb)
					ui:useUserItem(localItemId, exampleVersion, { used = true }, true, cb)
				end)
				assert(res ~= nil, "UseUserItem did not return a response")
			end,
		},

		{
			name = "DropUserItem",
			fn = function()
				local s, res = TestUtils.await("DropUserItem", function(cb)
					ui:dropUserItem(localItemId, 1, true, cb)
				end)
				assert(res ~= nil, "DropUserItem did not return a response")
			end,
		},

		{
			name = "PublishUserItemToBlockchain",
			fn = function()
				local s, res = TestUtils.await("PublishUserItemToBlockchain", function(cb)
					ui:publishUserItemToBlockchain(exampleItem, exampleVersion, cb)
				end)
				assert(res ~= nil, "PublishUserItemToBlockchain did not return a response")
			end,
		},

		{
			name = "RefreshBlockchainUserItems",
			fn = function()
				local s, res = TestUtils.await("RefreshBlockchainUserItems", function(cb)
					ui:refreshBlockchainUserItems(cb)
				end)
				assert(res ~= nil, "RefreshBlockchainUserItems did not return a response")
			end,
		},

		{
			name = "RemoveUserItemFromBlockchain",
			fn = function()
				local s, res = TestUtils.await("RemoveUserItemFromBlockchain", function(cb)
					ui:removeUserItemFromBlockchain(exampleItem, exampleVersion, cb)
				end)
				assert(res ~= nil, "RemoveUserItemFromBlockchain did not return a response")
			end,
		},

		{
			--- not recommended from the client,
			--- for sanity of the test suite this is being called
			name = "AwardUserBundleItem",
			fn = function()
				local s, res = TestUtils.await("AwardUserBundleItem", function(cb)
					ui:awardUserItem(exampleBundleItem, 1, true, cb)
				end)
				assert(res ~= nil, "AwardUserBundleItem did not return a response")

				for itemId, defID in pairs(res.data.items) do
					localItemId = itemId
					break --- just take the first one
				end

				assert(localItemId, "No items in dictionary")
			end,
		},

		{
			name = "OpenBundle",
			fn = function()
				local s, res = TestUtils.await("OpenBundle", function(cb)
					ui:openBundle(localItemId, 1, 1, false, {}, cb)
				end)
				assert(res ~= nil, "OpenBundle did not return a response")
			end,
		},
	}

	return tests
end)

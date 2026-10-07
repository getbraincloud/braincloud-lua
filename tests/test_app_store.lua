--- Test_AppStore.lua
--- Server integration tests for AppStore service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("AppStore", nil, function(client)
	local appStore = client.appStore
	assert(appStore, "AppStore module missing")

	--- example placeholders; replace with valid store id / iap ids for meaningful tests
	local exampleStoreId = "googlePlay"
	local exampleIapId = "example.iap"
	local exampleReceipt = { receipt = "example" }

	return {
		{
			name = "CachePurchasePayloadContext",
			fn = function()
				local s, res = TestUtils.await("CachePurchasePayloadContext", function(cb)
					appStore:cachePurchasePayloadContext(exampleStoreId, exampleIapId, "payload123", cb)
				end)
				assert(res ~= nil, "CachePurchasePayloadContext did not return a response")
			end,
		},

		{
			name = "VerifyPurchase",
			fn = function()
				local s, res = TestUtils.await("VerifyPurchase", function(cb)
					appStore:verifyPurchase(exampleStoreId, exampleReceipt, cb)
				end)
				assert(res ~= nil, "VerifyPurchase did not return a response")
			end,
		},

		{
			name = "GetEligiblePromotions",
			fn = function()
				local s, res = TestUtils.await("GetEligiblePromotions", function(cb)
					appStore:getEligiblePromotions(cb)
				end)
				assert(res ~= nil, "GetEligiblePromotions did not return a response")
			end,
		},

		{
			name = "GetSalesInventory",
			fn = function()
				local s, res = TestUtils.await("GetSalesInventory", function(cb)
					appStore:getSalesInventory(exampleStoreId, "USD", cb)
				end)
				assert(res ~= nil, "GetSalesInventory did not return a response")
			end,
		},

		{
			name = "GetSalesInventoryByCategory",
			fn = function()
				local s, res = TestUtils.await("GetSalesInventoryByCategory", function(cb)
					appStore:getSalesInventoryByCategory(exampleStoreId, "USD", "default", cb)
				end)
				assert(res ~= nil, "GetSalesInventoryByCategory did not return a response")
			end,
		},

		{
			name = "StartPurchase",
			fn = function()
				local s, res = TestUtils.await("StartPurchase", function(cb)
					appStore:startPurchase(exampleStoreId, { productId = exampleIapId }, cb)
				end)
				assert(res ~= nil, "StartPurchase did not return a response")
			end,
		},

		{
			name = "FinalizePurchase",
			fn = function()
				local s, res = TestUtils.await("FinalizePurchase", function(cb)
					appStore:finalizePurchase(exampleStoreId, "example-transaction", { receipt = exampleReceipt }, cb)
				end)
				assert(res ~= nil, "FinalizePurchase did not return a response")
			end,
		},

		{
			name = "RefreshPromotions",
			fn = function()
				local s, res = TestUtils.await("RefreshPromotions", function(cb)
					appStore:refreshPromotions(cb)
				end)
				assert(res ~= nil, "RefreshPromotions did not return a response")
			end,
		},
	}
end)

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local AppStore = {}
AppStore.__index = AppStore

local SERVICE = "appStore"

local OPS = {
	CACHE_PURCHASE_PAYLOAD_CONTEXT = "CACHE_PURCHASE_PAYLOAD_CONTEXT",
	FINALIZE_PURCHASE = "FINALIZE_PURCHASE",
	ELIGIBLE_PROMOTIONS = "ELIGIBLE_PROMOTIONS",
	GET_INVENTORY = "GET_INVENTORY",
	REFRESH_PROMOTIONS = "REFRESH_PROMOTIONS",
	START_PURCHASE = "START_PURCHASE",
	VERIFY_PURCHASE = "VERIFY_PURCHASE",
}

--- Create a new AppStore service instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return AppStore
function AppStore.new(brainCloudClient)
	local self = setmetatable({}, AppStore)
	self.client = brainCloudClient
	return self
end

--- Before making a purchase with the IAP store, you will need to store the purchase
-- payload context on brainCloud so that the purchase can be verified for the proper IAP product.
-- This payload will be used during the VerifyPurchase method to ensure the
-- user properly paid for the correct product before awarding them the IAP product.
-- Service Name - appStore
-- Service Operation - CACHE_PURCHASE_PAYLOAD_CONTEXT
-- 
-- @param storeId The store platform. Valid stores are:
--        itunes
--        facebook
--        appworld
--        steam
--        windows
--        windowsPhone
--        googlePlay
--        metaHorizon
--        epicGames
--        xsolla
-- @param transactionId the transactionId returned from start Purchase
-- @param transactionData specific data for purchasing 2 staged purchases
-- @param callback The method to be invoked when the server response is received
-- 
function AppStore:cachePurchasePayloadContext(storeId, iapId, payload, callback)
	local data = {
		storeId = storeId,
		iapId = iapId,
		payload = payload,
	}
	self.client:sendRequest(SERVICE, OPS.CACHE_PURCHASE_PAYLOAD_CONTEXT, data, callback)
end

--- Verifies that purchase was properly made at the store.
-- Service Name - appStore
-- Service Operation - VERIFY_PURCHASE
-- 
-- @param storeId The store platform. Valid stores are:
--        itunes
--        facebook
--        appworld
--        steam
--        windows
--        windowsPhone
--        googlePlay
--        metaHorizon
--        epicGames
--        xsolla
-- @param receiptData the specific store data required
-- @param callback The method to be invoked when the server response is received
-- 
function AppStore:verifyPurchase(storeId, receiptData, callback)
	local message = { storeId = storeId, receiptData = receiptData }
	self.client:sendRequest(SERVICE, OPS.VERIFY_PURCHASE, message, callback)
end

--- Returns the eligible promotions for the player.
-- Service Name - appStore
-- Service Operation - ELIGIBLE_PROMOTIONS
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function AppStore:getEligiblePromotions(callback)
	local message = {}
	self.client:sendRequest(SERVICE, OPS.ELIGIBLE_PROMOTIONS, message, callback)
end

--- Method gets the active sales inventory for the passed-in
-- currency type.
-- Service Name - appStore
-- Service Operation - GET_INVENTORY
-- 
-- @param platform The store platform. Valid stores are:
--        itunes
--        facebook
--        appworld
--        steam
--        windows
--        windowsPhone
--        googlePlay
--        metaHorizon
--        epicGames
--        xsolla
-- @param userCurrency The currency type to retrieve the sales inventory for.
-- @param callback The method to be invoked when the server response is received
-- 
function AppStore:getSalesInventory(storeId, userCurrency, callback)
	self:getSalesInventoryByCategory(storeId, userCurrency, nil, callback)
end

--- Method gets the active sales inventory for the passed-in
-- currency type.
-- Service Name - appStore
-- Service Operation - GET_INVENTORY
-- 
-- @param storeId The store platform. Valid stores are:
--        itunes
--        facebook
--        appworld
--        steam
--        windows
--        windowsPhone
--        googlePlay
--        metaHorizon
--        epicGames
--        xsolla
-- @param userCurrency The currency type to retrieve the sales inventory for.
-- @param category The product category
-- @param callback The method to be invoked when the server response is received
-- 
function AppStore:getSalesInventoryByCategory(storeId, userCurrency, category, callback)
	local message = {
		storeId = storeId,
		category = category,
		priceInfoCriteria = { userCurrency = userCurrency },
	}
	self.client:sendRequest(SERVICE, OPS.GET_INVENTORY, message, callback)
end

--- Start A Two Staged Purchase Transaction
-- Service Name - appStore
-- Service Operation - START_PURCHASE
-- 
-- @param storeId The store id. Currently only accepts "steam".
-- @param purchaseData specific data for purchasing 2 staged purchases
-- @param callback The method to be invoked when the server response is received
-- 
function AppStore:startPurchase(storeId, purchaseData, callback)
	local message = { storeId = storeId, purchaseData = purchaseData }
	self.client:sendRequest(SERVICE, OPS.START_PURCHASE, message, callback)
end

--- Finalize A Two Staged Purchase Transaction
-- Service Name - appStore
-- Service Operation - FINALIZE_PURCHASE
-- 
-- @param storeId The store id. Currently only accepts "steam".
-- @param transactionId the transactionId returned from start Purchase
-- @param transactionData specific data for purchasing 2 staged purchases
-- @param callback The method to be invoked when the server response is received
--
function AppStore:finalizePurchase(storeId, transactionId, transactionData, callback)
	local message = { storeId = storeId, transactionId = transactionId, transactionData = transactionData }
	self.client:sendRequest(SERVICE, OPS.FINALIZE_PURCHASE, message, callback)
end

--- Returns up-to-date eligible 'promotions' for the user and a 'promotionsRefreshed' flag indicating whether the user's promotion info required refreshing.
-- Service Name - appStore
-- Service Operation - REFRESH_PROMOTIONS
-- 
-- 
function AppStore:refreshPromotions(callback)
	local message = {}
	self.client:sendRequest(SERVICE, OPS.REFRESH_PROMOTIONS, message, callback)
end

return AppStore

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")

local UserItems = {}
UserItems.__index = UserItems

local SERVICE = "userItems"

local OPS = {
	AWARD_USER_ITEM = "AWARD_USER_ITEM",
	DROP_USER_ITEM = "DROP_USER_ITEM",
	GET_USER_ITEMS_PAGE = "GET_USER_ITEMS_PAGE",
	GET_USER_ITEMS_PAGE_OFFSET = "GET_USER_ITEMS_PAGE_OFFSET",
	GET_USER_ITEM = "GET_USER_ITEM",
	GET_ITEM_PROMOTION_DETAILS = "GET_ITEM_PROMOTION_DETAILS",
	GET_ITEMS_ON_PROMOTION = "GET_ITEMS_ON_PROMOTION",
	GIVE_USER_ITEM_TO = "GIVE_USER_ITEM_TO",
	PURCHASE_USER_ITEM = "PURCHASE_USER_ITEM",
	RECIEVE_USER_ITEM_FROM = "RECEIVE_USER_ITEM_FROM",
	SELL_USER_ITEM = "SELL_USER_ITEM",
	UPDATE_USER_ITEM_DATA = "UPDATE_USER_ITEM_DATA",
	USE_USER_ITEM = "USE_USER_ITEM",
	PUBLISH_USER_ITEM_TO_BLOCKCHAIN = "PUBLISH_USER_ITEM_TO_BLOCKCHAIN",
	REFRESH_BLOCKCHAIN_USER_ITEMS = "REFRESH_BLOCKCHAIN_USER_ITEMS",
	REMOVE_USER_ITEM_FROM_BLOCKCHAIN = "REMOVE_USER_ITEM_FROM_BLOCKCHAIN",
	OPEN_BUNDLE = "OPEN_BUNDLE",
}


--- Creates a new UserItems service wrapper.
--- @param brainCloudClient BrainCloudClient
--- @return UserItems
function UserItems.new(brainCloudClient)
	local self = setmetatable({}, UserItems)
	self.client = brainCloudClient
	return self
end


--- Allows item(s) to be awarded to a user without collecting
-- the purchase amount. If includeDef is true, response
-- includes associated itemDef with language fields limited
-- to the current or default language.
-- @param defId
-- @param quantity
-- @param includeDef
-- Service Name - userItems
-- Service Operation - AWARD_USER_ITEM
-- 
-- 
function UserItems:awardUserItem(defId, quantity, includeDef, callback)
	local data = { defId = defId, quantity = quantity, includeDef = includeDef }
	self.client:sendRequest(SERVICE, OPS.AWARD_USER_ITEM, data, callback)
end

--- Awards item(s) to a user with additional options.
--- Service Name - userItems
--- Service Operation - AWARD_USER_ITEM
--- @param defId The unique id of the item definition to award.
--- @param quantity The quantity of the item to award.
--- @param includeDef If true, include associated item definition in the response.
--- @param optionsJson JSON string specifying additional options (e.g., blockIfExceedItemMaxStackable).
--- @param callback The method to be invoked when the server response is received
function UserItems:awardUserItemWithOptions(defId, quantity, includeDef, optionsJson, callback)
	local data = { defId = defId, quantity = quantity, includeDef = includeDef, optionsJson = Utils.emptyFix(optionsJson) }
	self.client:sendRequest(SERVICE, OPS.AWARD_USER_ITEM, data, callback)
end

--- Allows a quantity of a specified user item to be dropped,
-- without any recovery of the money paid for the item.
-- If any quantity of the user item remains, it will be returned,
-- potentially with the associated itemDef (with language fields
-- limited to the current or default language).
-- @param defId
-- @param quantity
-- @param includeDef
-- Service Name - userItems
-- Service Operation - DROP_USER_ITEM
-- 
-- 
function UserItems:dropUserItem(itemId, quantity, includeDef, callback)
	local data = { itemId = itemId, quantity = quantity, includeDef = includeDef }
	self.client:sendRequest(SERVICE, OPS.DROP_USER_ITEM, data, callback)
end

--- Retrieves the page of user's inventory from the server
-- based on the context. If includeDef is true, response
-- includes associated itemDef with each user item, with
-- language fields limited to the current or default language.
-- @param context
-- @param includeDef
-- Service Name - userItems
-- Service Operation - GET_USER_INVENTORY_PAGE
-- 
-- 
function UserItems:getUserItemsPage(context, includeDef, callback)
	local data = { context = context, includeDef = includeDef }
	self.client:sendRequest(SERVICE, OPS.GET_USER_ITEMS_PAGE, data, callback)
end

--- Retrieves the page of user's inventory from the server
-- based on the encoded context. If includeDef is true,
-- response includes associated itemDef with each user item,
-- with language fields limited to the current or default
-- language.
-- @param context
-- @param pageOffset
-- @param includeDef
-- Service Name - userItems
-- Service Operation - GET_USER_INVENTORY_PAGE_OFFSET
-- 
-- 
function UserItems:getUserItemsPageOffset(context, pageOffset, includeDef, callback)
	local data = { context = context, pageOffset = pageOffset, includeDef = includeDef }
	self.client:sendRequest(SERVICE, OPS.GET_USER_ITEMS_PAGE_OFFSET, data, callback)
end

--- Retrieves the identified user item from the server.
-- If includeDef is true, response includes associated
-- itemDef with language fields limited to the current
-- or default language.
-- @param itemId
-- @param includeDef
-- Service Name - userItems
-- Service Operation - GET_USER_ITEM
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function UserItems:getUserItem(itemId, includeDef, callback)
	local data = { itemId = itemId, includeDef = includeDef }
	self.client:sendRequest(SERVICE, OPS.GET_USER_ITEM, data, callback)
end

--- Gifts item to the specified player.
-- @param profileId
-- @param itemId
-- @param version
-- @param immediate
-- Service Name - userItems
-- Service Operation - GIVE_USER_ITEM_TO
-- 
-- 
function UserItems:giveUserItemTo(profileId, itemId, version, quantity, immediate, callback)
	local data = {
		profileId = profileId,
		itemId = itemId,
		version = version,
		quantity = quantity,
		immediate = immediate,
	}
	self.client:sendRequest(SERVICE, OPS.GIVE_USER_ITEM_TO, data, callback)
end

--- Retrieves the identified user item from the server.
-- If includeDef is true, response includes associated
-- itemDef with language fields limited to the current
-- or default language.
-- @param defId
-- @param quantity
-- @param shopId
-- @param includeDef
-- Service Name - userItems
-- Service Operation - PURCHASE_USER_ITEM
-- 
-- 
function UserItems:purchaseUserItem(defId, quantity, shopId, includeDef, callback)
	local data = { defId = defId, quantity = quantity, shopId = shopId, includeDef = includeDef }
	self.client:sendRequest(SERVICE, OPS.PURCHASE_USER_ITEM, data, callback)
end

--- Purchase a user item with options
--- @param defId string
--- @param quantity number
--- @param shopId string
--- @param includeDef boolean?
--- @param optionsJson table
--- @param callback fun(success: boolean, response: table)
function UserItems:purchaseUserItemWithOptions(defId, quantity, shopId, includeDef, optionsJson, callback)
	local data = {
		defId = defId,
		quantity = quantity,
		shopId = shopId,
		includeDef = includeDef,
		optionsJson = Utils.emptyFix(optionsJson),
	}
	self.client:sendRequest(SERVICE, OPS.PURCHASE_USER_ITEM, data, callback)
end

--- Same as purchaseUserItemWithOptions (C++/C# name).
function UserItems:purchaseUserItemsWithOptions(defId, quantity, shopId, includeDef, optionsJson, callback)
	self:purchaseUserItemWithOptions(defId, quantity, shopId, includeDef, optionsJson, callback)
end

--- Retrieves and transfers the gift item from
-- the specified player, who must have previously
-- called giveUserItemTo.
-- @param profileId
-- @param itemId
-- Service Name - userItems
-- Service Operation - RECEIVE_USER_ITEM_FROM
-- 
-- 
function UserItems:receiveUserItemFrom(profileId, itemId, callback)
	local data = { profileId = profileId, itemId = itemId }
	self.client:sendRequest(SERVICE, OPS.RECIEVE_USER_ITEM_FROM, data, callback)
end

--- Allows a quantity of a specified user item to be sold.
-- If any quantity of the user item remains, it will be returned,
-- potentially with the associated itemDef (with language fields
-- limited to the current or default language), along with the
-- currency refunded and currency balances.
-- @param itemId
-- @param version
-- @param quantity
-- @param shopId
-- @param includeDef
-- Service Name - userItems
-- Service Operation - SELL_USER_ITEM
-- 
-- 
function UserItems:sellUserItem(itemId, version, quantity, shopId, includeDef, callback)
	local data = { itemId = itemId, version = version, quantity = quantity, shopId = shopId, includeDef = includeDef }
	self.client:sendRequest(SERVICE, OPS.SELL_USER_ITEM, data, callback)
end

--- Updates the item data on the specified user item.
-- @param itemId
-- @param version
-- @param newItemData
-- Service Name - userItems
-- Service Operation - UPDATE_USER_ITEM_DATA
-- 
-- 
function UserItems:updateUserItemData(itemId, version, newItemData, callback)
	local data = { itemId = itemId, version = version, newItemData = Utils.emptyFix(newItemData) }
	self.client:sendRequest(SERVICE, OPS.UPDATE_USER_ITEM_DATA, data, callback)
end

--- Uses the specified item, potentially consuming it.
-- @param itemId
-- @param version
-- @param newItemData
-- @param includeDef
-- Service Name - userItems
-- Service Operation - USE_USER_ITEM
-- 
-- 
function UserItems:useUserItem(itemId, version, newItemData, includeDef, callback)
	local data = { itemId = itemId, version = version, newItemData = Utils.emptyFix(newItemData), includeDef = includeDef }
	self.client:sendRequest(SERVICE, OPS.USE_USER_ITEM, data, callback)
end

--- Publishes the specified item to the item management attached blockchain. Results are reported asynchronously via an RTT event.
-- @param itemId
-- @param version
-- @param newItemData
-- Service Name - userItems
-- Service Operation - PUBLISH_USER_ITEM_TO_BLOCKCHAIN
-- 
-- 
function UserItems:publishUserItemToBlockchain(itemId, version, callback)
	local data = { itemId = itemId, version = version }
	self.client:sendRequest(SERVICE, OPS.PUBLISH_USER_ITEM_TO_BLOCKCHAIN, data, callback)
end

--- Syncs the caller's user items with the item management attached blockchain. Results are reported asynchronously via an RTT event.
-- Service Name - userItems
-- Service Operation - REFRESH_BLOCKCHAUSER_ITEMS
-- 
-- 
function UserItems:refreshBlockchainUserItems(callback)
	self.client:sendRequest(SERVICE, OPS.REFRESH_BLOCKCHAIN_USER_ITEMS, {}, callback)
end

--- Removes the specified item from the item management attached blockchain. Results are reported asynchronously via an RTT event.
-- Service Name - userItems
-- Service Operation - REMOVE_USER_ITEM_FROM_BLOCKCHAIN
-- 
-- 
function UserItems:removeUserItemFromBlockchain(itemId, version, callback)
	local data = { itemId = itemId, version = version }
	self.client:sendRequest(SERVICE, OPS.REMOVE_USER_ITEM_FROM_BLOCKCHAIN, data, callback)
end

--- Returns a list of promotional details for a specified item.
--- Service Name - userItems
--- Service Operation - GET_ITEM_PROMOTION_DETAILS
--- @param defId Item definition ID.
--- @param shopId Store ID.
--- @param includeDef Include associated item definition if true.
--- @param includePromotionDetails Include promotion details if true.
--- @param callback Callback invoked when the server response is received.
function UserItems:getItemPromotionDetails(defId, shopId, includeDef, includePromotionDetails, callback)
	local data =
		{ defId = defId, shopId = shopId, includeDef = includeDef, includePromotionDetails = includePromotionDetails }
	self.client:sendRequest(SERVICE, OPS.GET_ITEM_PROMOTION_DETAILS, data, callback)
end

--- Returns a list of items on promotion available to the current user.
--- Service Name - userItems
--- Service Operation - GET_ITEMS_ON_PROMOTION
--- @param shopId Store ID.
--- @param includeDef Include associated item definition if true.
--- @param includePromotionDetails Include promotion details if true.
--- @param optionsJson JSON string specifying additional options (e.g., category).
--- @param callback Callback invoked when the server response is received.
function UserItems:getItemsOnPromotion(shopId, includeDef, includePromotionDetails, optionsJson, callback)
	local data = {
		shopId = shopId,
		includeDef = includeDef,
		includePromotionDetails = includePromotionDetails,
		optionsJson = Utils.emptyFix(optionsJson),
	}
	self.client:sendRequest(SERVICE, OPS.GET_ITEMS_ON_PROMOTION, data, callback)
end

--- Allows a quantity of a specified bundle user item to be opened. Response
--- indicates any items and currency awards configured for the associated bundle
--- user item's BUNDLE type item definition, plus any 'items' awarded and any
--- 'currencies' awarded, along with the resulting currency balances. If
--- includeItemDef is true, the associated item definition will be included in
--- the response for any user items awarded and for the bundle user item being
--- opened (if any quantity of the bundle user item remains), with language
--- fields limited to the current or default language.
--- Service Name - userItems
--- Service Operation - OPEN_BUNDLE
--- @param itemId ID of the bundle item to open.
--- @param version Version of the bundle item (pass -1 for any version).
--- @param quantity Quantity of the item to open.
--- @param includeDef Include associated item definitions if true.
--- @param optionsJson JSON string specifying additional options.
--- @param callback The method to be invoked when the server response is received
function UserItems:openBundle(itemId, version, quantity, includeDef, optionsJson, callback)
	local data = {
		itemId = itemId,
		version = version,
		quantity = quantity,
		includeDef = includeDef,
		optionsJson = Utils.emptyFix(optionsJson),
	}

	self.client:sendRequest(SERVICE, OPS.OPEN_BUNDLE, data, callback)
end

return UserItems

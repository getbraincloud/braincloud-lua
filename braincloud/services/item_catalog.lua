local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local ItemCatalog = {}
ItemCatalog.__index = ItemCatalog

local SERVICE = "itemCatalog"

local OPS = {
	GET_CATALOG_ITEM_DEFINITION = "GET_CATALOG_ITEM_DEFINITION",
	GET_CATALOG_ITEMS_PAGE = "GET_CATALOG_ITEMS_PAGE",
	GET_CATALOG_ITEMS_PAGE_OFFSET = "GET_CATALOG_ITEMS_PAGE_OFFSET",
}

--- Creates a new ItemCatalog instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return ItemCatalog
function ItemCatalog.new(brainCloudClient)
	local self = setmetatable({}, ItemCatalog)
	self.client = brainCloudClient
	return self
end

--- Reads an existing item definition from the server, with language fields
-- limited to the current or default language
-- @param defId
-- Service Name - itemCatalog
-- Service Operation - GET_CATALOG_ITEM_DEFINITION
-- 
-- 
function ItemCatalog:getCatalogItemDefinition(defId, callback)
	self.client:sendRequest(SERVICE, OPS.GET_CATALOG_ITEM_DEFINITION, { defId = defId }, callback)
end

--- Retrieve page of catalog items from the server, with language fields limited to the
-- text for the current or default language.
-- @param context
-- Service Name - itemCatalog
-- Service Operation - GET_CATALOG_ITEMS_PAGE
-- 
-- 
function ItemCatalog:getCatalogItemsPage(context, callback)
	self.client:sendRequest(SERVICE, OPS.GET_CATALOG_ITEMS_PAGE, { context = context }, callback)
end

--- Gets the page of catalog items from the server based ont he encoded
-- context and specified page offset, with language fields limited to the
-- text fir the current or default language
-- @param context
-- @param pageOffset
-- Service Name - itemCatalog
-- Service Operation - GET_CATALOG_ITEMS_PAGE_OFFSET
-- 
-- 
function ItemCatalog:getCatalogItemsPageOffset(context, pageOffset, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.GET_CATALOG_ITEMS_PAGE_OFFSET,
		{ context = context, pageOffset = pageOffset },
		callback
	)
end

return ItemCatalog

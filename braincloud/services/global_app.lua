local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")
local GlobalApp = {}
GlobalApp.__index = GlobalApp

local SERVICE = "globalApp"

local OPS = {
	READ_PROPERTIES = "READ_PROPERTIES",
	READ_SELECTED_PROPERTIES = "READ_SELECTED_PROPERTIES",
	READ_PROPERTIES_IN_CATEGORIES = "READ_PROPERTIES_IN_CATEGORIES",
}


--- Constructor

--- Creates a new GlobalApp instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return GlobalApp
function GlobalApp.new(brainCloudClient)
	local self = setmetatable({}, GlobalApp)
	self.client = brainCloudClient
	return self
end


--- SERVICE METHODS

--- Read game's global properties
-- Service Name - globalApp
-- Service Operation - READ_PROPERTIES
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function GlobalApp:readProperties(callback)
	self.client:sendRequest(SERVICE, OPS.READ_PROPERTIES, {}, callback)
end

--- Returns a list of properties, identified by the property names provided.
-- If a property from the list isn't found, it just isn't returned (no error).
-- Service Name - globalApp
-- Service Operation - READ_SELECTED_PROPERTIES
-- 
-- @param propertyNames Specifies which properties to return
-- @param callback The method to be invoked when the server response is received
-- 
function GlobalApp:readSelectedProperties(propertyNames, callback)
	local data = { propertyNames = propertyNames }
	self.client:sendRequest(SERVICE, OPS.READ_SELECTED_PROPERTIES, data, callback)
end

--- Returns a list of properties, identified by the categories provided.
-- If a category from the list isn't found, it just isn't returned (no error).
-- Service Name - globalApp
-- Service Operation - READ_PROPERTIES_CATEGORIES
-- 
-- @param categories Specifies which category to return
-- @param callback The method to be invoked when the server response is received
-- 
function GlobalApp:readPropertiesInCategories(categories, callback)
	local data = { categories = Utils.array(categories) }
	self.client:sendRequest(SERVICE, OPS.READ_PROPERTIES_IN_CATEGORIES, data, callback)
end

return GlobalApp

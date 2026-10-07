local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local VirtualCurrency = {}
VirtualCurrency.__index = VirtualCurrency

local SERVICE = "virtualCurrency"

local OPS = {
	GET_CURRENCY = "GET_PLAYER_VC",
	GET_PARENT_CURRENCY = "GET_PARENT_VC",
	GET_PEER_CURRENCY = "GET_PEER_VC",
	RESET_PLAYER_VC = "RESET_PLAYER_VC",

	AWARD_VC = "AWARD_VC",
	CONSUME_VC = "CONSUME_VC",
}

--- Create a new VirtualCurrency service instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return VirtualCurrency
function VirtualCurrency.new(brainCloudClient)
	local self = setmetatable({}, VirtualCurrency)
	self.client = brainCloudClient
	return self
end

--- Retrieve the user's currency account. Optional parameters: vcId (if retrieving all currencies).
-- @param vcId
-- Service Name - virtualCurrency
-- Service Operation - GET_PLAYER_VC
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function VirtualCurrency:getCurrency(vcId, callback)
	local data = { vcId = vcId }
	self.client:sendRequest(SERVICE, OPS.GET_CURRENCY, data, callback)
end

--- Retrieve the parent user's currency account. Optional parameters: vcId (if retrieving all currencies).
-- @param vcId
-- @param levelName
-- Service Name - virtualCurrency
-- Service Operation - GET_PARENT_VC
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function VirtualCurrency:getParentCurrency(vcId, levelName, callback)
	local data = { vcId = vcId, levelName = levelName }
	self.client:sendRequest(SERVICE, OPS.GET_PARENT_CURRENCY, data, callback)
end

--- Retrieve the peer user's currency account. Optional parameters: vcId (if retrieving all currencies).
-- @param vcId
-- @param peerCode
-- Service Name - virtualCurrency
-- Service Operation - GET_PEER_VC
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function VirtualCurrency:getPeerCurrency(vcId, peerCode, callback)
	local data = { vcId = vcId, peerCode = peerCode }
	self.client:sendRequest(SERVICE, OPS.GET_PEER_CURRENCY, data, callback)
end

--- @warning Method is recommended to be used in Cloud Code only for security
-- If you need to use it client side, enable 'Allow Currency Calls from Client' on the brainCloud dashboard
-- 
-- 
function VirtualCurrency:awardCurrency(vcId, vcAmount, callback)
	local data = { vcId = vcId, vcAmount = vcAmount }
	self.client:sendRequest(SERVICE, OPS.AWARD_VC, data, callback)
end

--- @warning Method is recommended to be used in Cloud Code only for security
-- If you need to use it client side, enable 'Allow Currency Calls from Client' on the brainCloud dashboard
-- 
-- 
function VirtualCurrency:consumeCurrency(vcId, vcAmount, callback)
	local data = { vcId = vcId, vcAmount = vcAmount }
	self.client:sendRequest(SERVICE, OPS.CONSUME_VC, data, callback)
end

--- Reset player's currency to zero
-- Service Name - virtualCurrency
-- Service Operation - RESET_PLAYER_VC
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function VirtualCurrency:resetCurrency(callback)
	self.client:sendRequest(SERVICE, OPS.RESET_PLAYER_VC, {}, callback)
end

return VirtualCurrency

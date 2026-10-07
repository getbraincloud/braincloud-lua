local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Blockchain = {}
Blockchain.__index = Blockchain

local SERVICE = "blockchain"

local OPS = {
	GET_BLOCKCHAIN_ITEMS = "GET_BLOCKCHAIN_ITEMS",
	GET_UNIQS = "GET_UNIQS",
}

function Blockchain.new(brainCloudClient)
	local self = setmetatable({}, Blockchain)
	self.client = brainCloudClient
	return self
end

--- @brief Retrieves the blockchain items owned by the caller.
-- Service Name - blockchain
-- Service Operation - GET_BLOCKCHAIN_ITEMS
-- 
-- 
function Blockchain:getBlockchainItems(integrationId, contextJson, callback)
	local data = { integrationId = integrationId, contextJson = contextJson or {} }
	self.client:sendRequest(SERVICE, OPS.GET_BLOCKCHAIN_ITEMS, data, callback)
end

--- @brief Retrieves the uniqs owned by the caller.
-- Service Name - blockchain
-- Service Operation - GET_UNIQS
-- 
-- 
function Blockchain:getUniqs(integrationId, contextJson, callback)
	local data = { integrationId = integrationId, contextJson = contextJson or {} }
	self.client:sendRequest(SERVICE, OPS.GET_UNIQS, data, callback)
end

return Blockchain

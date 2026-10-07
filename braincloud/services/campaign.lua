local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Campaign = {}
Campaign.__index = Campaign

local SERVICE = "campaign"

local OPS = {
	GET_MY_CAMPAIGNS = "GET_MY_CAMPAIGNS",
}

--- Creates a new Campaign service instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return Campaign
function Campaign.new(brainCloudClient)
	local self = setmetatable({}, Campaign)
	self.client = brainCloudClient
	return self
end

--- Returns the list of campaigns the current player is participating in,
-- providing campaign, campaign scenario, and participation details.
-- Service Name - campaign
-- Service Operation - GET_MY_CAMPAIGNS
-- 
-- @param optionsJson Optional parameters as a JSON string (reserved for future use).
-- @param callback The method to be invoked when the server response is received.
-- 
function Campaign:getMyCampaigns(optionsJson, callback)
	local data = optionsJson or {}
	self.client:sendRequest(SERVICE, OPS.GET_MY_CAMPAIGNS, { optionsJson = data }, callback)
end

return Campaign

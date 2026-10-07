local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local RedemptionCode = {}
RedemptionCode.__index = RedemptionCode

local SERVICE = "redemptionCode"

local OPS = {
	REDEEM_CODE = "REDEEM_CODE",
	GET_REDEEMED_CODES = "GET_REDEEMED_CODES",
}

function RedemptionCode.new(baseClient)
	local self = setmetatable({}, RedemptionCode)
	self.client = baseClient
	return self
end

--- Redeem a code.
-- Service Name - redemptionCode
-- Service Operation - REDEEM_CODE
-- 
-- @param scanCode The code to redeem
-- @param codeType The type of code
-- @param jsonCustomRedemptionInfo Optional - A JSON string containing custom redemption data
-- @param callback The method to be invoked when the server response is received
-- 
function RedemptionCode:redeemCode(scanCode, codeType, jsonCustomRedemptionInfo, callback)
	local data = {
		scanCode = scanCode,
		codeType = codeType,
	}

	if jsonCustomRedemptionInfo then
		data.customRedemptionInfo = jsonCustomRedemptionInfo
	end

	self.client:sendRequest(SERVICE, OPS.REDEEM_CODE, data, callback)
end

--- Retrieve the codes already redeemed by player.
-- Service Name - redemptionCode
-- Service Operation - GET_REDEEMED_CODES
-- 
-- @param codeType Optional - The type of codes to retrieve. Returns all codes if left unspecified.
-- @param callback The method to be invoked when the server response is received
-- 
function RedemptionCode:getRedeemedCodes(codeType, callback)
	local data = {}
	if codeType then
		data.codeType = codeType
	end
	self.client:sendRequest(SERVICE, OPS.GET_REDEEMED_CODES, data, callback)
end

return RedemptionCode

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Raw = {}
Raw.__index = Raw

--- Constructor
function Raw.new(baseClient)
	local self = setmetatable({}, Raw)
	self.client = baseClient
	return self
end

--- Just send the raw call to the base client
function Raw:sendRequest(service, operation, data, callback)
	self.client:sendRequest(service, operation, data, callback)
end

--- Export
return Raw

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Mail = {}
Mail.__index = Mail

local SERVICE = "mail"

local OPS = {
	SEND_BASIC_EMAIL = "SEND_BASIC_EMAIL",
	SEND_ADVANCED_EMAIL = "SEND_ADVANCED_EMAIL",
	SEND_ADVANCED_EMAIL_BY_ADDRESS = "SEND_ADVANCED_EMAIL_BY_ADDRESS",
	SEND_ADVANCED_EMAIL_BY_ADDRESSES = "SEND_ADVANCED_EMAIL_BY_ADDRESSES",
}

--- Creates a new Mail instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return Mail
function Mail.new(brainCloudClient)
	local self = setmetatable({}, Mail)
	self.client = brainCloudClient
	return self
end

--- Sends a simple text email to the specified player
--- Service Name - mail
--- Service Operation - SEND_BASIC_EMAIL
--- @param profileId The user to send the email to
--- @param subject The email subject
--- @param body The email body
--- @param callback The method to be invoked when the server response is received
function Mail:sendBasicEmail(profileId, subject, body, callback)
	local data = { profileId = profileId, subject = subject, body = body }
	self.client:sendRequest(SERVICE, OPS.SEND_BASIC_EMAIL, data, callback)
end

--- Sends an advanced email to the specified player
--- Service Name - mail
--- Service Operation - SEND_ADVANCED_EMAIL
--- @param profileId The user to send the email to
--- @param jsonServiceParams Parameters to send to the email service. See the documentation for
---        a full list. http://getbraincloud.com/apidocs/apiref/#capi-mail
--- @param callback The method to be invoked when the server response is received
function Mail:sendAdvancedEmail(profileId, serviceParams, callback)
	local data = { profileId = profileId, serviceParams = serviceParams }
	self.client:sendRequest(SERVICE, OPS.SEND_ADVANCED_EMAIL, data, callback)
end

--- Sends an advanced email to the specified email address
--- Service Name - mail
--- Service Operation - SEND_ADVANCED_EMAIL_BY_ADDRESS
--- @param emailAddress The address to send the email to
--- @param jsonServiceParams Parameters to send to the email service. See the documentation for
---        a full list. http://getbraincloud.com/apidocs/apiref/#capi-mail
--- @param callback The method to be invoked when the server response is received
function Mail:sendAdvancedEmailByAddress(emailAddress, serviceParams, callback)
	local data = { emailAddress = emailAddress, serviceParams = serviceParams }
	self.client:sendRequest(SERVICE, OPS.SEND_ADVANCED_EMAIL_BY_ADDRESS, data, callback)
end

--- Sends an advanced email to the specified email addresses.
-- Service Name - mail
-- Service Operation - SEND_ADVANCED_EMAIL_BY_ADDRESSES
-- 
-- @param emailAddress The list of addresses to send the email to
-- @param serviceParams Set of parameters dependant on the mail service configured
-- @param callback The method to be invoked when the server response is received
-- 
function Mail:sendAdvancedEmailByAddresses(emailAddresses, serviceParams, callback)
	local data = { emailAddresses = emailAddresses, serviceParams = serviceParams }
	self.client:sendRequest(SERVICE, OPS.SEND_ADVANCED_EMAIL_BY_ADDRESSES, data, callback)
end

return Mail

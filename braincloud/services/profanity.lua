local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Profanity = {}
Profanity.__index = Profanity

local SERVICE = "profanity"

local OPS = {
	PROFANITY_CHECK = "PROFANITY_CHECK",
	PROFANITY_REPLACE_TEXT = "PROFANITY_REPLACE_TEXT",
	PROFANITY_IDENTIFY_BAD_WORDS = "PROFANITY_IDENTIFY_BAD_WORDS",
}

--- Creates a new Profanity service instance.
--- @param baseClient table
--- @return Profanity
function Profanity.new(baseClient)
	local self = setmetatable({}, Profanity)
	self.client = baseClient
	return self
end

--- Checks supplied text for profanity.
-- Service Name - profanity
-- Service Operation - PROFANITY_CHECK
-- 
-- @param text The text to check
-- @param languages Optional comma delimited list of two character language codes
-- @param flagEmail Optional processing of email addresses
-- @param flagPhone Optional processing of phone numbers
-- @param flagUrls Optional processing of urls
-- @param callback The method to be invoked when the server response is received
--        Significant error codes:
--        40421 - WebPurify not configured
--        40422 - General exception occurred
--        40423 - WebPurify returned an error (Http status != 200)
--        40424 - WebPurify not enabled
-- 
function Profanity:profanityCheck(text, languages, flagEmail, flagPhone, flagUrls, callback)
	local data = { text = text }
	if languages ~= nil then
		data.languages = languages
	end
	data.flagEmail = flagEmail
	data.flagPhone = flagPhone
	data.flagUrls = flagUrls

	self.client:sendRequest(SERVICE, OPS.PROFANITY_CHECK, data, callback)
end

--- Replaces the characters of profanity text with a passed character(s).
-- Service Name - profanity
-- Service Operation - PROFANITY_REPLACE_TEXT
-- 
-- @param text The text to check
-- @param replaceSymbol The text to replace individual characters of profanity text with
-- @param languages Optional comma delimited list of two character language codes
-- @param flagEmail Optional processing of email addresses
-- @param flagPhone Optional processing of phone numbers
-- @param flagUrls Optional processing of urls
-- @param callback The method to be invoked when the server response is received
--        Significant error codes:
--        40421 - WebPurify not configured
--        40422 - General exception occurred
--        40423 - WebPurify returned an error (Http status != 200)
--        40424 - WebPurify not enabled
-- 
function Profanity:profanityReplaceText(text, replaceSymbol, languages, flagEmail, flagPhone, flagUrls, callback)
	local data = { text = text, replaceSymbol = replaceSymbol }
	if languages ~= nil then
		data.languages = languages
	end
	data.flagEmail = flagEmail
	data.flagPhone = flagPhone
	data.flagUrls = flagUrls

	self.client:sendRequest(SERVICE, OPS.PROFANITY_REPLACE_TEXT, data, callback)
end

--- Checks supplied text for profanity and returns a list of bad wors.
-- Service Name - profanity
-- Service Operation - PROFANITY_IDENTIFY_BAD_WORDS
-- 
-- @param text The text to check
-- @param languages Optional comma delimited list of two character language codes
-- @param flagEmail Optional processing of email addresses
-- @param flagPhone Optional processing of phone numbers
-- @param flagUrls Optional processing of urls
-- @param callback The method to be invoked when the server response is received
--        Significant error codes:
--        40421 - WebPurify not configured
--        40422 - General exception occurred
--        40423 - WebPurify returned an error (Http status != 200)
--        40424 - WebPurify not enabled
-- 
function Profanity:profanityIdentifyBadWords(text, languages, flagEmail, flagPhone, flagUrls, callback)
	local data = { text = text }
	if languages ~= nil then
		data.languages = languages
	end
	data.flagEmail = flagEmail
	data.flagPhone = flagPhone
	data.flagUrls = flagUrls

	self.client:sendRequest(SERVICE, OPS.PROFANITY_IDENTIFY_BAD_WORDS, data, callback)
end

return Profanity

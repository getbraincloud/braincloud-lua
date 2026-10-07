local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")
local S3Handling = {}
S3Handling.__index = S3Handling

local SERVICE = "s3Handling"

local OPS = {
	GET_FILE_LIST = "GET_FILE_LIST",
	GET_UPDATED_FILES = "GET_UPDATED_FILES",
	GET_CDN_URL = "GET_CDN_URL",
}

--- Create a new S3Handling service instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return S3Handling
function S3Handling.new(brainCloudClient)
	local self = setmetatable({}, S3Handling)
	self.client = brainCloudClient
	return self
end

--- Sends an array of file details and returns
-- the details of any of those files that have changed
-- Service Name - s3Handling
-- Service Operation - GET_UPDATED_FILES
-- 
-- @param category Category of files on server to compare against
-- @param fileDetailsJson An array of file details
-- @param callback Instance of IServerCallback to call when the server response is received
-- 
function S3Handling:getUpdatedFiles(category, fileDetails, callback)
	local data = { category = category, fileDetails = Utils.array(fileDetails) }
	self.client:sendRequest(SERVICE, OPS.GET_UPDATED_FILES, data, callback)
end

--- Retrieves the details of custom files stored on the server
-- Service Name - s3Handling
-- Service Operation - GET_FILE_LIST
-- 
-- @param category Category of files to retrieve
-- @param callback Instance of IServerCallback to call when the server response is receieved
-- 
function S3Handling:getFileList(category, callback)
	local data = { category = category }
	self.client:sendRequest(SERVICE, OPS.GET_FILE_LIST, data, callback)
end

--- Returns the CDN url for a file
-- 
-- @param fileId ID of file
-- @param callback The method to be invoked when the server response is received
-- 
function S3Handling:getCDNUrl(fileId, callback)
	local data = { fileId = fileId }
	self.client:sendRequest(SERVICE, OPS.GET_CDN_URL, data, callback)
end

return S3Handling

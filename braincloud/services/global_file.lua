local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local GlobalFile = {}
GlobalFile.__index = GlobalFile

local SERVICE = "globalFileV3"

local OPS = {
	GET_FILE_INFO = "GET_FILE_INFO",
	GET_FILE_INFO_SIMPLE = "GET_FILE_INFO_SIMPLE",
	GET_GLOBAL_CDN_URL = "GET_GLOBAL_CDN_URL",
	GET_GLOBAL_FILE_LIST = "GET_GLOBAL_FILE_LIST",
}

--- Create a new GlobalFile service instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return GlobalFile
function GlobalFile.new(brainCloudClient)
	local self = setmetatable({}, GlobalFile)
	self.client = brainCloudClient
	return self
end

--- Returns the complete info for the specified file given it’s fileId
-- Service Name - globalFileV3
-- Service Operation - GET_FILE_INFO
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function GlobalFile:getFileInfo(fileId, callback)
	local data = { fileId = fileId }
	self.client:sendRequest(SERVICE, OPS.GET_FILE_INFO, data, callback)
end

--- Returns the complete info for the specified file, without having to look up the fileId first.
-- Service Name - globalFileV3
-- Service Operation - GET_FILE_INFO_SIMPLE
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function GlobalFile:getFileInfoSimple(folderPath, filename, callback)
	local data = { folderPath = folderPath, filename = filename }
	self.client:sendRequest(SERVICE, OPS.GET_FILE_INFO_SIMPLE, data, callback)
end

--- Returns the CDN of the specified file.
-- Service Name - globalFileV3
-- Service Operation - GET_GLOBAL_CDN_URL
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function GlobalFile:getGlobalCDNUrl(fileId, callback)
	local data = { fileId = fileId }
	self.client:sendRequest(SERVICE, OPS.GET_GLOBAL_CDN_URL, data, callback)
end

--- Returns files at the current path.
-- Service Name - globalFileV3
-- Service Operation - GET_GLOBAL_FILE_LIST
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function GlobalFile:getGlobalFileList(folderPath, recurse, callback)
	local data = { folderPath = folderPath, recurse = recurse }
	self.client:sendRequest(SERVICE, OPS.GET_GLOBAL_FILE_LIST, data, callback)
end

return GlobalFile

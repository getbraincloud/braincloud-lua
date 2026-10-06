local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local File = {}
File.__index = File

local SERVICE = "file"

local OPS = {
	PREPARE_USER_UPLOAD = "PREPARE_USER_UPLOAD",
	LIST_USER_FILES = "LIST_USER_FILES",
	DELETE_USER_FILE = "DELETE_USER_FILE",
	DELETE_USER_FILES = "DELETE_USER_FILES",
	GET_CDN_URL = "GET_CDN_URL",
}

--- Create a new File service instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return File
function File.new(brainCloudClient)
	local self = setmetatable({}, File)
	self.client = brainCloudClient
	return self
end

--- Prepare a user upload and obtain an uploadId from the server.
--- @param cloudPath string|nil Desired cloud path
--- @param cloudFilename string|nil Desired cloud filename
--- @param shareable boolean|nil Whether the file is shareable
--- @param replaceIfExists boolean|nil Whether to replace existing file
--- @param fileSize number|nil File size in bytes
--- @param callback fun(success:boolean, response:table)|nil Optional callback
function File:prepareUserUpload(cloudPath, cloudFilename, shareable, replaceIfExists, fileSize, callback)
	local message = {
		cloudPath = cloudPath,
		cloudFilename = cloudFilename,
		shareable = shareable,
		replaceIfExists = replaceIfExists,
		fileSize = fileSize,
	}

	self.client:sendRequest(SERVICE, OPS.PREPARE_USER_UPLOAD, message, callback)
end

--- Prepares a user file upload. On success the file will begin uploading
-- to the brainCloud server. To be informed of success/failure of the upload
-- register an IFileUploadCallback with the BrainCloudClient class.
-- Service Name - file
-- Service Operation - PREPARE_USER_UPLOAD
-- 
-- @param cloudPath The desired cloud path of the file
-- @param cloudFilename The desired cloud filename of the file
-- @param shareable True if the file is shareable.
-- @param replaceIfExists Whether to replace file if it exists
-- @param localPath The path and filename of the local file
-- @param callback The method to be invoked when the server response is received
--        Significant error codes:
--        40429 - File maximum file size exceeded
--        40430 - File exists, replaceIfExists not set
-- 
function File:uploadFile(cloudPath, cloudFilename, shareable, replaceIfExists, localPath, callback)
	local data = self.client.platform.readLocalFile(localPath)
	if not data then
		if callback then
			callback(false, { status = 900, reason_code = 0, status_message = "Could not read " .. tostring(localPath) })
		end
		return
	end
	self:uploadFileFromMemory(cloudPath, cloudFilename, shareable, replaceIfExists, data, callback)
end

--- Prepares the upload, then sends fileData (a string) to the uploader. The callback gets the
--- prepare result once the upload completes.
function File:uploadFileFromMemory(cloudPath, cloudFilename, shareable, replaceIfExists, fileData, callback)
	local message = {
		cloudPath = cloudPath,
		cloudFilename = cloudFilename,
		shareable = shareable,
		replaceIfExists = replaceIfExists,
		fileSize = #fileData,
	}
	self.client:sendRequest(SERVICE, OPS.PREPARE_USER_UPLOAD, message, function(success, prepareResult)
		if not success then
			if callback then
				callback(false, prepareResult)
			end
			return
		end
		local uploadId = prepareResult.data.fileDetails.uploadId
		self.client:uploadFile(uploadId, cloudFilename, fileData, function(code, body)
			if not callback then
				return
			end
			if code == 200 then
				callback(true, prepareResult)
			else
				callback(false, { status = code, reason_code = 0, status_message = body })
			end
		end)
	end)
end

--- List all user files
-- Service Name - file
-- Service Operation - LIST_USER_FILES
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function File:listUserFiles(cloudPath, recurse, callback)
	local message = {}
	if cloudPath ~= nil then
		message.path = cloudPath
	end
	if recurse ~= nil then
		message.recurse = recurse
	end
	self.client:sendRequest(SERVICE, OPS.LIST_USER_FILES, message, callback)
end

--- Deletes a single user file.
-- Service Name - file
-- Service Operation - DELETE_USER_FILES
-- 
-- @param cloudPath File path
-- @param cloudFilename name of file
-- @param callback The method to be invoked when the server response is received
--        Significant error codes:
--        40431 - Cloud storage service error
--        40432 - File does not exist
-- 
function File:deleteUserFile(cloudPath, cloudFilename, callback)
	local message = { cloudPath = cloudPath, cloudFilename = cloudFilename }
	self.client:sendRequest(SERVICE, OPS.DELETE_USER_FILE, message, callback)
end

--- Delete multiple user files
-- Service Name - file
-- Service Operation - DELETE_USER_FILES
-- 
-- @param cloudPath File path
-- @param recurse Whether to recurse into sub-directories
-- @param callback The method to be invoked when the server response is received
-- 
function File:deleteUserFiles(cloudPath, recurse, callback)
	local message = { cloudPath = cloudPath, recurse = recurse }
	self.client:sendRequest(SERVICE, OPS.DELETE_USER_FILES, message, callback)
end

--- Returns the CDN url for a file object
-- Service Name - file
-- Service Operation - GET_CDN_URL
-- 
-- @param cloudPath File path
-- @param cloudFileName File name
-- @param callback The method to be invoked when the server response is received
-- 
function File:getCDNUrl(cloudPath, cloudFilename, callback)
	local message = { cloudPath = cloudPath, cloudFilename = cloudFilename }
	self.client:sendRequest(SERVICE, OPS.GET_CDN_URL, message, callback)
end

return File

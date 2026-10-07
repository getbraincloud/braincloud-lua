local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local GroupFile = {}
GroupFile.__index = GroupFile

local SERVICE = "groupFile"

local OPS = {
	GET_FILE_INFO = "GET_FILE_INFO",
	GET_FILE_INFO_SIMPLE = "GET_FILE_INFO_SIMPLE",
	GET_CDN_URL = "GET_CDN_URL",
	GET_FILE_LIST = "GET_FILE_LIST",
	CHECK_FILENAME_EXISTS = "CHECK_FILENAME_EXISTS",
	CHECK_FULLPATH_FILENAME_EXISTS = "CHECK_FULLPATH_FILENAME_EXISTS",
	MOVE_FILE = "MOVE_FILE",
	UPDATE_FILE_INFO = "UPDATE_FILE_INFO",
	COPY_FILE = "COPY_FILE",
	DELETE_FILE = "DELETE_FILE",
	MOVE_USER_TO_GROUP_FILE = "MOVE_USER_TO_GROUP_FILE",
}

--- Create a new GroupFile service instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return GroupFile
function GroupFile.new(brainCloudClient)
	local self = setmetatable({}, GroupFile)
	self.client = brainCloudClient
	return self
end

--- Returns information on a file using fileId.
-- Service Name - groupFile
-- Service Operation - GET_FILE_INFO
-- 
-- @param groupId the groupId
-- @param fileId the fileId
-- @param callback Block to call on return of  server response
-- 
function GroupFile:getFileInfo(groupId, fileId, callback)
	local data = { groupId = groupId, fileId = fileId }
	self.client:sendRequest(SERVICE, OPS.GET_FILE_INFO, data, callback)
end

--- Returns information on a file using path and name.
-- Service Name - groupFile
-- Service Operation - GET_FILE_INFO_SIMPLE
-- 
-- @param groupId the groupId
-- @param folderPath the folderPath
-- @param fileName the fileName
-- @param callback Block to call on return of  server response
-- 
function GroupFile:getFileInfoSimple(groupId, folderPath, filename, callback)
	local data = { groupId = groupId, folderPath = folderPath, filename = filename }
	self.client:sendRequest(SERVICE, OPS.GET_FILE_INFO_SIMPLE, data, callback)
end

--- Return CDN url for file for clients that cannot handle redirect.
-- Service Name - groupFile
-- Service Operation - GET_CDN_URL
-- 
-- @param groupId the groupId
-- @param fileId the fileId
-- @param callback Block to call on return of  server response
-- 
function GroupFile:getCDNUrl(groupId, fileId, callback)
	local data = { groupId = groupId, fileId = fileId }
	self.client:sendRequest(SERVICE, OPS.GET_CDN_URL, data, callback)
end

--- Returns a list of files.
-- Service Name - groupFile
-- Service Operation - GET_FILE_LIST
-- 
-- @param groupId the groupId
-- @param folderPath the folderPath
-- @param recurse true to recurse
-- @param callback Block to call on return of  server response
-- 
function GroupFile:getFileList(groupId, folderPath, recurse, callback)
	local data = { groupId = groupId, folderPath = folderPath, recurse = recurse }
	self.client:sendRequest(SERVICE, OPS.GET_FILE_LIST, data, callback)
end

--- Check if filename exists for provided path and name
-- Service Name - groupFile
-- Service Operation - CHECK_FILENAME_EXISTS
-- 
-- @param groupId ID of the group.
-- @param folderPath The path of the file
-- @param filename The filename of the file
-- @param callback Block to call on return of  server response
-- 
function GroupFile:checkFilenameExists(groupId, folderPath, filename, callback)
	local data = { groupId = groupId, folderPath = folderPath, filename = filename }
	self.client:sendRequest(SERVICE, OPS.CHECK_FILENAME_EXISTS, data, callback)
end

--- Check if filename exists for provided full path name
-- Service Name - groupFile
-- Service Operation - CHECK_FULLPATH_FILENAME_EXISTS
-- 
-- @param groupId ID of the group.
-- @param fullPathFilename The full path of the file
-- @param callback Block to call on return of  server response
-- 
function GroupFile:checkFullpathFilenameExists(groupId, fullPathFilename, callback)
	local data = { groupId = groupId, fullPathFilename = fullPathFilename }
	self.client:sendRequest(SERVICE, OPS.CHECK_FULLPATH_FILENAME_EXISTS, data, callback)
end

--- Move a file.
-- Service Name - groupFile
-- Service Operation - MOVE_FILE
-- 
-- @param groupId the groupId
-- @param fileId the fileId
-- @param version the version
-- @param newTreeId the newTreeId
-- @param newFilename the newFilename
-- @param callback Block to call on return of  server response
-- 
function GroupFile:moveFile(groupId, fileId, version, newTreeId, treeVersion, newFilename, overwriteIfPresent, callback)
	local data = {
		groupId = groupId,
		fileId = fileId,
		version = version,
		newTreeId = newTreeId,
		treeVersion = treeVersion,
		newFilename = newFilename,
		overwriteIfPresent = overwriteIfPresent,
	}
	self.client:sendRequest(SERVICE, OPS.MOVE_FILE, data, callback)
end

--- updates information on a file given fileId.
-- Service Name - groupFile
-- Service Operation - UPDATE_FILE_INFO
-- 
-- @param groupId the groupId
-- @param fileId the fileId
-- @param version the version
-- @param newFilename the newFilename
-- @param newAcl the newAcl
-- @param callback Block to call on return of  server response
-- 
function GroupFile:updateFileInfo(groupId, fileId, version, newFilename, newAcl, callback)
	local data = { groupId = groupId, fileId = fileId, version = version, newFilename = newFilename, newAcl = newAcl }
	self.client:sendRequest(SERVICE, OPS.UPDATE_FILE_INFO, data, callback)
end

--- Copy a file.
-- Service Name - groupFile
-- Service Operation - COPY_FILE
-- 
-- @param groupId the groupId
-- @param fileId the fileId
-- @param version the version
-- @param newTreeId thenewTreeId
-- @param treeVersion the treeVersion
-- @param newFilename the newFilename
-- @param callback Block to call on return of  server response
-- 
function GroupFile:copyFile(groupId, fileId, version, newTreeId, treeVersion, newFilename, overwriteIfPresent, callback)
	local data = {
		groupId = groupId,
		fileId = fileId,
		version = version,
		newTreeId = newTreeId,
		treeVersion = treeVersion,
		newFilename = newFilename,
		overwriteIfPresent = overwriteIfPresent,
	}
	self.client:sendRequest(SERVICE, OPS.COPY_FILE, data, callback)
end

--- Delete a file.
-- Service Name - groupFile
-- Service Operation - DELETE_FILE
-- 
-- @param groupId the groupId
-- @param fileId the fileId
-- @param version the version
-- @param newFilename the newFilename
-- @param callback Block to call on return of  server response
-- 
function GroupFile:deleteFile(groupId, fileId, version, filename, callback)
	local data = { groupId = groupId, fileId = fileId, version = version, filename = filename }
	self.client:sendRequest(SERVICE, OPS.DELETE_FILE, data, callback)
end

--- Move a file from user space to group space.
-- Service Name - groupFile
-- Service Operation - MOVE_USER_TO_GROUP_FILE
-- 
-- @param userCloudPath the userCloudPath
-- @param userCloudFilename the userCloudFilename
-- @param groupId the groupId
-- @param groupTreeId the groupTreeId
-- @param groupFilename the groupFilename
-- @param groupFileAcl the groupFileAcl
-- @param overwriteIfPresent the overwriteIfPresent
-- @param callback Block to call on return of  server response
-- 
function GroupFile:moveUserToGroupFile(
	userCloudPath,
	userCloudFilename,
	groupId,
	groupTreeId,
	groupFilename,
	groupFileAcl,
	overwriteIfPresent,
	callback
)
	local data = {
		userCloudPath = userCloudPath,
		userCloudFilename = userCloudFilename,
		groupId = groupId,
		groupTreeId = groupTreeId,
		groupFilename = groupFilename,
		groupFileAcl = groupFileAcl,
		overwriteIfPresent = overwriteIfPresent,
	}
	self.client:sendRequest(SERVICE, OPS.MOVE_USER_TO_GROUP_FILE, data, callback)
end

return GroupFile

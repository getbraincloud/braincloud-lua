--- Test_S3Handling.lua
--- Server integration tests for S3Handling service
local TestUtils = require("tests.shared")


local client = nil

local function allowedFailure(res)
	if not res or not res.status then
		return false
	end

	local okCodes = {
		[client.reasonCodes.FILE_DOES_NOT_EXIST] = true,
	}

	return okCodes[res.reason_code] == true
end

return TestUtils.buildRunner("S3Handling", nil, function(runnerClient)
	client = runnerClient
	local s3 = client.s3Handling
	assert(s3, "S3Handling module missing")

	--- example placeholders; replace with valid categories/file details for meaningful tests
	local exampleCategory = "test"
	local exampleFileDetails = { { fileId = "example-file-1", md5 = "" } }
	local exampleFileId = "3a42657c-5101-45de-90bf-f350eaca2505"

	local tests = {
		{
			name = "GetUpdatedFiles",
			fn = function()
				local s, res = TestUtils.await("GetUpdatedFiles", function(cb)
					s3:getUpdatedFiles(exampleCategory, exampleFileDetails, cb)
				end)
				assert(res ~= nil, "GetUpdatedFiles did not return a response")
				assert(res.data.fileDetails, "FileDetails missing in GetUpdatedFiles response")
			end,
		},

		{
			name = "GetFileList",
			fn = function()
				local s, res = TestUtils.await("GetFileList", function(cb)
					s3:getFileList(exampleCategory, cb)
				end)
				assert(res ~= nil, "GetFileList did not return a response")
				assert(res.data.fileDetails, "FileDetails missing in GetUpdatedFiles response")
			end,
		},

		{
			name = "GetCDNUrl",
			fn = function()
				local s, res = TestUtils.await("GetCDNUrl", function(cb)
					s3:getCDNUrl(exampleFileId, cb)
				end)
				assert(res ~= nil, "GetCDNUrl did not return a response")
				assert(s or allowedFailure(res), "Unexpected GetCDNUrl failure")
			end,
		},
	}

	return tests
end)

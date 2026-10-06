--- Test_GroupFile.lua
--- Server integration tests for GroupFile service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("GroupFile", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")
	local groupFile = client.groupFile
	assert(groupFile, "GroupFile module missing")

	--- Example placeholders; replace with real group/file ids for meaningful tests
	local exampleGroupId = "example-group-id"
	local exampleFileId = "example-file-id"

	local tests = {
		{
			name = "GetFileInfo",
			fn = function()
				local s, res = TestUtils.await("GetFileInfo", function(cb)
					groupFile:getFileInfo(exampleGroupId, exampleFileId, cb)
				end)
				assert(res ~= nil, "GetFileInfo did not return a response")
			end,
		},

		{
			name = "GetFileInfoSimple",
			fn = function()
				local s, res = TestUtils.await("GetFileInfoSimple", function(cb)
					groupFile:getFileInfoSimple(exampleGroupId, "/test", "testfile.txt", cb)
				end)
				assert(res ~= nil, "GetFileInfoSimple did not return a response")
			end,
		},

		{
			name = "GetCDNUrl",
			fn = function()
				local s, res = TestUtils.await("GetCDNUrl", function(cb)
					groupFile:getCDNUrl(exampleGroupId, exampleFileId, cb)
				end)
				assert(res ~= nil, "GetCDNUrl did not return a response")
			end,
		},

		{
			name = "GetFileList",
			fn = function()
				local s, res = TestUtils.await("GetFileList", function(cb)
					groupFile:getFileList(exampleGroupId, "/test", false, cb)
				end)
				assert(res ~= nil, "GetFileList did not return a response")
			end,
		},

		{
			name = "CheckFilenameExists",
			fn = function()
				local s, res = TestUtils.await("CheckFilenameExists", function(cb)
					groupFile:checkFilenameExists(exampleGroupId, "/test", "testfile.txt", cb)
				end)
				assert(res ~= nil, "CheckFilenameExists did not return a response")
			end,
		},

		{
			name = "CheckFullpathFilenameExists",
			fn = function()
				local s, res = TestUtils.await("CheckFullpathFilenameExists", function(cb)
					groupFile:checkFullpathFilenameExists(exampleGroupId, "/test/testfile.txt", cb)
				end)
				assert(res ~= nil, "CheckFullpathFilenameExists did not return a response")
			end,
		},
	}

	return tests
end)

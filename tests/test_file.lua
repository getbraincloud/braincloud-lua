--- Test_File.lua
--- Server integration smoke tests for File service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("File", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")
	local file = client.file
	assert(file, "File module missing")

	local tests = {
		{
			name = "PrepareUserUpload",
			fn = function()
				local s, res = TestUtils.await("PrepareUserUpload", function(cb)
					file:prepareUserUpload("/test", "testfile.txt", true, true, 10, cb)
				end)
				assert(res ~= nil, "PrepareUserUpload did not return a response")
			end,
		},

		{
			name = "ListUserFiles",
			fn = function()
				local s, res = TestUtils.await("ListUserFiles", function(cb)
					file:listUserFiles("/test", false, cb)
				end)
				assert(res ~= nil, "ListUserFiles did not return a response")
			end,
		},

		{
			name = "GetCDNUrl",
			fn = function()
				local s, res = TestUtils.await("GetCDNUrl", function(cb)
					file:getCDNUrl("/test", "testfile.txt", cb)
				end)
				assert(res ~= nil, "GetCDNUrl did not return a response")
			end,
		},

		{
			name = "UploadFileFromMemory",
			fn = function()
				local s, res = TestUtils.await("UploadFileFromMemory", function(cb)
					file:uploadFileFromMemory("/test", "testfile.txt", true, true, "hello", cb)
				end)
				assert(res ~= nil, "UploadFileFromMemory did not return a response")
			end,
		},
	}

	return tests
end)

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("GlobalFile", nil, function(client)
	local globalFile = client.globalFile
	assert(globalFile, "GlobalFile module missing")
	-- same portal-seeded file as C# TestGlobalFile
	local uploadedFileName = "testGlobalFile.png"
	local uploadedFilePath = "/fname/"
	local uploadedFileId = "ed2d2924-4650-4a88-b095-94b75ce9aa18"

	return {

		{
			name = "GetFileInfoSimple",
			fn = function()
				local s, res = TestUtils.await("GetFileInfoSimple", function(cb)
					globalFile:getFileInfoSimple(uploadedFilePath, uploadedFileName, cb)
				end)

				TestUtils.assertOk("GetFileInfoSimple", s, res)
				assert(res.data.fileDetails and res.data.fileDetails.fileId, "Missing fileId")
				uploadedFileId = res.data.fileDetails.fileId
			end,
		},

		{
			name = "GetFileInfo",
			fn = function()
				local s, res = TestUtils.await("GetFileInfo", function(cb)
					globalFile:getFileInfo(uploadedFileId, cb)
				end)

				TestUtils.assertOk("GetFileInfo", s, res)
				assert(res.data.fileDetails and res.data.fileDetails.fileId, "Missing fileId")
			end,
		},
		{
			name = "GetGlobalCDNUrl",
			fn = function()
				local s, res = TestUtils.await("GetGlobalCDNUrl", function(cb)
					globalFile:getGlobalCDNUrl(uploadedFileId, cb)
				end)

				TestUtils.assertOk("GetGlobalCDNUrl", s, res)
				assert(res.data.cdnUrl, "Missing cdnUrl")
			end,
		},

		{
			name = "GetGlobalFileList",
			fn = function()
				local s, res = TestUtils.await("GetGlobalFileList", function(cb)
					globalFile:getGlobalFileList(uploadedFilePath, true, cb)
				end)

				TestUtils.assertOk("GetGlobalFileList", s, res)
				assert(res.data.fileList, "Missing fileList")
			end,
		},
	}
end)

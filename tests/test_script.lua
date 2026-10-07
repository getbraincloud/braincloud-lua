--- Test_Script.lua
--- Server integration smoke tests for Script service

local TestUtils = require("tests.shared")

local client = nil

local function allowedFailure(res)
	if not res or not res.status then
		return false
	end

	local okCodes = {
		[client.reasonCodes.INVALID_PEER_CODE] = true,
		[client.reasonCodes.MISSING_GAME_PARENT] = true,
	}

	return okCodes[res.reason_code] == true
end

return TestUtils.buildRunner("Script", nil, function(runnerClient)
	client = runnerClient
	local scriptService = client.script
	assert(scriptService, "Script module missing")

	local jobId = nil
	local scriptName = "testScript"
	local tests = {
		{
			name = "RunScript",
			fn = function()
				local s, res = TestUtils.await("RunScript", function(cb)
					scriptService:runScript(scriptName, { hello = "world" }, cb)
				end)
				TestUtils.assertOk("RunScript", s, res)
				-- testScript returns an empty response; the script itself must have succeeded
				assert(res.data.success == true, "RunScript: script did not succeed")
			end,
		},

		{
			name = "ScheduleRunScriptMillisUTC",
			fn = function()
				local startMillis = (os.time() + 60) * 1000 --- 1 minute from now
				local s, res = TestUtils.await("ScheduleRunScriptMillisUTC", function(cb)
					scriptService:scheduleRunScriptMillisUTC(scriptName, { foo = "bar" }, startMillis, cb)
				end)
				assert(res ~= nil, "ScheduleRunScriptMillisUTC did not return a response")
				assert(res.data.scriptName, "ScheduleRunScriptMillisUTC did not return a scriptName")
			end,
		},

		{
			name = "ScheduleRunScriptMinutes",
			fn = function()
				local s, res = TestUtils.await("ScheduleRunScriptMinutes", function(cb)
					scriptService:scheduleRunScriptMinutes(scriptName, { a = 1 }, 1, cb)
				end)
				assert(res ~= nil, "ScheduleRunScriptMinutes did not return a response")
				assert(res.data.scriptName, "ScheduleRunScriptMinutes did not return a scriptName")
				assert(res.data.jobId, "ScheduleRunScriptMinutes did not return a jobId")
				jobId = res.data.jobId
			end,
		},

		{
			name = "RunParentScript",
			fn = function()
				local s, res = TestUtils.await("RunParentScript", function(cb)
					scriptService:runParentScript(scriptName, { p = true }, "parent", cb)
				end)
				assert(res ~= nil, "RunParentScript did not return a response")
				assert(s or allowedFailure(res), "Unexpected RunParentScript failure")
			end,
		},

		{
			name = "CancelScheduledScript",
			fn = function()
				--- Attempt cancel with placeholder job id; expect a response object (may be an error)
				local s, res = TestUtils.await("CancelScheduledScript", function(cb)
					scriptService:cancelScheduledScript(jobId, cb)
				end)
				assert(res ~= nil, "CancelScheduledScript did not return a response")
				assert(res.data.scriptName, "ScheduleRunScriptMinutes did not return a scriptName")
			end,
		},

		{
			name = "GetRunningOrQueuedCloudScripts",
			fn = function()
				local s, res = TestUtils.await("GetRunningOrQueuedCloudScripts", function(cb)
					scriptService:getRunningOrQueuedCloudScripts(cb)
				end)
				assert(res ~= nil, "GetRunningOrQueuedCloudScripts did not return a response")
				assert(res.data.runningOrQueuedJobs, "GetRunningOrQueuedCloudScripts did not return a scriptName")
			end,
		},

		{
			name = "GetScheduledCloudScripts",
			fn = function()
				local startMillis = (os.time() - 86400) * 1000 --- since yesterday
				local s, res = TestUtils.await("GetScheduledCloudScripts", function(cb)
					scriptService:getScheduledCloudScripts(startMillis, cb)
				end)
				assert(res ~= nil, "GetScheduledCloudScripts did not return a response")
				assert(res.data.scheduledJobs, "GetScheduledCloudScripts did not return a scriptName")
			end,
		},

		{
			name = "RunPeerScript",
			fn = function()
				local peer = TestUtils.ids.peerName or "peerapp"
				local s, res = TestUtils.await("RunPeerScript", function(cb)
					scriptService:runPeerScript("TestPeerScriptPublic", { x = 2 }, peer, cb)
				end)
				assert(res ~= nil, "RunPeerScript did not return a response")
				assert(s or allowedFailure(res), "Unexpected RunPeerScript failure")
			end,
		},

		{
			name = "RunPeerScriptAsync",
			fn = function()
				local peer = TestUtils.ids.peerName or "peerapp"
				local s, res = TestUtils.await("RunPeerScriptAsync", function(cb)
					scriptService:runPeerScriptAsync("TestPeerScriptPublic", { x = 3 }, peer, cb)
				end)
				assert(res ~= nil, "RunPeerScriptAsync did not return a response")
				assert(s or allowedFailure(res), "Unexpected RunPeerScriptAsync failure")
			end,
		},
	}
	return tests
end)

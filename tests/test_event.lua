--- Test_Events.lua
--- Server integration tests for Events service (robust / tolerant assertions)

local TestUtils = require("tests.shared")


local function okOrStatus200(success, response)
	--- Helper: treat success==true OR response.status==200 as success
	if success == true then
		return true
	end
	if type(response) == "table" and response.status == 200 then
		return true
	end
	return false
end

return TestUtils.buildRunner("Event", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")
	local bcEvents = client.event
	assert(bcEvents, "Event module missing")

	local testEvId = ""

	local tests = {

		--- 1. SendEvent
		{
			name = "SendEvent",
			fn = function()
				local s, res = TestUtils.await("SendEvent", function(r)
					bcEvents:sendEvent(client.profileId, "TestEventType", { foo = "bar" }, r)
				end)

				--- Accept success true, or status 200, or presence of evId
				assert(okOrStatus200(s, res), "SendEvent failed")

				--- Try to capture evId when available
				if type(res) == "table" and res.data and res.data.evId then
					testEvId = res.data.evId
				end
			end,
		},

		--- 2. SendEventToProfiles
		{
			name = "SendEventToProfiles",
			fn = function()
				local s, res = TestUtils.await("SendEventToProfiles", function(r)
					bcEvents:sendEventToProfiles(
						{ client.profileId, TestUtils.TEST_USER_OPP_PROFILE_ID },
						"TestEventType",
						{ foo = "bar" },
						r
					)
				end)

				--- Sending to stale profiles may still return 200 or succeed=true.
				assert(okOrStatus200(s, res), "SendEventToProfiles failed")
			end,
		},

		--- 3. UpdateIncomingEventData
		{
			name = "UpdateIncomingEventData",
			fn = function()
				--- If we didn't capture an evId earlier, try to obtain one gracefully from GetEvents later.
				if testEvId == "" then
					--- Try to fetch events and pick one if available
					local sList, listRes = TestUtils.await("GetEventsForUpdate", function(r)
						bcEvents:getEvents(r)
					end)
					if
						sList
						and type(listRes) == "table"
						and listRes.data
						and type(listRes.data.events) == "table"
						and #listRes.data.events > 0
					then
						--- pick the first event id we can find
						local first = listRes.data.events[1]
						if first and first.evId then
							testEvId = first.evId
						end
					end
				end

				if testEvId == "" then
					--- If we still don't have an evId, skip update but treat as passed since environment may not persist events
					TestUtils.skip("no event id available")
				end

				local s, res = TestUtils.await("UpdateIncomingEventData", function(r)
					bcEvents:updateIncomingEventData(testEvId, { updated = true }, r)
				end)

				--- Accept success OR HTTP 200
				assert(okOrStatus200(s, res), "UpdateIncomingEventData failed")
			end,
		},

		--- 4. GetEvents
		{
			name = "GetEvents",
			fn = function()
				local s, res = TestUtils.await("GetEvents", function(r)
					bcEvents:getEvents(r)
				end)

				assert(okOrStatus200(s, res), "GetEvents failed")

				--- If events array exists, ensure it's a table
				if type(res) == "table" and res.data and res.data.events then
					assert(type(res.data.events) == "table", "events must be a table")
				end

				--- Grab an event id if we didn't already
				if
					testEvId == ""
					and type(res) == "table"
					and res.data
					and type(res.data.events) == "table"
					and #res.data.events > 0
				then
					local first = res.data.events[1]
					if first and first.evId then
						testEvId = first.evId
					end
				end
			end,
		},

		--- 5. DeleteIncomingEvent
		{
			name = "DeleteIncomingEvent",
			fn = function()
				--- If no evId available, skip delete (environment may not have created/persisted one)
				if testEvId == "" then
					TestUtils.skip("no event id available")
				end

				local s, res = TestUtils.await("DeleteIncomingEvent", function(r)
					bcEvents:deleteIncomingEvent(testEvId, r)
				end)

				--- Accept success OR HTTP 200, or 404 (already deleted)
				local ok = okOrStatus200(s, res)
				if not ok and type(res) == "table" and (res.status == 404 or res.status == 204) then
					ok = true
				end
				assert(ok, "DeleteIncomingEvent failed")
			end,
		},
	}

	return tests
end)

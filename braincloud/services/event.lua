local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Event = {}
Event.__index = Event

local SERVICE = "event"

local OPS = {
	SEND = "SEND",
	SEND_EVENT_TO_PROFILES = "SEND_EVENT_TO_PROFILES",
	UPDATE_EVENT_DATA = "UPDATE_EVENT_DATA",
	UPDATE_EVENT_DATA_IF_EXISTS = "UPDATE_EVENT_DATA_IF_EXISTS",
	DELETE_INCOMING = "DELETE_INCOMING",
	DELETE_SENT = "DELETE_SENT",
	GET_EVENTS = "GET_EVENTS",
	DELETE_INCOMING_EVENTS = "DELETE_INCOMING_EVENTS",
	DELETE_INCOMING_EVENTS_OLDER_THAN = "DELETE_INCOMING_EVENTS_OLDER_THAN",
	DELETE_INCOMING_EVENTS_BY_TYPE_OLDER_THAN = "DELETE_INCOMING_EVENTS_BY_TYPE_OLDER_THAN",
}


--- Constructor

function Event.new(baseClient)
	local self = setmetatable({}, Event)
	self.client = baseClient
	return self
end


--- Send Event

--- Sends an event to the designated user id with the attached json data.
--- Any events that have been sent to a user will show up in their
--- incoming event mailbox. If the recordLocally flag is set to true,
--- a copy of this event (with the exact same event id) will be stored
--- in the sending user's "sent" event mailbox.
--- Note that the list of sent and incoming events for a user is returned
--- in the "ReadPlayerState" call (in the BrainCloudPlayer module).
--- Service Name - event
--- Service Operation - SEND
--- @param toProfileId The id of the user who is being sent the event
--- @param eventType The user-defined type of the event.
--- @param jsonEventData The user-defined data for this event encoded in JSON.
--- @param callback The method to be invoked when the server response is received
function Event:sendEvent(toProfileId, eventType, eventData, callback)
	local data = {
		toId = toProfileId,
		eventType = eventType,
		eventData = eventData,
	}
	self.client:sendRequest(SERVICE, OPS.SEND, data, callback)
end


--- Send Event To Multiple Profiles

--- Sends an event to multiple users with the attached json data.
-- Service Name - event
-- Service Operation - SEND_EVENT_TO_PROFILES
-- 
-- @param toIds The profile ids of the users to send the event
-- @param eventType The user-defined type of the event
-- @param eventData The user-defined data for this event encoded in JSON
-- @param callback The method to be invoked when the server response is received
-- 
function Event:sendEventToProfiles(toIds, eventType, eventData, callback)
	local data = {
		toIds = toIds,
		eventType = eventType,
		eventData = eventData,
	}
	self.client:sendRequest(SERVICE, OPS.SEND_EVENT_TO_PROFILES, data, callback)
end


--- Update Incoming Event

--- Updates an event in the user's incoming event mailbox.
--- Service Name - event
--- Service Operation - UPDATE_EVENT_DATA
--- @param evId The event id
--- @param jsonEventData The user-defined data for this event encoded in JSON.
--- @param callback The method to be invoked when the server response is received
function Event:updateIncomingEventData(evId, eventData, callback)
	local data = {
		evId = evId,
		eventData = eventData,
	}
	self.client:sendRequest(SERVICE, OPS.UPDATE_EVENT_DATA, data, callback)
end


--- Update Incoming Event If Exists

--- Updates an event in the user's incoming event mailbox.
--- Returns the same data as updateIncomingEventData, but returns null instead of an error if none exists.
--- Service Name - event
--- Service Operation - UPDATE_EVENT_DATA
--- @param evId The event id
--- @param jsonEventData The user-defined data for this event encoded in JSON.
--- @param callback The method to be invoked when the server response is received
function Event:updateIncomingEventDataIfExists(evId, eventData, callback)
	local data = {
		evId = evId,
		eventData = eventData,
	}
	self.client:sendRequest(SERVICE, OPS.UPDATE_EVENT_DATA_IF_EXISTS, data, callback)
end


--- Delete Incoming Event

--- Delete an event out of the user's incoming mailbox.
--- Service Name - event
--- Service Operation - DELETE_INCOMING
--- @param evId The event id
--- @param callback The method to be invoked when the server response is received
function Event:deleteIncomingEvent(evId, callback)
	local data = { evId = evId }
	self.client:sendRequest(SERVICE, OPS.DELETE_INCOMING, data, callback)
end


--- Get Events

--- Get the events currently queued for the user.
--- Service Name - event
--- Service Operation - GET_EVENTS
--- @param callback The method to be invoked when the server response is received
function Event:getEvents(callback)
	self.client:sendRequest(SERVICE, OPS.GET_EVENTS, nil, callback)
end


--- Delete Incoming Events (Multiple)

--- Delete a list of events out of the user's incoming mailbox.
--- Service Name - event
--- Service Operation - DELETE_INCOMING_EVENTS
--- @param eventIds Collection of event ids
--- @param callback The method to be invoked when the server response is received
function Event:deleteIncomingEvents(evIds, callback)
	local data = { evIds = evIds }
	self.client:sendRequest(SERVICE, OPS.DELETE_INCOMING_EVENTS, data, callback)
end


--- Delete Incoming Events Older Than

--- Delete any events older than the given date out of the user's incoming mailbox.
--- Service Name - event
--- Service Operation - DELETE_INCOMING_EVENTS_OLDER_THAN
--- @param dateMillis createdAt cut-off time whereby older events will be deleted (In UTC since Epoch)
--- @param callback The method to be invoked when the server response is received
function Event:deleteIncomingEventsOlderThan(dateMillis, callback)
	local data = { dateMillis = dateMillis }
	self.client:sendRequest(SERVICE, OPS.DELETE_INCOMING_EVENTS_OLDER_THAN, data, callback)
end


--- Delete Incoming Events By Type Older Than

--- Delete any events of the given type older than the given date out of the user's incoming mailbox.
--- Service Name - event
--- Service Operation - DELETE_INCOMING_EVENTS_BY_TYPE_OLDER_THAN
--- @param eventType The user-defined type of the event
--- @param dateMillis createdAt cut-off time whereby older events will be deleted (In UTC since Epoch)
--- @param callback The method to be invoked when the server response is received
function Event:deleteIncomingEventsByTypeOlderThan(eventType, dateMillis, callback)
	local data = {
		eventType = eventType,
		dateMillis = dateMillis,
	}
	self.client:sendRequest(SERVICE, OPS.DELETE_INCOMING_EVENTS_BY_TYPE_OLDER_THAN, data, callback)
end

return Event

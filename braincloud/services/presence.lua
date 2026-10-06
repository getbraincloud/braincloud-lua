local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")
local Presence = {}
Presence.__index = Presence

local SERVICE = "presence"

local OPS = {
	FORCE_PUSH = "FORCE_PUSH",
	GET_PRESENCE_OF_FRIENDS = "GET_PRESENCE_OF_FRIENDS",
	GET_PRESENCE_OF_GROUP = "GET_PRESENCE_OF_GROUP",
	GET_PRESENCE_OF_USERS = "GET_PRESENCE_OF_USERS",
	REGISTER_LISTENERS_FOR_FRIENDS = "REGISTER_LISTENERS_FOR_FRIENDS",
	REGISTER_LISTENERS_FOR_GROUP = "REGISTER_LISTENERS_FOR_GROUP",
	REGISTER_LISTENERS_FOR_PROFILES = "REGISTER_LISTENERS_FOR_PROFILES",
	SET_VISIBILITY = "SET_VISIBILITY",
	STOP_LISTENING = "STOP_LISTENING",
	UPDATE_ACTIVITY = "UPDATE_ACTIVITY",
}

--- Creates a new Presence service instance.
--- @param baseClient table The brainCloud client instance.
--- @return Presence
function Presence.new(baseClient)
	local self = setmetatable({}, Presence)
	self.client = baseClient
	return self
end

--- Force an RTT presence update to all listeners of the caller.
-- Service Name - presence
-- Service Operation - FORCE_PUSH
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function Presence:forcePush(callback)
	self.client:sendRequest(SERVICE, OPS.FORCE_PUSH, {}, callback)
end

--- Gets the presence data for the given <platform>. Can be one of "all",
-- "brainCloud", or "facebook". Will not include offline profiles
-- unless <includeOffline> is set to true.
-- 
-- 
function Presence:getPresenceOfFriends(platform, includeOffline, callback)
	local data = { platform = platform, includeOffline = includeOffline }
	self.client:sendRequest(SERVICE, OPS.GET_PRESENCE_OF_FRIENDS, data, callback)
end

--- Gets the presence data for the given <groupId>. Will not include
-- offline profiles unless <includeOffline> is set to true.
-- 
-- 
function Presence:getPresenceOfGroup(groupId, includeOffline, callback)
	local data = { groupId = groupId, includeOffline = includeOffline }
	self.client:sendRequest(SERVICE, OPS.GET_PRESENCE_OF_GROUP, data, callback)
end

--- Gets the presence data for the given <profileIds>. Will not include
-- offline profiles unless <includeOffline> is set to true.
-- 
-- 
function Presence:getPresenceOfUsers(profileIds, includeOffline, callback)
	local data = { profileIds = Utils.array(profileIds), includeOffline = includeOffline }
	self.client:sendRequest(SERVICE, OPS.GET_PRESENCE_OF_USERS, data, callback)
end

--- Registers the caller for RTT presence updates from friends for the
-- given <platform>. Can be one of "all", "brainCloud", or "facebook".
-- If <bidirectional> is set to true, then also registers the targeted
-- users for presence updates from the caller.
-- 
-- 
function Presence:registerListenersForFriends(platform, bidirectional, callback)
	local data = { platform = platform, bidirectional = bidirectional }
	self.client:sendRequest(SERVICE, OPS.REGISTER_LISTENERS_FOR_FRIENDS, data, callback)
end

--- Registers the caller for RTT presence updates from the members of
-- the given <groupId>. Caller must be a member of said group. If
-- <bidirectional> is set to true, then also registers the targeted
-- users for presence updates from the caller.
-- 
-- 
function Presence:registerListenersForGroup(groupId, bidirectional, callback)
	local data = { groupId = groupId, bidirectional = bidirectional }
	self.client:sendRequest(SERVICE, OPS.REGISTER_LISTENERS_FOR_GROUP, data, callback)
end

--- Registers the caller for RTT presence updates for the given
-- <profileIds>. If <bidirectional> is set to true, then also registers
-- the targeted users for presence updates from the caller.
-- 
-- 
function Presence:registerListenersForProfiles(profileIds, bidriectional, callback)
	local data = { profileIds = Utils.array(profileIds), bidriectional = bidriectional }
	self.client:sendRequest(SERVICE, OPS.REGISTER_LISTENERS_FOR_PROFILES, data, callback)
end

--- Update the presence data visible field for the caller.
-- 
-- 
function Presence:setVisibility(visible, callback)
	local data = { visible = visible }
	self.client:sendRequest(SERVICE, OPS.SET_VISIBILITY, data, callback)
end

--- Stops the caller from receiving RTT presence updates. Does not
-- affect the broadcasting of *their* presence updates to other
-- listeners.
-- 
-- 
function Presence:stopListening(callback)
	self.client:sendRequest(SERVICE, OPS.STOP_LISTENING, {}, callback)
end

--- Update the presence data activity field for the caller.
-- 
-- 
function Presence:updateActivity(activity, callback)
	local data = { activity = activity }
	self.client:sendRequest(SERVICE, OPS.UPDATE_ACTIVITY, data, callback)
end

return Presence

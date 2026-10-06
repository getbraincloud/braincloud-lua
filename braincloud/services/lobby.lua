local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")
local json = require(ROOT .. ".lib.json")

local Utils = require(ROOT .. ".util")

local Lobby = {}
Lobby.__index = Lobby

local SERVICE = "lobby"

local OPS = {
	CREATE_LOBBY = "CREATE_LOBBY",
	CREATE_LOBBY_WITH_PING_DATA = "CREATE_LOBBY_WITH_PING_DATA",
	FIND_LOBBY = "FIND_LOBBY",
	FIND_LOBBY_WITH_PING_DATA = "FIND_LOBBY_WITH_PING_DATA",
	FIND_OR_CREATE_LOBBY = "FIND_OR_CREATE_LOBBY",
	FIND_OR_CREATE_LOBBY_WITH_PING_DATA = "FIND_OR_CREATE_LOBBY_WITH_PING_DATA",
	GET_LOBBY_DATA = "GET_LOBBY_DATA",
	LEAVE_LOBBY = "LEAVE_LOBBY",
	JOIN_LOBBY = "JOIN_LOBBY",
	JOIN_LOBBY_WITH_PING_DATA = "JOIN_LOBBY_WITH_PING_DATA",
	REMOVE_MEMBER = "REMOVE_MEMBER",
	SEND_SIGNAL = "SEND_SIGNAL",
	SWITCH_TEAM = "SWITCH_TEAM",
	UPDATE_READY = "UPDATE_READY",
	UPDATE_SETTINGS = "UPDATE_SETTINGS",
	CANCEL_FIND_REQUEST = "CANCEL_FIND_REQUEST",
	GET_REGIONS_FOR_LOBBIES = "GET_REGIONS_FOR_LOBBIES",
	PING_REGIONS = "PING_REGIONS",
	GET_LOBBY_INSTANCES = "GET_LOBBY_INSTANCES",
	GET_LOBBY_INSTANCES_WITH_PING_DATA = "GET_LOBBY_INSTANCES_WITH_PING_DATA",
	CREATE_LOBBY_WITH_CONFIG = "CREATE_LOBBY_WITH_CONFIG",
	CREATE_LOBBY_WITH_CONFIG_AND_PING_DATA = "CREATE_LOBBY_WITH_CONFIG_AND_PING_DATA",
}

local MAX_PING_CALLS = 4
local NUM_PING_CALLS_IN_PARALLEL = 2

--- Creates a new Lobby instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return Lobby
function Lobby.new(brainCloudClient)
	local self = setmetatable({}, Lobby)
	self.client = brainCloudClient
	self._pingData = nil
	self._regionPingData = nil
	self._regionsToPing = {}
	self._targetPingCount = 0
	return self
end

local attachPingDataAndSend

--- Creates a new lobby.
-- Sends LOBBY_JOSUCCESS message to the user, with full copy of lobby data Sends LOBBY_MEMBER_JOINED to all lobby members, with copy of member data
-- Service Name - lobby
-- Service Operation - CREATE_LOBBY
-- 
-- @param lobbyType The type of lobby to look for. Lobby types are defined in the portal.
-- @param rating The skill rating to use for finding the lobby. Provided as a separate parameter because it may not exactly match the user's rating (especially in cases where parties are involved).
-- @param otherUserCxIds Array of other users (i.e. party members) to add to the lobby as well. Will constrain things so that only lobbies with room for all players will be considered.
-- @param isReady Initial ready-status of this user.
-- @param extraJson Initial extra-data about this user.
-- @param teamCode Preferred team for this user, if applicable. Send "" or null for automatic assignment.
-- @param settings Configuration data for the room.
-- 
function Lobby:createLobby(lobbyType, rating, otherUserCxIds, isReady, extraJson, teamCode, settings, callback)
	local data = {
		lobbyType = lobbyType,
		rating = rating,
		otherUserCxIds = Utils.array(otherUserCxIds),
		isReady = isReady,
		extraJson = Utils.emptyFix(extraJson),
		teamCode = teamCode,
		settings = Utils.emptyFix(settings),
	}

	self.client:sendRequest(SERVICE, OPS.CREATE_LOBBY, data, callback)
end

--- Creates a new lobby. Uses attached ping data to resolve best location. GetRegionsForLobbies and PingRegions must be successfully responded to.
-- Sends LOBBY_JOSUCCESS message to the user, with full copy of lobby data Sends LOBBY_MEMBER_JOINED to all lobby members, with copy of member data
-- Service Name - lobby
-- Service Operation - CREATE_LOBBY_WITH_PING_DATA
-- 
-- @param lobbyType The type of lobby to look for. Lobby types are defined in the portal.
-- @param rating The skill rating to use for finding the lobby. Provided as a separate parameter because it may not exactly match the user's rating (especially in cases where parties are involved).
-- @param otherUserCxIds Array of other users (i.e. party members) to add to the lobby as well. Will constrain things so that only lobbies with room for all players will be considered.
-- @param isReady Initial ready-status of this user.
-- @param extraJson Initial extra-data about this user.
-- @param teamCode Preferred team for this user, if applicable. Send "" or null for automatic assignment.
-- @param settings Configuration data for the room.
-- 
function Lobby:createLobbyWithPingData(
	lobbyType,
	rating,
	otherUserCxIds,
	isReady,
	extraJson,
	teamCode,
	settings,
	callback
)
	local data = {
		lobbyType = lobbyType,
		rating = rating,
		otherUserCxIds = Utils.array(otherUserCxIds),
		isReady = isReady,
		extraJson = Utils.emptyFix(extraJson),
		teamCode = teamCode,
		settings = Utils.emptyFix(settings),
	}

	attachPingDataAndSend(self, data, OPS.CREATE_LOBBY_WITH_PING_DATA, callback)
end

--- Creates a new lobby with server config overrides.
-- Service Name - lobby
-- Service Operation - CREATE_LOBBY_WITH_CONFIG
-- 
-- @param lobbyType The type of lobby to look for. Lobby types are defined in the portal.
-- @param rating The skill rating to use for finding the lobby.
-- @param otherUserCxIds Array of other users (i.e. party members) to add to the lobby as well.
-- @param isReady Initial ready-status of this user.
-- @param extraJson Initial extra-data about this user.
-- @param teamCode Preferred team for this user, if applicable. Send "" or null for automatic assignment.
-- @param settings Configuration data for the room.
-- @param jsonConfigOverrides Server config overrides for the lobby.
-- 
function Lobby:createLobbyWithConfig(lobbyType, rating, otherUserCxIds, isReady, extraJson, teamCode, settings, configOverrides, callback)
	local data = {
		lobbyType = lobbyType,
		rating = rating,
		otherUserCxIds = Utils.array(otherUserCxIds),
		isReady = isReady,
		extraJson = Utils.emptyFix(extraJson),
		teamCode = teamCode,
		settings = Utils.emptyFix(settings),
		configOverrides = Utils.emptyFix(configOverrides),
	}

	self.client:sendRequest(SERVICE, OPS.CREATE_LOBBY_WITH_CONFIG, data, callback)
end

--- Creates a new lobby with server config overrides. Uses attached ping data to resolve best location.
-- Service Name - lobby
-- Service Operation - CREATE_LOBBY_WITH_CONFIG_AND_PING_DATA
-- 
-- @param lobbyType The type of lobby to look for. Lobby types are defined in the portal.
-- @param rating The skill rating to use for finding the lobby.
-- @param otherUserCxIds Array of other users (i.e. party members) to add to the lobby as well.
-- @param isReady Initial ready-status of this user.
-- @param extraJson Initial extra-data about this user.
-- @param teamCode Preferred team for this user, if applicable. Send "" or null for automatic assignment.
-- @param settings Configuration data for the room.
-- @param jsonConfigOverrides Server config overrides for the lobby.
-- 
function Lobby:createLobbyWithConfigAndPingData(
	lobbyType,
	rating,
	otherUserCxIds,
	isReady,
	extraJson,
	teamCode,
	settings,
	configOverrides,
	callback
)
	local data = {
		lobbyType = lobbyType,
		rating = rating,
		otherUserCxIds = Utils.array(otherUserCxIds),
		isReady = isReady,
		extraJson = Utils.emptyFix(extraJson),
		teamCode = teamCode,
		settings = Utils.emptyFix(settings),
		configOverrides = Utils.emptyFix(configOverrides),
	}

	attachPingDataAndSend(self, data, OPS.CREATE_LOBBY_WITH_CONFIG_AND_PING_DATA, callback)
end

--- Finds a lobby matching the specified parameters. Asynchronous - returns 200 to indicate that matchmaking has started.
-- Service Name - lobby
-- Service Operation - FIND_LOBBY
-- 
-- @param lobbyType The type of lobby to look for. Lobby types are defined in the portal.
-- @param rating The skill rating to use for finding the lobby. Provided as a separate parameter because it may not exactly match the user's rating (especially in cases where parties are involved).
-- @param maxSteps The maximum number of steps to wait when looking for an applicable lobby. Each step is ~5 seconds.
-- @param algo The algorithm to use for increasing the search scope.
-- @param filterJson Used to help filter the list of rooms to consider. Passed to the matchmaking filter, if configured.
-- @param otherUserCxIds Array of other users (i.e. party members) to add to the lobby as well. Will constrain things so that only lobbies with room for all players will be considered.
-- @param isReady Initial ready-status of this user.
-- @param extraJson Initial extra-data about this user.
-- @param teamCode Preferred team for this user, if applicable. Send "" or null for automatic assignment
-- 
function Lobby:findLobby(
	lobbyType,
	rating,
	maxSteps,
	algo,
	filterJson,
	otherUserCxIds,
	isReady,
	extraJson,
	teamCode,
	callback
)
	local data = {
		lobbyType = lobbyType,
		rating = rating,
		maxSteps = maxSteps,
		algo = algo,
		filterJson = filterJson,
		otherUserCxIds = Utils.array(otherUserCxIds),
		isReady = isReady,
		extraJson = Utils.emptyFix(extraJson),
		teamCode = teamCode,
	}

	self.client:sendRequest(SERVICE, OPS.FIND_LOBBY, data, callback)
end

--- Finds a lobby matching the specified parameters. Asynchronous - returns 200 to indicate that matchmaking has started. Uses attached ping data to resolve best location. GetRegionsForLobbies and PingRegions must be successfully responded to.
-- Service Name - lobby
-- Service Operation - FIND_LOBBY_WITH_PING_DATA
-- 
-- @param lobbyType The type of lobby to look for. Lobby types are defined in the portal.
-- @param rating The skill rating to use for finding the lobby. Provided as a separate parameter because it may not exactly match the user's rating (especially in cases where parties are involved).
-- @param maxSteps The maximum number of steps to wait when looking for an applicable lobby. Each step is ~5 seconds.
-- @param algo The algorithm to use for increasing the search scope.
-- @param filterJson Used to help filter the list of rooms to consider. Passed to the matchmaking filter, if configured.
-- @param otherUserCxIds Array of other users (i.e. party members) to add to the lobby as well. Will constrain things so that only lobbies with room for all players will be considered.
-- @param isReady Initial ready-status of this user.
-- @param extraJson Initial extra-data about this user.
-- @param teamCode Preferred team for this user, if applicable. Send "" or null for automatic assignment
-- 
function Lobby:findLobbyWithPingData(
	lobbyType,
	rating,
	maxSteps,
	algo,
	filterJson,
	otherUserCxIds,
	isReady,
	extraJson,
	teamCode,
	callback
)
	local data = {
		lobbyType = lobbyType,
		rating = rating,
		maxSteps = maxSteps,
		algo = algo,
		filterJson = filterJson,
		otherUserCxIds = Utils.array(otherUserCxIds),
		isReady = isReady,
		extraJson = Utils.emptyFix(extraJson),
		teamCode = teamCode,
	}

	attachPingDataAndSend(self, data, OPS.FIND_LOBBY_WITH_PING_DATA, callback)
end

--- Adds the caller to the lobby entry queue and will create a lobby if none are found.
-- Service Name - lobby
-- Service Operation - FIND_OR_CREATE_LOBBY
-- 
-- @param lobbyType The type of lobby to look for. Lobby types are defined in the portal.
-- @param rating The skill rating to use for finding the lobby. Provided as a separate parameter because it may not exactly match the user's rating (especially in cases where parties are involved).
-- @param maxSteps The maximum number of steps to wait when looking for an applicable lobby. Each step is ~5 seconds.
-- @param algo The algorithm to use for increasing the search scope.
-- @param filterJson Used to help filter the list of rooms to consider. Passed to the matchmaking filter, if configured.
-- @param otherUserCxIds Array of other users (i.e. party members) to add to the lobby as well. Will constrain things so that only lobbies with room for all players will be considered.
-- @param settings Configuration data for the room.
-- @param isReady Initial ready-status of this user.
-- @param extraJson Initial extra-data about this user.
-- @param teamCode Preferred team for this user, if applicable. Send "" or null for automatic assignment.
-- 
function Lobby:findOrCreateLobby(
	lobbyType,
	rating,
	maxSteps,
	algo,
	filterJson,
	otherUserCxIds,
	settings,
	isReady,
	extraJson,
	teamCode,
	callback
)
	local data = {
		lobbyType = lobbyType,
		rating = rating,
		maxSteps = maxSteps,
		algo = algo,
		filterJson = filterJson,
		otherUserCxIds = Utils.array(otherUserCxIds),
		settings = settings,
		isReady = isReady,
		extraJson = Utils.emptyFix(extraJson),
		teamCode = teamCode,
	}

	self.client:sendRequest(SERVICE, OPS.FIND_OR_CREATE_LOBBY, data, callback)
end

--- Adds the caller to the lobby entry queue and will create a lobby if none are found. Uses attached ping data to resolve best location. GetRegionsForLobbies and PingRegions must be successfully responded to.
-- Service Name - lobby
-- Service Operation - FIND_OR_CREATE_LOBBY_WITH_PING_DATA
-- 
-- @param lobbyType The type of lobby to look for. Lobby types are defined in the portal.
-- @param rating The skill rating to use for finding the lobby. Provided as a separate parameter because it may not exactly match the user's rating (especially in cases where parties are involved).
-- @param maxSteps The maximum number of steps to wait when looking for an applicable lobby. Each step is ~5 seconds.
-- @param algo The algorithm to use for increasing the search scope.
-- @param filterJson Used to help filter the list of rooms to consider. Passed to the matchmaking filter, if configured.
-- @param otherUserCxIds Array of other users (i.e. party members) to add to the lobby as well. Will constrain things so that only lobbies with room for all players will be considered.
-- @param settings Configuration data for the room.
-- @param isReady Initial ready-status of this user.
-- @param extraJson Initial extra-data about this user.
-- @param teamCode Preferred team for this user, if applicable. Send "" or null for automatic assignment.
-- 
function Lobby:findOrCreateLobbyWithPingData(
	lobbyType,
	rating,
	maxSteps,
	algo,
	filterJson,
	otherUserCxIds,
	settings,
	isReady,
	extraJson,
	teamCode,
	callback
)
	local data = {
		lobbyType = lobbyType,
		rating = rating,
		maxSteps = maxSteps,
		algo = algo,
		filterJson = filterJson,
		otherUserCxIds = Utils.array(otherUserCxIds),
		settings = settings,
		isReady = isReady,
		extraJson = Utils.emptyFix(extraJson),
		teamCode = teamCode,
	}

	attachPingDataAndSend(self, data, OPS.FIND_OR_CREATE_LOBBY_WITH_PING_DATA, callback)
end

--- Returns the data for the specified lobby, including member data.
-- Service Name - lobby
-- Service Operation - GET_LOBBY_DATA
-- 
-- @param lobbyId Id of chosen lobby.
-- 
function Lobby:getLobbyData(lobbyId, callback)
	local data = { lobbyId = lobbyId }
	self.client:sendRequest(SERVICE, OPS.GET_LOBBY_DATA, data, callback)
end

--- Causes the caller to leave the specified lobby. If the user was the owner, a new owner will be chosen. If user was the last member, the lobby will be deleted.
-- Service Name - lobby
-- Service Operation - LEAVE_LOBBY
-- 
-- @param lobbyId Id of chosen lobby.
-- 
function Lobby:leaveLobby(lobbyId, callback)
	local data = { lobbyId = lobbyId }
	self.client:sendRequest(SERVICE, OPS.LEAVE_LOBBY, data, callback)
end

--- Join specified lobby
-- Service Name - lobby
-- Service Operation - JOIN_LOBBY
-- 
-- @param lobbyId Id of the specfified lobby.
-- @param isReady Initial ready-status of this user.
-- @param extraJson Initial extra-data about this user.
-- @param toTeamCode Specified team code.
-- @param otherUserCxIds Array of other users (i.e. party members) to add to the lobby as well. Will constrain things so that only lobbies with room for all players will be considered.
-- 
function Lobby:joinLobby(lobbyId, isReady, extraJson, teamCode, otherUserCxIds, callback)
	local data = {
		lobbyId = lobbyId,
		isReady = isReady,
		extraJson = Utils.emptyFix(extraJson),
		teamCode = teamCode,
		otherUserCxIds = Utils.array(otherUserCxIds),
	}

	self.client:sendRequest(SERVICE, OPS.JOIN_LOBBY, data, callback)
end

--- Join specified lobby. Uses attached ping data to resolve best location. GetRegionsForLobbies and PingRegions must be successfully responded to.
-- Service Name - lobby
-- Service Operation - JOIN_LOBBY_WITH_PING_DATA
-- 
-- @param lobbyId Id of the specfified lobby.
-- @param isReady Initial ready-status of this user.
-- @param extraJson Initial extra-data about this user.
-- @param toTeamCode Specified team code.
-- @param otherUserCxIds Array of other users (i.e. party members) to add to the lobby as well. Will constrain things so that only lobbies with room for all players will be considered.
-- 
function Lobby:joinLobbyWithPingData(lobbyId, isReady, extraJson, teamCode, otherUserCxIds, callback)
	local data = {
		lobbyId = lobbyId,
		isReady = isReady,
		extraJson = Utils.emptyFix(extraJson),
		teamCode = teamCode,
		otherUserCxIds = Utils.array(otherUserCxIds),
	}

	attachPingDataAndSend(self, data, OPS.JOIN_LOBBY_WITH_PING_DATA, callback)
end

--- Evicts the specified user from the specified lobby. The caller must be the owner of the lobby.
-- Service Name - lobby
-- Service Operation - REMOVE_MEMBER
-- 
-- @param lobbyId Id of chosen lobby.
-- @param cxId Specified member to be removed from the lobby.
-- 
function Lobby:removeMember(lobbyId, cxId, callback)
	local data = { lobbyId = lobbyId, cxId = cxId }
	self.client:sendRequest(SERVICE, OPS.REMOVE_MEMBER, data, callback)
end

--- Sends LOBBY_SIGNAL_DATA message to all lobby members.
-- Service Name - lobby
-- Service Operation - SEND_SIGNAL
-- 
-- @param lobbyId Id of chosen lobby.
-- @param signalData Signal data to be sent.
-- 
function Lobby:sendSignal(lobbyId, signalData, callback)
	local data = { lobbyId = lobbyId, signalData = signalData }
	self.client:sendRequest(SERVICE, OPS.SEND_SIGNAL, data, callback)
end

--- Switches to the specified team (if allowed.)
-- Sends LOBBY_MEMBER_UPDATED to all lobby members, with copy of member data
-- Service Name - lobby
-- Service Operation - SWITCH_TEAM
-- 
-- @param lobbyId Id of chosen lobby.
-- @param toTeamCode Specified team code.
-- 
function Lobby:switchTeam(lobbyId, toTeamCode, callback)
	local data = { lobbyId = lobbyId, toTeamCode = toTeamCode }
	self.client:sendRequest(SERVICE, OPS.SWITCH_TEAM, data, callback)
end

--- Updates the ready status and extra json for the given lobby member.
-- Service Name - lobby
-- Service Operation - UPDATE_READY
-- 
-- @param lobbyId The type of lobby to look for. Lobby types are defined in the portal.
-- @param isReady Initial ready-status of this user.
-- @param extraJson Initial extra-data about this user.
-- 
function Lobby:updateReady(lobbyId, isReady, extraJson, callback)
	local data = { lobbyId = lobbyId, isReady = isReady, extraJson = Utils.emptyFix(extraJson) }
	self.client:sendRequest(SERVICE, OPS.UPDATE_READY, data, callback)
end

--- Updates the ready status and extra json for the given lobby member.
-- Service Name - lobby
-- Service Operation - UPDATE_SETTINGS
-- 
-- @param lobbyId Id of the specfified lobby.
-- @param settings Configuration data for the room.
-- 
function Lobby:updateSettings(lobbyId, settings, callback)
	local data = { lobbyId = lobbyId, settings = Utils.emptyFix(settings) }
	self.client:sendRequest(SERVICE, OPS.UPDATE_SETTINGS, data, callback)
end

--- Cancels an active find, join, or search request for lobbies.
--- @param lobbyType The lobby type associated with the request
--- @param entryId The entry identifier returned from matchmaking
--- @param callback The method to be invoked when the server response is received
function Lobby:cancelFindRequest(lobbyType, entryId, callback)
	local data = { lobbyType = lobbyType }
	if entryId then
		data.entryId = entryId
	end
	self.client:sendRequest(SERVICE, OPS.CANCEL_FIND_REQUEST, data, callback)
end

--- Retrieves the region settings for each of the given lobby types. Upon success or afterwards, call pingRegions to start retrieving appropriate data.
-- Service Name - lobby
-- Service Operation - GET_REGIONS_FOR_LOBBIES
-- 
-- @param roomTypes Ids of the lobby types.
-- 
function Lobby:getRegionsForLobbies(lobbyTypes, callback)
	local data = { lobbyTypes = Utils.array(lobbyTypes) }
	self.client:sendRequest(SERVICE, OPS.GET_REGIONS_FOR_LOBBIES, data, function(success, result)
		if success and result and result.data and result.data.regionPingData then
			self._regionPingData = result.data.regionPingData
		end
		if callback then
			callback(success, result)
		end
	end)
end

--- Gets a map keyed by rating of the visible lobby instances matching the given type and rating range.
-- Service Name - lobby
-- Service Operation - GET_LOBBY_INSTANCES
-- 
-- @param lobbyType The type of lobby to look for.
-- @param criteriaJson A JSON string used to describe filter criteria.
-- 
function Lobby:getLobbyInstances(lobbyType, criteriaJson, callback)
	local data = { lobbyType = lobbyType, criteriaJson = criteriaJson }
	self.client:sendRequest(SERVICE, OPS.GET_LOBBY_INSTANCES, data, callback)
end

--- Gets a map keyed by rating of the visible lobby instances matching the given type and rating range.
-- Only lobby instances in the regions that satisfy the ping portion of the criteriaJson (based on the values provided in pingData) will be returned.
-- Service Name - lobby
-- Service Operation - GET_LOBBY_INSTANCES_WITH_PING_DATA
-- 
-- @param lobbyType The type of lobby to look for.
-- @param criteriaJson A JSON string used to describe filter criteria.
-- 
function Lobby:getLobbyInstancesWithPingData(lobbyType, criteriaJson, callback)
	local data = { lobbyType = lobbyType, criteriaJson = criteriaJson }
	attachPingDataAndSend(self, data, OPS.GET_LOBBY_INSTANCES_WITH_PING_DATA, callback)
end

--- Retrieves associated Ping Data averages to be used with all associated <>WithPingData APIs.
-- Call anytime after GetRegionsForLobbies before proceeding.
-- Once that completes, the associated region Ping Data is retrievable via getPingData and all associated <>WithPingData APIs are useable
--
function Lobby:pingRegions(callback)
	local regionPingData = self._regionPingData
	if not regionPingData then
		self.client:defer(function()
			if callback then
				callback(false, {
					status = 400,
					reason_code = 40358,
					status_message = "No Regions to Ping. Please call GetRegionsForLobbies and await the response before calling PingRegions",
					severity = "ERROR",
				})
			end
		end)
		return
	end

	local pingData = {}
	local queue = {}
	for regionName, region in pairs(regionPingData) do
		if region and region.target and region.type == "PING" then
			queue[#queue + 1] = { name = regionName, url = region.target, pings = {} }
		end
	end
	local remaining = #queue
	if remaining == 0 then
		self._pingData = pingData
		self.client:defer(function()
			if callback then
				callback(true, { status = 200, data = pingData })
			end
		end)
		return
	end

	-- average of the fastest MAX_PING_CALLS - 1 pings, like the other clients
	local function regionDone(region)
		table.sort(region.pings)
		local total = 0
		for i = 1, #region.pings - 1 do
			total = total + region.pings[i]
		end
		pingData[region.name] = math.floor(total / (#region.pings - 1) + 0.5)
		self.client:debugLog("[Lobby] ping", region.name, pingData[region.name], "ms")
		remaining = remaining - 1
		if remaining == 0 then
			self._pingData = pingData
			if callback then
				callback(true, { status = 200, data = pingData })
			end
		end
	end

	local nextRegion
	local function pingOnce(region)
		self.client._http:request({ url = region.url, method = "PING", timeout = 2 }, function(code, body)
			local ms = code == 200 and tonumber(body) or 999
			region.pings[#region.pings + 1] = math.min(999, ms)
			if #region.pings < MAX_PING_CALLS then
				pingOnce(region)
			else
				regionDone(region)
				nextRegion()
			end
		end)
	end
	nextRegion = function()
		local region = table.remove(queue, 1)
		if region then
			pingOnce(region)
		end
	end
	for _ = 1, math.min(NUM_PING_CALLS_IN_PARALLEL, #queue) do
		nextRegion()
	end
end

--- Returns the ping data gathered by the last pingRegions call (nil until it completes).
function Lobby:getPingData()
	return self._pingData
end

function attachPingDataAndSend(self, data, operation, callback)
	if self._pingData then
		data.pingData = self._pingData
		self.client:sendRequest(SERVICE, operation, data, callback)
	else
		self.client:defer(function()
			if callback then
				callback(false, {
					status = 400,
					reason_code = 40358,
					status_message = "Required Parameter 'pingData' is missing. Please ensure 'pingData' exists by first calling GetRegionsForLobbies and PingRegions, and waiting for response before proceeding.",
					severity = "ERROR",
				})
			end
		end)
	end
end

return Lobby

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")
local PushNotification = {}
PushNotification.__index = PushNotification

local SERVICE = "pushNotification"

local OPS = {
	DEREGISTER_ALL = "DEREGISTER_ALL",
	DEREGISTER = "DEREGISTER",
	SEND_SIMPLE = "SEND_SIMPLE",
	SEND_RICH = "SEND_RICH",
	SEND_RAW = "SEND_RAW",
	SEND_RAW_TO_GROUP = "SEND_RAW_TO_GROUP",
	SEND_RAW_BATCH = "SEND_RAW_BATCH",
	REGISTER = "REGISTER",
	SEND_NORMALIZED_TO_GROUP = "SEND_NORMALIZED_TO_GROUP",
	SEND_TEMPLATED_TO_GROUP = "SEND_TEMPLATED_TO_GROUP",
	SEND_NORMALIZED = "SEND_NORMALIZED",
	SEND_NORMALIZED_BATCH = "SEND_NORMALIZED_BATCH",
	SCHEDULE_RICH = "SCHEDULE_RICH_NOTIFICATION",
	SCHEDULE_NORMALIZED = "SCHEDULE_NORMALIZED_NOTIFICATION",
	SCHEDULE_RAW = "SCHEDULE_RAW_NOTIFICATION",
}

--- Creates a new PushNotification service instance.
--- @param baseClient table
--- @return PushNotification
function PushNotification.new(baseClient)
	local self = setmetatable({}, PushNotification)
	self.client = baseClient
	return self
end

--- Deregisters all device tokens currently registered to the user.
-- Service Name - pushNotification
-- Service Operation - DEREGISTER_ALL
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function PushNotification:deregisterAllPushNotificationDeviceTokens(callback)
	self.client:sendRequest(SERVICE, OPS.DEREGISTER_ALL, {}, callback)
end

--- Deregisters the given device token from the server to disable this device
--- from receiving push notifications.
--- @param device The device platform being deregistered.
--- @param token The platform-dependent device token needed for push notifications.
--- @param callback The method to be invoked when the server response is received
function PushNotification:deregisterPushNotificationDeviceToken(deviceType, deviceToken, callback)
	local data = { deviceType = deviceType, deviceToken = deviceToken }
	self.client:sendRequest(SERVICE, OPS.DEREGISTER, data, callback)
end

--- Registers the given device token with the server to enable this device
--- to receive push notifications.
--- @param platform The device platform
--- @param deviceToken The platform-dependent device token needed for push notifications.
---        On IOS, this is obtained using the application:didRegisterForRemoteNotificationsWithDeviceToken callback
--- @param callback The method to be invoked when the server response is received
function PushNotification:registerPushNotificationDeviceToken(deviceType, deviceToken, callback)
	if not deviceToken or (type(deviceToken) == "string" and deviceToken:match("^%s*$")) then
		if callback then
			callback(false, { status = 400, reason_code = "INVALID_DEVICE_TOKEN", message = "Invalid device token" })
		end
		return
	end

	local data = { deviceType = deviceType, deviceToken = deviceToken }
	self.client:sendRequest(SERVICE, OPS.REGISTER, data, callback)
end

--- Sends a simple push notification based on the passed in message.
--- NOTE: It is possible to send a push notification to oneself.
--- @param toProfileId The braincloud profileId of the user to receive the notification
--- @param message Text of the push notification
--- @param callback The method to be invoked when the server response is received
function PushNotification:sendSimplePushNotification(toProfileId, message, callback)
	local data = { toPlayerId = toProfileId, message = message }
	self.client:sendRequest(SERVICE, OPS.SEND_SIMPLE, data, callback)
end

--- Sends a notification to a user based on a brainCloud portal configured notification template.
--- NOTE: It is possible to send a push notification to oneself.
--- @param toProfileId The braincloud profileId of the user to receive the notification
--- @param notificationTemplateId Id of the notification template
--- @param callback The method to be invoked when the server response is received
function PushNotification:sendRichPushNotification(toProfileId, notificationTemplateId, callback)
	self:sendRichPushNotificationWithParams(toProfileId, notificationTemplateId, nil, callback)
end

--- Sends a notification to a user based on a brainCloud portal configured notification template.
--- Includes JSON defining the substitution params to use with the template.
--- See the Portal documentation for more info.
--- NOTE: It is possible to send a push notification to oneself.
--- @param toProfileId The braincloud profileId of the user to receive the notification
--- @param notificationTemplateId Id of the notification template
--- @param substitutionJson JSON defining the substitution params to use with the template
--- @param callback The method to be invoked when the server response is received
function PushNotification:sendRichPushNotificationWithParams(
	toProfileId,
	notificationTemplateId,
	substitutionJson,
	callback
)
	local data = { toPlayerId = toProfileId, notificationTemplateId = notificationTemplateId }
	if substitutionJson ~= nil then
		data.substitutions = substitutionJson
	end
	self.client:sendRequest(SERVICE, OPS.SEND_RICH, data, callback)
end

--- Sends a notification to a "group" of user based on a brainCloud portal configured notification template.
--- Includes JSON defining the substitution params to use with the template.
--- See the Portal documentation for more info.
--- @param groupId Target group
--- @param notificationTemplateId Template to use
--- @param substitutionsJson Map of substitution positions to strings
--- @param callback The method to be invoked when the server response is received
function PushNotification:sendTemplatedPushNotificationToGroup(
	groupId,
	notificationTemplateId,
	substitutionJson,
	callback
)
	local data = { groupId = groupId, notificationTemplateId = notificationTemplateId }
	if substitutionJson ~= nil then
		data.substitutions = substitutionJson
	end
	self.client:sendRequest(SERVICE, OPS.SEND_TEMPLATED_TO_GROUP, data, callback)
end

--- Sends a notification to a "group" of user consisting of alert content and custom data.
--- See the Portal documentation for more info.
--- @param groupId Target group
--- @param alertContentJson Body and title of alert
--- @param customDataJson Optional custom data
--- @param callback The method to be invoked when the server response is received
function PushNotification:sendNormalizedPushNotificationToGroup(groupId, alertContentJson, customDataJson, callback)
	local data = { groupId = groupId, alertContent = alertContentJson }
	if customDataJson ~= nil then
		data.customData = customDataJson
	end
	self.client:sendRequest(SERVICE, OPS.SEND_NORMALIZED_TO_GROUP, data, callback)
end

--- Schedules a normalized push notification to a user
--- @param profileId The profileId of the user to receive the notification
--- @param fcmContent Valid Fcm data content
--- @param iosContent Valid ios data content
--- @param facebookContent Facebook template string
--- @param startTimeUTC Start time of sending the push notification in milliseconds, use UTC time in milliseconds since epoch
--- @param callback The method to be invoked when the server response is received
function PushNotification:scheduleRawPushNotificationUTC(
	profileId,
	fcmContent,
	iosContent,
	facebookContent,
	startTime,
	callback
)
	local data = { profileId = profileId, startDateUTC = startTime }
	if fcmContent ~= nil then
		data.fcmContent = fcmContent
	end
	if iosContent ~= nil then
		data.iosContent = iosContent
	end
	if facebookContent ~= nil then
		data.facebookContent = facebookContent
	end
	self.client:sendRequest(SERVICE, OPS.SCHEDULE_RAW, data, callback)
end

--- Schedules a normalized push notification to a user
-- 
-- @param profileId The profileId of the user to receive the notification
-- @param fcmContent Valid Fcm data content
-- @param iosContent Valid ios data content
-- @param facebookContent Facebook template string
-- @param minutesFromNow Minutes from now to send the push notification
-- @param callback The method to be invoked when the server response is received
-- 
function PushNotification:scheduleRawPushNotificationMinutes(
	profileId,
	fcmContent,
	iosContent,
	facebookContent,
	minutesFromNow,
	callback
)
	local data = { profileId = profileId, minutesFromNow = minutesFromNow }
	if fcmContent ~= nil then
		data.fcmContent = fcmContent
	end
	if iosContent ~= nil then
		data.iosContent = iosContent
	end
	if facebookContent ~= nil then
		data.facebookContent = facebookContent
	end
	self.client:sendRequest(SERVICE, OPS.SCHEDULE_RAW, data, callback)
end

--- Sends a raw push notification to a target user.
--- @param toProfileId The profileId of the user to receive the notification
--- @param fcmContent Valid Fcm data content
--- @param iosContent Valid ios data content
--- @param facebookContent Facebook template string
--- @param callback The method to be invoked when the server response is received
function PushNotification:sendRawPushNotification(toProfileId, fcmContent, iosContent, facebookContent, callback)
	local data = { toPlayerId = toProfileId }
	if fcmContent ~= nil then
		data.fcmContent = fcmContent
	end
	if iosContent ~= nil then
		data.iosContent = iosContent
	end
	if facebookContent ~= nil then
		data.facebookContent = facebookContent
	end
	self.client:sendRequest(SERVICE, OPS.SEND_RAW, data, callback)
end

--- Sends a raw push notification to a target list of users.
--- @param profileIds Collection of profile IDs to send the notification to
--- @param fcmContent Valid Fcm data content
--- @param iosContent Valid ios data content
--- @param facebookContent Facebook template string
--- @param callback The method to be invoked when the server response is received
function PushNotification:sendRawPushNotificationBatch(profileIds, fcmContent, iosContent, facebookContent, callback)
	local data = { profileIds = Utils.array(profileIds) }
	if fcmContent ~= nil then
		data.fcmContent = fcmContent
	end
	if iosContent ~= nil then
		data.iosContent = iosContent
	end
	if facebookContent ~= nil then
		data.facebookContent = facebookContent
	end
	self.client:sendRequest(SERVICE, OPS.SEND_RAW_BATCH, data, callback)
end

--- Sends a raw push notification to a target group.
--- @param groupId Target group
--- @param fcmContent Valid Fcm data content
--- @param iosContent Valid ios data content
--- @param facebookContent Facebook template stringn
--- @param callback The method to be invoked when the server response is received
function PushNotification:sendRawPushNotificationToGroup(groupId, fcmContent, iosContent, facebookContent, callback)
	local data = { groupId = groupId }
	if fcmContent ~= nil then
		data.fcmContent = fcmContent
	end
	if iosContent ~= nil then
		data.iosContent = iosContent
	end
	if facebookContent ~= nil then
		data.facebookContent = facebookContent
	end
	self.client:sendRequest(SERVICE, OPS.SEND_RAW_TO_GROUP, data, callback)
end

--- Schedules a normalized push notification to a user
--- @param toProfileId The profileId of the user to receive the notification
--- @param alertContentJson Body and title of alert
--- @param customDataJson Optional custom data
--- @param startTimeUTC Start time of sending the push notification in milliseconds, use UTC time in milliseconds since epoch
--- @param callback The method to be invoked when the server response is received
function PushNotification:scheduleNormalizedPushNotificationUTC(
	profileId,
	alertContentJson,
	customDataJson,
	startTime,
	callback
)
	local data = { profileId = profileId, alertContent = alertContentJson, startDateUTC = startTime }
	if customDataJson ~= nil then
		data.customData = customDataJson
	end
	self.client:sendRequest(SERVICE, OPS.SCHEDULE_NORMALIZED, data, callback)
end

--- Schedules a normalized push notification to a user
--- @param toProfileId The profileId of the user to receive the notification
--- @param alertContentJson Body and title of alert
--- @param customDataJson Optional custom data
--- @param minutesFromNow Minutes from now to send the push notification
--- @param callback The method to be invoked when the server response is received
function PushNotification:scheduleNormalizedPushNotificationMinutes(
	profileId,
	alertContentJson,
	customDataJson,
	minutesFromNow,
	callback
)
	local data = { profileId = profileId, alertContent = alertContentJson, minutesFromNow = minutesFromNow }
	if customDataJson ~= nil then
		data.customData = customDataJson
	end
	self.client:sendRequest(SERVICE, OPS.SCHEDULE_NORMALIZED, data, callback)
end

--- Schedules a rich push notification to a user
--- @param toProfileId The profileId of the user to receive the notification
--- @param notificationTemplateId Body and title of alert
--- @param substitutionsJson Map of substitution positions to strings
--- @param startTimeUTC Start time of sending the push notification in milliseconds, use UTC time in milliseconds since epoch
--- @param callback The method to be invoked when the server response is received
function PushNotification:scheduleRichPushNotificationUTC(
	profileId,
	notificationTemplateId,
	substitutionJson,
	startTime,
	callback
)
	local data = { profileId = profileId, notificationTemplateId = notificationTemplateId, startDateUTC = startTime }
	if substitutionJson ~= nil then
		data.substitutions = substitutionJson
	end
	self.client:sendRequest(SERVICE, OPS.SCHEDULE_RICH, data, callback)
end

--- Schedules a rich push notification to a user
--- @param toProfileId The profileId of the user to receive the notification
--- @param notificationTemplateId Body and title of alert
--- @param substitutionsJson Map of substitution positions to strings
--- @param minutesFromNow Minutes from now to send the push notification
--- @param callback The method to be invoked when the server response is received
function PushNotification:scheduleRichPushNotificationMinutes(
	profileId,
	notificationTemplateId,
	substitutionJson,
	minutesFromNow,
	callback
)
	local data =
		{ profileId = profileId, notificationTemplateId = notificationTemplateId, minutesFromNow = minutesFromNow }
	if substitutionJson ~= nil then
		data.substitutions = substitutionJson
	end
	self.client:sendRequest(SERVICE, OPS.SCHEDULE_RICH, data, callback)
end

--- Sends a notification to a user consisting of alert content and custom data.
--- @param toProfileId The profileId of the user to receive the notification
--- @param alertContent Body and title of alert
--- @param customData Optional custom data
--- @param callback The method to be invoked when the server response is received
function PushNotification:sendNormalizedPushNotification(toProfileId, alertContentJson, customDataJson, callback)
	local data = { toPlayerId = toProfileId, alertContent = alertContentJson }
	if customDataJson ~= nil then
		data.customData = customDataJson
	end
	self.client:sendRequest(SERVICE, OPS.SEND_NORMALIZED, data, callback)
end

--- Sends a notification to multiple users consisting of alert content and custom data.
--- @param profileIds Collection of profile IDs to send the notification to
--- @param alertContent Body and title of alert
--- @param customData Optional custom data
--- @param callback The method to be invoked when the server response is received
function PushNotification:sendNormalizedPushNotificationBatch(profileIds, alertContentJson, customDataJson, callback)
	local data = { profileIds = Utils.array(profileIds), alertContent = alertContentJson }
	if customDataJson ~= nil then
		data.customData = customDataJson
	end
	self.client:sendRequest(SERVICE, OPS.SEND_NORMALIZED_BATCH, data, callback)
end

return PushNotification

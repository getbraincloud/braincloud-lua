local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")

local Group = {}
Group.__index = Group

local SERVICE = "group"

local OPS = {
	ACCEPT_GROUP_INVITATION = "ACCEPT_GROUP_INVITATION",
	ADD_GROUP_MEMBER = "ADD_GROUP_MEMBER",
	READ_GROUP_MEMBERS = "READ_GROUP_MEMBERS",
	APPROVE_GROUP_JOIN_REQUEST = "APPROVE_GROUP_JOIN_REQUEST",
	AUTO_JOIN_GROUP = "AUTO_JOIN_GROUP",
	AUTO_JOIN_GROUP_MULTI = "AUTO_JOIN_GROUP_MULTI",
	CANCEL_GROUP_INVITATION = "CANCEL_GROUP_INVITATION",
	CREATE_GROUP = "CREATE_GROUP",
	CREATE_GROUP_ENTITY = "CREATE_GROUP_ENTITY",
	DELETE_GROUP = "DELETE_GROUP",
	DELETE_GROUP_ENTITY = "DELETE_GROUP_ENTITY",
	DELETE_GROUP_JOIN_REQUEST = "DELETE_GROUP_JOIN_REQUEST",
	INCREMENT_GROUP_DATA = "INCREMENT_GROUP_DATA",
	INCREMENT_GROUP_ENTITY_DATA = "INCREMENT_GROUP_ENTITY_DATA",
	INVITE_GROUP_MEMBER = "INVITE_GROUP_MEMBER",
	JOIN_GROUP = "JOIN_GROUP",
	LEAVE_GROUP = "LEAVE_GROUP",
	LIST_GROUPS_PAGE = "LIST_GROUPS_PAGE",
	LIST_GROUPS_PAGE_BY_OFFSET = "LIST_GROUPS_PAGE_BY_OFFSET",
	LIST_GROUPS_WITH_MEMBER = "LIST_GROUPS_WITH_MEMBER",
	REJECT_GROUP_INVITATION = "REJECT_GROUP_INVITATION",
	REJECT_GROUP_JOIN_REQUEST = "REJECT_GROUP_JOIN_REQUEST",
	GET_MY_GROUPS = "GET_MY_GROUPS",
	READ_GROUP = "READ_GROUP",
	READ_GROUP_DATA = "READ_GROUP_DATA",
	READ_GROUP_ENTITIES_PAGE = "READ_GROUP_ENTITIES_PAGE",
	READ_GROUP_ENTITIES_PAGE_BY_OFFSET = "READ_GROUP_ENTITIES_PAGE_BY_OFFSET",
	READ_GROUP_ENTITY = "READ_GROUP_ENTITY",
	REMOVE_GROUP_MEMBER = "REMOVE_GROUP_MEMBER",
	SET_GROUP_OPEN = "SET_GROUP_OPEN",
	UPDATE_GROUP_ACL = "UPDATE_GROUP_ACL",
	UPDATE_GROUP_DATA = "UPDATE_GROUP_DATA",
	UPDATE_GROUP_MEMBER = "UPDATE_GROUP_MEMBER",
	UPDATE_GROUP_NAME = "UPDATE_GROUP_NAME",
	UPDATE_GROUP_ENTITY_ACL = "UPDATE_GROUP_ENTITY_ACL",
	UPDATE_GROUP_ENTITY_DATA = "UPDATE_GROUP_ENTITY_DATA",
	UPDATE_GROUP_SUMMARY_DATA = "UPDATE_GROUP_SUMMARY_DATA",
	GET_RANDOM_GROUPS_MATCHING = "GET_RANDOM_GROUPS_MATCHING",
}

--[[
    Constructor
]]

--- Creates a new Group instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return Group
function Group.new(brainCloudClient)
	local self = setmetatable({}, Group)
	self.client = brainCloudClient
	return self
end

--- GROUP FUNCTIONS

--- Accept an outstanding invitation to join the group.
-- Service Name - group
-- Service Operation - ACCEPT_GROUP_INVITATION
-- 
-- @param groupId ID of the group.
-- @param callback The method to be invoked when the server response is received
-- 
function Group:acceptGroupInvitation(groupId, callback)
	self.client:sendRequest(SERVICE, OPS.ACCEPT_GROUP_INVITATION, { groupId = groupId }, callback)
end

--- Reject an outstanding invitation to join the group.
-- Service Name - group
-- Service Operation - REJECT_GROUP_INVITATION
-- 
-- @param groupId ID of the group.
-- @param callback The method to be invoked when the server response is received
-- 
function Group:rejectGroupInvitation(groupId, callback)
	self.client:sendRequest(SERVICE, OPS.REJECT_GROUP_INVITATION, { groupId = groupId }, callback)
end

--- Cancel an outstanding invitation to the group.
-- Service Name - group
-- Service Operation - CANCEL_GROUP_INVITATION
-- 
-- @param groupId ID of the group.
-- @param profileId Profile ID of the invitation being deleted.
-- @param callback The method to be invoked when the server response is received
-- 
function Group:cancelGroupInvitation(groupId, profileId, callback)
	self.client:sendRequest(SERVICE, OPS.CANCEL_GROUP_INVITATION, { groupId = groupId, profileId = profileId }, callback)
end

--- Add a member to the group.
--- Service Name - group
--- Service Operation - ADD_GROUP_MEMBER
--- @param groupId ID of the group.
--- @param profileId Profile ID of the member being added.
--- @param role Role of the member being added.
--- @param jsonAttributes Attributes of the member being added.
--- @param callback The method to be invoked when the server response is received
function Group:addGroupMember(groupId, profileId, role, attributes, callback)
	self.client:sendRequest(SERVICE, OPS.ADD_GROUP_MEMBER, {
		groupId = groupId,
		profileId = profileId,
		role = role,
		attributes = attributes,
	}, callback)
end

--- Read the members of the group.
--- Service Name - group
--- Service Operation - READ_MEMBERS_OF_GROUP
--- @param groupId ID of the group.
--- @param callback The method to be invoked when the server response is received
function Group:readGroupMembers(groupId, callback)
	local message = {
		groupId = groupId,
	}

	self.client:sendRequest(SERVICE, OPS.READ_GROUP_MEMBERS, message, callback)
end

--- Approve an outstanding request to join the group.
--- Service Name - group
--- Service Operation - APPROVE_GROUP_JOREQUEST
--- @param groupId ID of the group.
--- @param profileId Profile ID of the invitation being deleted.
--- @param role Role of the member being invited.
--- @param jsonAttributes Attributes of the member being invited.
--- @param callback The method to be invoked when the server response is received
function Group:approveGroupJoinRequest(groupId, profileId, role, attributes, callback)
	self.client:sendRequest(SERVICE, OPS.APPROVE_GROUP_JOIN_REQUEST, {
		groupId = groupId,
		profileId = profileId,
		role = role,
		attributes = attributes,
	}, callback)
end

--- Automatically join an open group that matches the search criteria and has space available.
--- Service Name - group
--- Service Operation - AUTO_JOGROUP
--- @param groupType Name of the associated group type.
--- @param autoJoinStrategy Selection strategy to employ when there are multiple matches
--- @param dataQueryJson Query parameters (optional)
--- @param callback The method to be invoked when the server response is received
function Group:autoJoinGroup(groupType, autoJoinStrategy, dataQuery, callback)
	self.client:sendRequest(SERVICE, OPS.AUTO_JOIN_GROUP, {
		groupType = groupType,
		autoJoinStrategy = autoJoinStrategy,
		where = dataQuery,
	}, callback)
end

--- Find and join an open group in the pool of groups in multiple group types provided as input arguments.		*
-- Service Name - group
-- Service Operation - AUTO_JOGROUP_MULTI
-- 
-- @param groupTypes Name of the associated group type.
-- @param autoJoinStrategy Selection strategy to employ when there are multiple matches
-- @param where Query parameters (optional)
-- @param callback The method to be invoked when the server response is received
-- 
function Group:autoJoinGroupMulti(groupTypes, autoJoinStrategy, where, callback)
	self.client:sendRequest(SERVICE, OPS.AUTO_JOIN_GROUP_MULTI, {
		groupTypes = Utils.array(groupTypes),
		autoJoinStrategy = autoJoinStrategy,
		where = where,
	}, callback)
end

--- Create a group.
--- Service Name - group
--- Service Operation - CREATE_GROUP
--- @param name Name of the group.
--- @param groupType Name of the type of group.
--- @param isOpenGroup true if group is open; false if closed.
--- @param acl The group's access control list. A null ACL implies default.
--- @param jsonOwnerAttributes Attributes for the group owner (current user).
--- @param jsonDefaultMemberAttributes Default attributes for group members.
--- @param jsonData Custom application data.
--- @param callback The method to be invoked when the server response is received
function Group:createGroup(name, groupType, isOpenGroup, acl, data, ownerAttributes, defaultMemberAttributes, callback)
	self:createGroupWithSummaryData(
		name,
		groupType,
		isOpenGroup,
		acl,
		data,
		ownerAttributes,
		defaultMemberAttributes,
		nil,
		callback
	)
end

--- Create a group with Summary Data.
-- Service Name - group
-- Service Operation - CREATE_GROUP
-- 
-- @param name Name of the group.
-- @param groupType Name of the type of group.
-- @param isOpenGroup true if group is open; false if closed.
-- @param acl The group's access control list. A null ACL implies default.
-- @param jsonOwnerAttributes Attributes for the group owner (current user).
-- @param jsonDefaultMemberAttributes Default attributes for group members.
-- @param jsonSummaryData the summary.
-- @param jsonData Custom application data.
-- @param callback The method to be invoked when the server response is received
-- 
function Group:createGroupWithSummaryData(
	name,
	groupType,
	isOpenGroup,
	acl,
	data,
	ownerAttributes,
	defaultMemberAttributes,
	summaryData,
	callback
)
	self.client:sendRequest(SERVICE, OPS.CREATE_GROUP, {
		name = name,
		groupType = groupType,
		isOpenGroup = isOpenGroup,
		acl = acl,
		data = data,
		ownerAttributes = ownerAttributes,
		defaultMemberAttributes = defaultMemberAttributes,
		summaryData = summaryData,
	}, callback)
end

--- Create a group entity.
-- Service Name - group
-- Service Operation - CREATE_GROUP_ENTITY
-- 
-- @param groupId ID of the group.
-- @param isOwnedByGroupMember true if entity is owned by a member; false if owned by the entire group.
-- @param entityType Type of the group entity.
-- @param acl Access control list for the group entity.
-- @param jsonData Custom application data.
-- @param callback The method to be invoked when the server response is received
-- 
function Group:createGroupEntity(groupId, entityType, isOwnedByGroupMember, acl, data, callback)
	local payload = {
		groupId = groupId,
		isOwnedByGroupMember = isOwnedByGroupMember,
		entityType = entityType,
	}
	local fixedData = Utils.emptyFix(data)
	if next(fixedData) then payload.data = fixedData end
	local fixedAcl = Utils.emptyFix(acl)
	if next(fixedAcl) then payload.acl = fixedAcl end
	self.client:sendRequest(SERVICE, OPS.CREATE_GROUP_ENTITY, payload, callback)
end

--- Delete a group.
--- Service Name - group
--- Service Operation - DELETE_GROUP
--- @param groupId ID of the group.
--- @param version Current version of the group
--- @param callback The method to be invoked when the server response is received
function Group:deleteGroup(groupId, version, callback)
	self.client:sendRequest(SERVICE, OPS.DELETE_GROUP, { groupId = groupId, version = version }, callback)
end

--- Delete a group entity.
--- Service Name - group
--- Service Operation - DELETE_GROUP_ENTITY
--- @param groupId ID of the group.
--- @param entityId ID of the entity.
--- @param version The current version of the group entity (for concurrency checking).
--- @param callback The method to be invoked when the server response is received
function Group:deleteGroupEntity(groupId, entityId, version, callback)
	self.client:sendRequest(SERVICE, OPS.DELETE_GROUP_ENTITY, {
		groupId = groupId,
		entityId = entityId,
		version = version,
	}, callback)
end

--- Delete an outstanding request to join the group.
--- Service Name - group
--- Service Operation - DELETE_GROUP_JOREQUEST
--- @param groupId ID of the group.
--- @param callback The method to be invoked when the server response is received
function Group:deleteGroupJoinRequest(groupId, callback)
	self.client:sendRequest(SERVICE, OPS.DELETE_GROUP_JOIN_REQUEST, {
		groupId = groupId,
	}, callback)
end

--- Increment elements for the group's data field.
--- Service Name - group
--- Service Operation - INCREMENT_GROUP_DATA
--- @param groupId ID of the group.
--- @param jsonData Partial data map with incremental values.
--- @param callback The method to be invoked when the server response is received
function Group:incrementGroupData(groupId, data, callback)
	local payload = { groupId = groupId }
	local fixedData = Utils.emptyFix(data)
	if next(fixedData) then payload.data = fixedData end
	self.client:sendRequest(SERVICE, OPS.INCREMENT_GROUP_DATA, payload, callback)
end

--- Increment elements for the group entity's data field.
--- Service Name - group
--- Service Operation - INCREMENT_GROUP_ENTITY_DATA
--- @param groupId ID of the group.
--- @param entityId ID of the entity.
--- @param jsonData Partial data map with incremental values.
--- @param callback The method to be invoked when the server response is received
function Group:incrementGroupEntityData(groupId, entityId, data, callback)
	local payload = {
		groupId = groupId,
		entityId = entityId,
	}
	local fixedData = Utils.emptyFix(data)
	if next(fixedData) then payload.data = fixedData end
	self.client:sendRequest(SERVICE, OPS.INCREMENT_GROUP_ENTITY_DATA, payload, callback)
end

--- Invite a member to the group.
--- Service Name - group
--- Service Operation - INVITE_GROUP_MEMBER
--- @param groupId ID of the group.
--- @param profileId Profile ID of the member being invited.
--- @param role Role of the member being invited.
--- @param jsonAttributes Attributes of the member being invited.
--- @param callback The method to be invoked when the server response is received
function Group:inviteGroupMember(groupId, profileId, role, attributes, callback)
	self.client:sendRequest(SERVICE, OPS.INVITE_GROUP_MEMBER, {
		groupId = groupId,
		profileId = profileId,
		role = role,
		attributes = attributes,
	}, callback)
end

--- Join an open group or request to join a closed group.
-- Service Name - group
-- Service Operation - JOGROUP
-- 
-- @param groupId ID of the group.
-- @param callback The method to be invoked when the server response is received
-- 
function Group:joinGroup(groupId, callback)
	self.client:sendRequest(SERVICE, OPS.JOIN_GROUP, { groupId = groupId }, callback)
end

--- Leave a group in which the user is a member.
--- Service Name - group
--- Service Operation - LEAVE_GROUP
--- @param groupId ID of the group.
--- @param callback The method to be invoked when the server response is received
function Group:leaveGroup(groupId, callback)
	self.client:sendRequest(SERVICE, OPS.LEAVE_GROUP, { groupId = groupId }, callback)
end

--- Read a page of group information.
--- Service Name - group
--- Service Operation - LIST_GROUPS_PAGE
--- @param context Query context.
--- @param callback The method to be invoked when the server response is received
function Group:listGroupsPage(context, callback)
	self.client:sendRequest(SERVICE, OPS.LIST_GROUPS_PAGE, { context = context }, callback)
end

--- Read a page of group information.
--- Service Name - group
--- Service Operation - LIST_GROUPS_PAGE_BY_OFFSET
--- @param encodedContext Encoded reference query context.
--- @param offset Number of pages by which to offset the query.
--- @param callback The method to be invoked when the server response is received
function Group:listGroupsPageByOffset(context, offset, callback)
	self.client:sendRequest(SERVICE, OPS.LIST_GROUPS_PAGE_BY_OFFSET, {
		context = context,
		pageOffset = offset,
	}, callback)
end

--- Read information on groups to which the specified user belongs.  Access is subject to restrictions.
--- @param profileId
--- Service Name - group
--- Service Operation - LIST_GROUPS_WITH_MEMBER
--- @param callback The method to be invoked when the server response is received
function Group:listGroupsWithMember(profileId, callback)
	self.client:sendRequest(SERVICE, OPS.LIST_GROUPS_WITH_MEMBER, { profileId = profileId }, callback)
end

--- Reject an outstanding request to join the group.
--- Service Name - group
--- Service Operation - REJECT_GROUP_JOREQUEST
--- @param groupId ID of the group.
--- @param profileId Profile ID of the invitation being deleted.
--- @param callback The method to be invoked when the server response is received
function Group:rejectGroupJoinRequest(groupId, profileId, callback)
	self.client:sendRequest(SERVICE, OPS.REJECT_GROUP_JOIN_REQUEST, {
		groupId = groupId,
		profileId = profileId,
	}, callback)
end

--- Read information on groups to which the current user belongs.
--- Service Name - group
--- Service Operation - GET_MY_GROUPS
--- @param callback The method to be invoked when the server response is received
function Group:getMyGroups(callback)
	self.client:sendRequest(SERVICE, OPS.GET_MY_GROUPS, nil, callback)
end

--- Read the specified group.
--- Service Name - group
--- Service Operation - READ_GROUP
--- @param groupId ID of the group.
--- @param callback The method to be invoked when the server response is received
function Group:readGroup(groupId, callback)
	self.client:sendRequest(SERVICE, OPS.READ_GROUP, { groupId = groupId }, callback)
end

--- Read the specified group's data.
--- Service Name - group
--- Service Operation - READ_GROUP_DATA
--- @param groupId ID of the group.
--- @param callback The method to be invoked when the server response is received
function Group:readGroupData(groupId, callback)
	self.client:sendRequest(SERVICE, OPS.READ_GROUP_DATA, { groupId = groupId }, callback)
end

--- Read a page of group entity information.
--- Service Name - group
--- Service Operation - READ_GROUP_ENTITIES_PAGE
--- @param context Query context.
--- @param callback The method to be invoked when the server response is received
function Group:readGroupEntitiesPage(context, callback)
	self.client:sendRequest(SERVICE, OPS.READ_GROUP_ENTITIES_PAGE, { context = context }, callback)
end

--- Read a page of group entity information.
--- Service Name - group
--- Service Operation - READ_GROUP_ENTITIES_PAGE_BY_OFFSET
--- @param encodedContext Encoded reference query context.
--- @param offset Number of pages by which to offset the query.
--- @param callback The method to be invoked when the server response is received
function Group:readGroupEntitiesPageByOffset(context, offset, callback)
	self.client:sendRequest(SERVICE, OPS.READ_GROUP_ENTITIES_PAGE_BY_OFFSET, {
		context = context,
		pageOffset = offset,
	}, callback)
end

--- Read the specified group entity.
--- Service Name - group
--- Service Operation - READ_GROUP_ENTITY
--- @param groupId ID of the group.
--- @param entityId ID of the entity.
--- @param callback The method to be invoked when the server response is received
function Group:readGroupEntity(groupId, entityId, callback)
	self.client:sendRequest(SERVICE, OPS.READ_GROUP_ENTITY, {
		groupId = groupId,
		entityId = entityId,
	}, callback)
end

--- Remove a member from the group.
--- Service Name - group
--- Service Operation - REMOVE_GROUP_MEMBER
--- @param groupId ID of the group.
--- @param profileId Profile ID of the member being deleted.
--- @param callback The method to be invoked when the server response is received
function Group:removeGroupMember(groupId, profileId, callback)
	self.client:sendRequest(SERVICE, OPS.REMOVE_GROUP_MEMBER, {
		groupId = groupId,
		profileId = profileId,
	}, callback)
end

--- Set whether a group is open true or false
--- Service Name - group
--- Service Operation - SET_GROUP_OPEN
--- @param groupId ID of the group.
--- @param isOpenGroup whether its open or not
--- @param callback The method to be invoked when the server response is received
function Group:setGroupOpen(groupId, isOpen, callback)
	self.client:sendRequest(SERVICE, OPS.SET_GROUP_OPEN, {
		groupId = groupId,
		isOpenGroup = isOpen,
	}, callback)
end

--- Updates a group's name.
--- Service Name - group
--- Service Operation - UPDATE_GROUP_NAME
--- @param groupId ID of the group.
--- @param name Name to apply.
--- @param callback The method to be invoked when the server response is received
function Group:updateGroupName(groupId, name, callback)
	local message = {
		groupId = groupId,
		name = name,
	}

	self.client:sendRequest(SERVICE, OPS.UPDATE_GROUP_NAME, message, callback)
end

--- Updates a group's data.
--- Service Name - group
--- Service Operation - UPDATE_GROUP_DATA
--- @param groupId ID of the group.
--- @param version Version to verify.
--- @param jsonData Data to apply.
--- @param callback The method to be invoked when the server response is received
function Group:updateGroupData(groupId, version, data, callback)
	local payload = { groupId = groupId, version = version }
	local fixedData = Utils.emptyFix(data)
	if next(fixedData) then payload.data = fixedData end
	self.client:sendRequest(SERVICE, OPS.UPDATE_GROUP_DATA, payload, callback)
end

--- Update the acl settings for a group entity, enforcing ownership.
-- Service Name - group
-- Service Operation - UPDATE_GROUP_ENTITY_ACL
-- 
-- @param groupId The id of the group
-- @param entityId The id of the entity to update
-- @param acl Access control list for the group entity
-- @param callback The method to be invoked when the server response is received
-- 
function Group:updateGroupEntityAcl(groupId, entityId, version, acl, callback)
	self.client:sendRequest(SERVICE, OPS.UPDATE_GROUP_ENTITY_ACL, {
		groupId = groupId,
		entityId = entityId,
		version = version,
		acl = acl,
	}, callback)
end

--- Update a group entity.
--- Service Name - group
--- Service Operation - UPDATE_GROUP_ENTITY_DATA
--- @param groupId ID of the group.
--- @param entityId ID of the entity.
--- @param version The current version of the group entity (for concurrency checking).
--- @param jsonData Custom application data.
--- @param callback The method to be invoked when the server response is received
function Group:updateGroupEntityData(groupId, entityId, version, data, callback)
	local payload = { groupId = groupId, entityId = entityId, version = version }
	local fixedData = Utils.emptyFix(data)
	if next(fixedData) then payload.data = fixedData end
	self.client:sendRequest(SERVICE, OPS.UPDATE_GROUP_ENTITY_DATA, payload, callback)
end

--- Update a group's summary data
--- Service Name - group
--- Service Operation - UPDATE_GROUP_SUMMARY_DATA
--- @param groupId ID of the group.
--- @param version the version of the group
--- @param jsonSummaryData custom application data
--- @param callback The method to be invoked when the server response is received
function Group:updateGroupSummaryData(groupId, version, summaryData, callback)
	local payload = { groupId = groupId, version = version, summaryData = summaryData or {} }
	self.client:sendRequest(SERVICE, OPS.UPDATE_GROUP_SUMMARY_DATA, payload, callback)
end

--- Set a group's access conditions.
-- Service Name - group
-- Service Operation - UPDATE_GROUP_ACL
-- 
-- @param groupId ID of the group
-- @param acl The group's access control list. A null ACL implies default
-- @param callback The method to be invoked when the server response is received
-- 
function Group:updateGroupAcl(groupId, acl, callback)
	self.client:sendRequest(SERVICE, OPS.UPDATE_GROUP_ACL, { groupId = groupId, acl = acl }, callback)
end

--- Update a member of the group.
-- Service Name - group
-- Service Operation - UPDATE_GROUP_MEMBER
-- 
-- @param groupId ID of the group.
-- @param profileId Profile ID of the member being updated.
-- @param role Role of the member being updated (optional).
-- @param jsonAttributes Attributes of the member being updated (optional).
-- @param callback The method to be invoked when the server response is received
-- 
function Group:updateGroupMember(groupId, profileId, role, attributes, callback)
	self.client:sendRequest(SERVICE, OPS.UPDATE_GROUP_MEMBER, {
		groupId = groupId,
		profileId = profileId,
		role = role,
		attributes = attributes,
	}, callback)
end

--- Gets a list of up to maxReturn randomly selected groups from the server based on the where condition.
--- Service Name - group
--- Service Operation - GET_RANDOM_GROUPS_MATCHING
--- @param jsonWhere where to search
--- @param maxReturn # of groups to search
--- @param callback The method to be invoked when the server response is received
function Group:getRandomGroupsMatching(where, maxReturn, callback)
	local message = {
		where = where,
		maxReturn = maxReturn,
	}

	self.client:sendRequest("group", OPS.GET_RANDOM_GROUPS_MATCHING, message, callback)
end

return Group

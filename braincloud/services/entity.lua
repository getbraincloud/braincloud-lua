local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")

local Entity = {}
Entity.__index = Entity

local SERVICE = "entity"

--- Operation constants matching the JS file exactly
local OPS = {
	READ = "READ",
	CREATE = "CREATE",
	READ_BY_TYPE = "READ_BY_TYPE",
	READ_SHARED = "READ_SHARED",
	READ_SHARED_ENTITY = "READ_SHARED_ENTITY",
	READ_SINGLETON = "READ_SINGLETON",
	UPDATE = "UPDATE",
	UPDATE_SHARED = "UPDATE_SHARED",
	UPDATE_SINGLETON = "UPDATE_SINGLETON",
	UPDATE_PARTIAL = "UPDATE_PARTIAL",
	DELETE = "DELETE",
	DELETE_SINGLETON = "DELETE_SINGLETON",
	GET_LIST = "GET_LIST",
	GET_LIST_COUNT = "GET_LIST_COUNT",
	GET_PAGE = "GET_PAGE",
	GET_PAGE_BY_OFFSET = "GET_PAGE_BY_OFFSET",
	READ_SHARED_ENTITIES_LIST = "READ_SHARED_ENTITIES_LIST",
	INCREMENT_USER_ENTITY_DATA = "INCREMENT_USER_ENTITY_DATA",
	INCREMENT_SHARED_USER_ENTITY_DATA = "INCREMENT_SHARED_USER_ENTITY_DATA",
}

--- Creates a new Entity module instance.
--- @param client any The brainCloud client instance
--- @return table
function Entity.new(client)
	local self = setmetatable({}, Entity)
	self.client = client
	return self
end

--- CREATE

--- Method creates a new entity on the server.
-- Service Name - entity
-- Service Operation - CREATE
-- 
-- @param entityType The entity type as defined by the user
-- @param jsonEntityData The entity's data as a json string
-- @param jsonEntityAcl The entity's access control list as json. A null acl implies default
--        permissions which make the entity readable/writeable by only the user.
-- @param callback The method to be invoked when the server response is received
-- 
function Entity:createEntity(entityType, data, acl, callback)
	local msg = { entityType = entityType, data = Utils.emptyFix(data) }
	if acl then
		msg.acl = acl
	end

	self.client:sendRequest(SERVICE, OPS.CREATE, msg, callback)
end

--- READ

--- Method to get a specific entity.
-- Service Name - entity
-- Service Operation - READ
-- 
-- @param entityId The entity id
-- @param callback The method to be invoked when the server response is received
-- 
function Entity:getEntity(entityId, callback)
	self.client:sendRequest(SERVICE, OPS.READ, { entityId = entityId }, callback)
end

--- Method returns all user entities that match the given type.
-- Service Name - entity
-- Service Operation - READ_BY_TYPE
-- 
-- @param entityType The entity type to search for
-- @param callback The method to be invoked when the server response is received
-- 
function Entity:getEntitiesByType(entityType, callback)
	self.client:sendRequest(SERVICE, OPS.READ_BY_TYPE, { entityType = entityType }, callback)
end

--- Method returns a shared entity for the given user and entity ID.
-- An entity is shared if its ACL allows for the currently logged
-- in user to read the data.
-- Service Name - entity
-- Service Operation - READ_SHARED_ENTITY
-- 
-- @param profileId The the profile ID of the user who owns the entity
-- @param entityId The ID of the entity that will be retrieved
-- @param callback The method to be invoked when the server response is received
-- 
function Entity:getSharedEntityForProfileId(profileId, entityId, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.READ_SHARED_ENTITY,
		{ targetPlayerId = profileId, entityId = entityId },
		callback
	)
end

--- Method returns all shared entities for the given profile id.
-- An entity is shared if its ACL allows for the currently logged
-- in user to read the data.
-- Service Name - entity
-- Service Operation - READ_SHARED
-- 
-- @param profileId The profile id to retrieve shared entities for
-- @param callback The method to be invoked when the server response is received
-- 
function Entity:getSharedEntitiesForProfileId(profileId, callback)
	self.client:sendRequest(SERVICE, OPS.READ_SHARED, { targetPlayerId = profileId }, callback)
end

--- Method gets list of shared entities for the specified user based on type and/or where clause
-- Service Name - entity
-- Service Operation - READ_SHARED_ENTITIES_LIST
-- 
-- @param profileId The profile ID to retrieve shared entities for
-- @param whereJson Mongo style query
-- @param orderByJson Sort order
-- @param maxReturn The maximum number of entities to return
-- @param callback The method to be invoked when the server response is received
-- 
function Entity:getSharedEntitiesListForProfileId(profileId, where, orderBy, maxReturn, callback)
	local msg = {
		targetPlayerId = profileId,
		maxReturn = maxReturn,
	}
	if where then
		msg.where = where
	end
	if orderBy then
		msg.orderBy = orderBy
	end

	self.client:sendRequest(SERVICE, OPS.READ_SHARED_ENTITIES_LIST, msg, callback)
end

--- Method retreives a singleton entity on the server. If the entity doesn't exist, null is returned.
-- Service Name - entity
-- Service Operation - READ_SINGLETON
-- 
-- @param entityType The entity type as defined by the user
-- @param callback The method to be invoked when the server response is received
-- 
function Entity:getSingleton(entityType, callback)
	self.client:sendRequest(SERVICE, OPS.READ_SINGLETON, { entityType = entityType }, callback)
end

--- UPDATE

--- Method updates a new entity on the server. This operation results in the entity
-- data being completely replaced by the passed in JSON string.
-- Service Name - entity
-- Service Operation - UPDATE
-- 
-- @param entityId The id of the entity to update
-- @param entityType The entity type as defined by the user
-- @param jsonEntityData The entity's data as a json string.
-- @param jsonEntityAcl The entity's access control list as json. A null acl implies default
--        permissions which make the entity readable/writeable by only the user.
-- @param version Current version of the entity. If the version of the
--        entity on the server does not match the version passed in, the
--        server operation will fail. Use -1 to skip version checking.
-- @param callback The method to be invoked when the server response is received
-- 
function Entity:updateEntity(entityId, entityType, data, acl, version, callback)
	local msg = {
		entityId = entityId,
		data = Utils.emptyFix(data),
		version = version,
	}
	if entityType then
		msg.entityType = entityType
	end
	if acl then
		msg.acl = acl
	end

	self.client:sendRequest(SERVICE, OPS.UPDATE, msg, callback)
end

--- Method updates a shared entity owned by another user. This operation results in the entity
-- data being completely replaced by the passed in JSON string.
-- Service Name - entity
-- Service Operation - UPDATE_SHARED
-- 
-- @param entityId The id of the entity to update
-- @param targetProfileId The id of the user who owns the shared entity
-- @param entityType The entity type as defined by the user
-- @param jsonEntityData The entity's data as a json string.
-- @param callback The method to be invoked when the server response is received
-- 
function Entity:updateSharedEntity(entityId, targetProfileId, entityType, data, version, callback)
	local msg = {
		targetPlayerId = targetProfileId,
		entityId = entityId,
		data = Utils.emptyFix(data),
		version = version,
	}
	if entityType then
		msg.entityType = entityType
	end

	self.client:sendRequest(SERVICE, OPS.UPDATE_SHARED, msg, callback)
end

--- Method updates a new singleton entity on the server. This operation results in the entity
-- data being completely replaced by the passed in JSON string. If the entity doesn't exists it is created
-- Service Name - entity
-- Service Operation - UPDATE_SINGLETON
-- 
-- @param entityType The entity type as defined by the user
-- @param jsonEntityData The entity's data as a json string.
--        permissions which make the entity readable/writeable by only the user.
-- @param jsonEntityAcl The entity's access control list as json. A null acl implies default
--        permissions which make the entity readable/writeable by only the user.
-- @param version Current version of the entity. If the version of the
--        entity on the server does not match the version passed in, the
--        server operation will fail. Use -1 to skip version checking.
-- @param callback The method to be invoked when the server response is received
-- 
function Entity:updateSingleton(entityType, data, acl, version, callback)
	local msg = {
		entityType = entityType,
		data = Utils.emptyFix(data),
		version = version,
	}
	if acl then
		msg.acl = acl
	end

	self.client:sendRequest(SERVICE, OPS.UPDATE_SINGLETON, msg, callback)
end

--- DELETE

--- Method deletes the given entity on the server.
-- Service Name - entity
-- Service Operation - DELETE
-- 
-- @param entityId The id of the entity to update
-- @param version Current version of the entity. If the version of the
--        entity on the server does not match the version passed in, the
--        server operation will fail. Use -1 to skip version checking.
-- @param callback The method to be invoked when the server response is received
-- 
function Entity:deleteEntity(entityId, version, callback)
	self.client:sendRequest(SERVICE, OPS.DELETE, { entityId = entityId, version = version }, callback)
end

--- Method deletes the given singleton entity on the server.
-- Service Name - entity
-- Service Operation - DELETE_SINGLETON
-- 
-- @param entityType The type of the entity to delete
-- @param version Current version of the entity. If the version of the
--        entity on the server does not match the version passed in, the
--        server operation will fail. Use -1 to skip version checking.
-- @param callback The method to be invoked when the server response is received
-- 
function Entity:deleteSingleton(entityType, version, callback)
	self.client:sendRequest(SERVICE, OPS.DELETE_SINGLETON, { entityType = entityType, version = version }, callback)
end

--- LIST / PAGE

--- Method gets list of entities from the server base on type and/or where clause
-- Service Name - entity
-- Service Operation - GET_LIST
-- 
-- @param whereJson Mongo style query string
-- @param orderByJson Sort order
-- @param maxReturn The maximum number of entities to return
-- @param callback The callback object
-- 
function Entity:getList(where, orderBy, maxReturn, callback)
	local msg = { where = where, maxReturn = maxReturn }
	if orderBy then
		msg.orderBy = orderBy
	end

	self.client:sendRequest(SERVICE, OPS.GET_LIST, msg, callback)
end

--- Method gets a count of entities based on the where clause
-- Service Name - entity
-- Service Operation - GET_LIST_COUNT
-- 
-- @param whereJson Mongo style query string
-- @param callback The callback object
-- 
function Entity:getListCount(where, callback)
	self.client:sendRequest(SERVICE, OPS.GET_LIST_COUNT, { where = where }, callback)
end

--- Method uses a paging system to iterate through user entities
-- After retrieving a page of entities with this method,
-- use GetPageOffset() to retrieve previous or next pages.
-- Service Name - entity
-- Service Operation - GET_PAGE
-- 
-- @param context The json context for the page request.
--        See the portal appendix documentation for format.
-- @param callback The callback object
-- 
function Entity:getPage(context, callback)
	self.client:sendRequest(SERVICE, OPS.GET_PAGE, { context = context }, callback)
end

--- Method to retrieve previous or next pages after having called the GetPage method.
-- Service Name - entity
-- Service Operation - GET_PAGE_BY_OFFSET
-- 
-- @param context The context string returned from the server from a
--        previous call to GetPage or GetPageOffset
-- @param pageOffset The positive or negative page offset to fetch. Uses the last page
--        retrieved using the context string to determine a starting point.
-- @param callback The callback object
-- 
function Entity:getPageOffset(context, pageOffset, callback)
	self.client:sendRequest(SERVICE, OPS.GET_PAGE_BY_OFFSET, { context = context, pageOffset = pageOffset }, callback)
end

--- INCREMENT

--- Partial increment of entity data field items. Partial set of items incremented as specified.
-- Service Name - entity
-- Service Operation - INCREMENT_USER_ENTITY_DATA
-- 
-- @param entityId The id of the entity to update
-- @param jsonData The entity's data object
-- @param callback The callback object
-- 
function Entity:incrementUserEntityData(entityId, data, callback)
	self.client:sendRequest(SERVICE, OPS.INCREMENT_USER_ENTITY_DATA, { entityId = entityId, data = Utils.emptyFix(data) }, callback)
end

--- Partial increment of entity data field items. Partial set of items incremented as specified.
-- Service Name - entity
-- Service Operation - INCREMENT_SHARED_USER_ENTITY_DATA
-- 
-- @param entityId The id of the entity to update
-- @param targetProfileId Profile ID of the entity owner
-- @param jsonData The entity's data object
-- @param callback The callback object
-- 
function Entity:incrementSharedUserEntityData(entityId, targetProfileId, data, callback)
	self.client:sendRequest(SERVICE, OPS.INCREMENT_SHARED_USER_ENTITY_DATA, {
		entityId = entityId,
		targetPlayerId = targetProfileId,
		data = Utils.emptyFix(data),
	}, callback)
end

return Entity

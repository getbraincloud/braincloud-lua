local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local CustomEntity = {}
CustomEntity.__index = CustomEntity

local SERVICE = "customEntity"

local OPS = {
	CREATE = "CREATE_ENTITY",
	GET_COUNT = "GET_COUNT",
	GET_RANDOM_ENTITIES_MATCHING = "GET_RANDOM_ENTITIES_MATCHING",
	GET_ENTITY_PAGE = "GET_ENTITY_PAGE",
	GET_ENTITY_PAGE_OFFSET = "GET_ENTITY_PAGE_OFFSET",
	READ_ENTITY = "READ_ENTITY",
	UPDATE_ENTITY = "UPDATE_ENTITY",
	UPDATE_ENTITY_FIELDS = "UPDATE_ENTITY_FIELDS",
	UPDATE_ENTITY_FIELDS_SHARDED = "UPDATE_ENTITY_FIELDS_SHARDED",
	DELETE_ENTITY = "DELETE_ENTITY",
	DELETE_ENTITIES = "DELETE_ENTITIES",
	DELETE_SINGLETON = "DELETE_SINGLETON",
	READ_SINGLETON = "READ_SINGLETON",
	INCREMENT_SINGLETON_DATA = "INCREMENT_SINGLETON_DATA",
	UPDATE_SINGLETON = "UPDATE_SINGLETON",
	UPDATE_SINGLETON_FIELDS = "UPDATE_SINGLETON_FIELDS",
	INCREMENT_DATA = "INCREMENT_DATA",
}

function CustomEntity.new(baseClient)
	local self = setmetatable({}, CustomEntity)
	self.client = baseClient
	return self
end

--- Entity APIs

--- Creates new custom entity.
-- Service Name - customEntity
-- Service Operation - CREATE_ENTITY
-- 
-- @param entityType The entity type as defined by the user
-- @param jsonEntityData The entity's data as a json string
-- @param jsonEntityAcl The entity's access control list as json. A null acl implies default
--        permissions which make the entity readable/writeable by only the user.
--        @param timeToLive
--        @param isOwned
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:createEntity(entityType, dataJson, acl, timeToLive, isOwned, callback)
	local data = {
		entityType = entityType,
		dataJson = dataJson,
		timeToLive = timeToLive,
		isOwned = isOwned,
	}
	if acl then
		data.acl = acl
	else
		data.acl = { other = 1 }
	end

	self.client:sendRequest(SERVICE, OPS.CREATE, data, callback)
end

--- Deletes the specified custom entity on the server.
-- Service Name - customEntity
-- Service Operation - GET_COUNT
-- 
-- @param entityType The entity type as defined by the user
--        @param whereJson
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:getCount(entityType, whereJson, callback)
	self.client:sendRequest(SERVICE, OPS.GET_COUNT, { entityType = entityType, whereJson = whereJson }, callback)
end

--- Service Name - customEntity
-- Service Operation - GET_RANDOM_ENTITIES_MATCHING
-- 
-- @param entityType The entity type as defined by the user
--        @param whereJson
--        @param maxReturn
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:getRandomEntitiesMatching(entityType, whereJson, maxReturn, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.GET_RANDOM_ENTITIES_MATCHING,
		{ entityType = entityType, whereJson = whereJson, maxReturn = maxReturn },
		callback
	)
end

--- Method uses a paging system to iterate through Custom Entities
-- After retrieving a page of Custom Entities with this method,
-- use GetEntityPageOffset() to retrieve previous or next pages.
-- Service Name - customEntity
-- Service Operation - GET_ENTITY_PAGE
-- 
-- @param entityType The entity type as defined by the user
-- @param context The json context for the page request.
--        See the portal appendix documentation for format.
-- @param callback The callback object
-- 
function CustomEntity:getEntityPage(entityType, context, callback)
	self.client:sendRequest(SERVICE, OPS.GET_ENTITY_PAGE, { entityType = entityType, context = context }, callback)
end

--- Gets the page of custom entities from the server based on the encoded context and specified page offset.
-- Service Name - customEntity
-- Service Operation - GET_ENTITY_PAGE_OFFSET
-- 
-- @param entityType The entity type as defined by the user
--        @param context
--        @param pageOffset
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:getEntityPageOffset(entityType, context, pageOffset, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.GET_ENTITY_PAGE_OFFSET,
		{ entityType = entityType, context = context, pageOffset = pageOffset },
		callback
	)
end

--- Reads the specified custom entity from the server.
-- Service Name - customEntity
-- Service Operation - READ_ENTITY
-- 
-- @param entityType The entity type as defined by the user
-- @param entityId The entity id as defined by the system
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:readEntity(entityType, entityId, callback)
	self.client:sendRequest(SERVICE, OPS.READ_ENTITY, { entityType = entityType, entityId = entityId }, callback)
end

--- Replaces the specified custom entity's data, and optionally updates the acl and expiry, on the server.
-- Service Name - customEntity
-- Service Operation - UPDATE_ENTITY
-- 
-- @param entityType The entity type as defined by the user
--        @param entityId
--        @param version
-- @param jsonEntityData The entity's data as a json string
-- @param jsonEntityAcl The entity's access control list as json. A null acl implies default
--        permissions which make the entity readable/writeable by only the user.
--        @param timeToLive
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:updateEntity(entityType, entityId, version, dataJson, acl, timeToLive, callback)
	local dataOut = { entityType = entityType, entityId = entityId, version = version, timeToLive = timeToLive }
	if dataJson then
		dataOut.dataJson = dataJson
	end
	if acl then
		dataOut.acl = acl
	end

	self.client:sendRequest(SERVICE, OPS.UPDATE_ENTITY, dataOut, callback)
end

--- Replaces the specified custom entity's data, and optionally updates the acl and expiry, on the server.
-- Service Name - customEntity
-- Service Operation - UPDATE_ENTITY_FIELDS
-- 
-- @param entityType The entity type as defined by the user
--        @param entityId
--        @param version
--        @param fieldsJson
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:updateEntityFields(entityType, entityId, version, fieldsJson, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.UPDATE_ENTITY_FIELDS,
		{ entityType = entityType, entityId = entityId, version = version, fieldsJson = fieldsJson },
		callback
	)
end

--- For sharded custom collection entities. Sets the specified fields within custom entity data on the server, enforcing ownership/ACL permissions.
-- Service Name - customEntity
-- Service Operation - UPDATE_ENTITY_FIELDS_SHARDED
-- 
-- @param entityType The entity type as defined by the user
--        @param entityId
--        @param version
--        @param fieldsJson
-- @param shardKeyJson The shard key field(s) and value(s), as JSON, applicable to the entity being updated.
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:updateEntityFieldsSharded(entityType, entityId, version, fieldsJson, shardKeyJson, callback)
	self.client:sendRequest(SERVICE, OPS.UPDATE_ENTITY_FIELDS_SHARDED, {
		entityType = entityType,
		entityId = entityId,
		version = version,
		fieldsJson = fieldsJson,
		shardKeyJson = shardKeyJson,
	}, callback)
end

--- Singleton APIs

--- deletes entities based on the delete criteria.
-- Service Name - customEntity
-- Service Operation - DELETE_ENTITIES
-- 
-- @param entityType The entity type as defined by the user
-- @param deleteCriteria Json string of criteria wanted for deletion
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:deleteEntities(entityType, deleteCriteria, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.DELETE_ENTITIES,
		{ entityType = entityType, deleteCriteria = deleteCriteria },
		callback
	)
end

--- Deletes the specified custom entity singleton, owned by the session's user,
-- for the specified entity type, on the server.
-- Service Name - customEntity
-- Service Operation - DELETE_SINGLETON
-- 
-- @param entityType The entity type as defined by the user
--        @param version
-- 
function CustomEntity:deleteSingleton(entityType, version, callback)
	self.client:sendRequest(SERVICE, OPS.DELETE_SINGLETON, { entityType = entityType, version = version }, callback)
end

--- Reads the custom entity singleton owned by the session's user.
-- Service Name - customEntity
-- Service Operation - READ_SINGLETON
-- 
-- @param entityType The entity type as defined by the user
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:readSingleton(entityType, callback)
	self.client:sendRequest(SERVICE, OPS.READ_SINGLETON, { entityType = entityType }, callback)
end

--- Increments the specified fields, of the singleton owned by the user, by the specified amount within the custom entity data on the server.
-- Service Name - customEntity
-- Service Operation - INCREMENT_SINGLETON_DATA
-- 
-- @param entityType The type of custom entity being updated.
-- @param fieldsJson Specific fields, as JSON, within entity's custom data, with respective increment amount.
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:incrementSingletonData(entityType, fieldsJson, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.INCREMENT_SINGLETON_DATA,
		{ entityType = entityType, fieldsJson = fieldsJson },
		callback
	)
end

--- Updates the singleton owned by the user for the specified custom entity type on the server,
-- creating the singleton if it does not exist.
-- This operation results in the owned singleton's data being completely replaced by the passed in JSON object.
-- Service Name - customEntity
-- Service Operation - UPDATE_SINGLETON
-- 
-- @param entityType The entity type as defined by the user
--        @param version
--        @param dataJson
--        @param acl
--        @param timeToLive
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:updateSingleton(entityType, version, dataJson, acl, timeToLive, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.UPDATE_SINGLETON,
		{ entityType = entityType, version = version, dataJson = dataJson, acl = acl, timeToLive = timeToLive },
		callback
	)
end

--- Partially updates the data, of the singleton owned by the user for the specified custom entity type,
-- with the specified fields, on the server
-- Service Name - customEntity
-- Service Operation - UPDATE_SINGLETON_FIELDS
-- 
-- @param entityType The entity type as defined by the user
--        @param version
--        @param fieldsJson
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:updateSingletonFields(entityType, version, fieldsJson, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.UPDATE_SINGLETON_FIELDS,
		{ entityType = entityType, version = version, fieldsJson = fieldsJson },
		callback
	)
end

--- Increments fields on the specified custom entity owned by the user on the server.
-- Service Name - customEntity
-- Service Operation - INCREMENT_DATA
-- 
-- @param entityType The entity type as defined by the user
-- @param entityId The entity id as defined by the system
-- @param fieldsJson Specific fields, as JSON, within entity's custom data, with respective increment amount.
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:incrementData(entityType, entityId, fieldsJson, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.INCREMENT_DATA,
		{ entityType = entityType, entityId = entityId, fieldsJson = fieldsJson },
		callback
	)
end

--- Deletes the specified custom entity on the server.
-- Service Name - customEntity
-- Service Operation - DELETE_ENTITY
-- 
-- @param entityType The entity type as defined by the user
-- @param jsonEntityData The entity's data as a json string
--        @param version
-- @param callback The method to be invoked when the server response is received
-- 
function CustomEntity:deleteEntity(entityType, entityId, version, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.DELETE_ENTITY,
		{ entityType = entityType, entityId = entityId, version = version },
		callback
	)
end

return CustomEntity

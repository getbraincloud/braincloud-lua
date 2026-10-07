local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local GlobalEntity = {}
GlobalEntity.__index = GlobalEntity

local SERVICE = "globalEntity"

local OPS = {
	CREATE = "CREATE",
	CREATE_WITH_INDEXED_ID = "CREATE_WITH_INDEXED_ID",
	READ = "READ",
	UPDATE = "UPDATE",
	UPDATE_ACL = "UPDATE_ACL",
	UPDATE_TIME_TO_LIVE = "UPDATE_TIME_TO_LIVE",
	DELETE = "DELETE",
	GET_LIST = "GET_LIST",
	GET_LIST_BY_INDEXED_ID = "GET_LIST_BY_INDEXED_ID",
	GET_LIST_COUNT = "GET_LIST_COUNT",
	GET_PAGE = "GET_PAGE",
	GET_PAGE_BY_OFFSET = "GET_PAGE_BY_OFFSET",
	INCREMENT_GLOBAL_ENTITY_DATA = "INCREMENT_GLOBAL_ENTITY_DATA",
	GET_RANDOM_ENTITIES_MATCHING = "GET_RANDOM_ENTITIES_MATCHING",
	UPDATE_ENTITY_INDEXED_ID = "UPDATE_INDEXED_ID",
	UPDATE_ENTITY_OWNER_AND_ACL = "UPDATE_ENTITY_OWNER_AND_ACL",
	MAKE_SYSTEM_ENTITY = "MAKE_SYSTEM_ENTITY",
}

function GlobalEntity.new(client)
	local self = setmetatable({}, GlobalEntity)
	self.client = client
	return self
end


--- Entity APIs

--- Method creates a new entity on the server.
-- Service Name - globalEntity
-- Service Operation - CREATE
-- 
-- @param entityType The entity type as defined by the user
-- @param timeToLive Sets expiry time for entity in milliseconds if > 0
-- @param jsonEntityAcl The entity's access control list as json. A null acl implies default
-- @param jsonEntityData The entity's data as a json string
-- @param callback The callback object
-- 
function GlobalEntity:createEntity(EntityType, TimeToLive, Acl, Data, Callback)
	local Message = { entityType = EntityType, timeToLive = TimeToLive, data = Data }
	if Acl then
		Message.acl = Acl
	end
	self.client:sendRequest(SERVICE, OPS.CREATE, Message, Callback)
end

--- Method creates a new entity on the server with an indexed id.
-- Service Name - globalEntity
-- Service Operation - CREATE_WITH_INDEXED_ID
-- 
-- @param entityType The entity type as defined by the user
-- @param indexedId A secondary ID that will be indexed
-- @param timeToLive Sets expiry time for entity in milliseconds if > 0
-- @param jsonEntityAcl The entity's access control list as json. A null acl implies default
-- @param jsonEntityData The entity's data as a json string
-- @param callback The callback object
-- 
function GlobalEntity:createEntityWithIndexedId(EntityType, IndexedId, TimeToLive, Acl, Data, Callback)
	local Message = { entityType = EntityType, entityIndexedId = IndexedId, timeToLive = TimeToLive, data = Data }
	if Acl then
		Message.acl = Acl
	end
	self.client:sendRequest(SERVICE, OPS.CREATE_WITH_INDEXED_ID, Message, Callback)
end

--- Method deletes an existing entity on the server.
-- Service Name - globalEntity
-- Service Operation - DELETE
-- 
-- @param entityId The entity ID
-- @param version The version of the entity to delete
-- @param callback The callback object
-- 
function GlobalEntity:deleteEntity(EntityId, Version, Callback)
	self.client:sendRequest(SERVICE, OPS.DELETE, { entityId = EntityId, version = Version }, Callback)
end

--- Method gets list of entities from the server base on type and/or where clause
-- Service Name - globalEntity
-- Service Operation - GET_LIST
-- 
-- @param where Mongo style query string
-- @param orderBy Sort order
-- @param maxReturn The maximum number of entities to return
-- @param callback The callback object
-- 
function GlobalEntity:getList(Where, OrderBy, MaxReturn, Callback)
	local Message = { where = Where, maxReturn = MaxReturn }
	if OrderBy then
		Message.orderBy = OrderBy
	end
	self.client:sendRequest(SERVICE, OPS.GET_LIST, Message, Callback)
end

--- Method gets list of entities from the server base on indexed id
-- Service Name - globalEntity
-- Service Operation - GET_LIST_BY_INDEXED_ID
-- 
-- @param entityIndexedId The entity indexed Id
-- @param maxReturn The maximum number of entities to return
-- @param callback The callback object
-- 
function GlobalEntity:getListByIndexedId(EntityIndexedId, MaxReturn, Callback)
	self.client:sendRequest(
		SERVICE,
		OPS.GET_LIST_BY_INDEXED_ID,
		{ entityIndexedId = EntityIndexedId, maxReturn = MaxReturn },
		Callback
	)
end

--- Method gets a count of entities based on the where clause
-- Service Name - globalEntity
-- Service Operation - GET_LIST_COUNT
-- 
-- @param where Mongo style query string
-- @param callback The callback object
-- 
function GlobalEntity:getListCount(Where, Callback)
	self.client:sendRequest(SERVICE, OPS.GET_LIST_COUNT, { where = Where }, Callback)
end

--- Method reads an existing entity from the server.
-- Service Name - globalEntity
-- Service Operation - READ
-- 
-- @param entityId The entity ID
-- @param callback The callback object
-- 
function GlobalEntity:readEntity(EntityId, Callback)
	self.client:sendRequest(SERVICE, OPS.READ, { entityId = EntityId }, Callback)
end

--- Method updates an existing entity on the server.
-- Service Name - globalEntity
-- Service Operation - UPDATE
-- 
-- @param entityId The entity ID
-- @param version The version of the entity to update
-- @param jsonEntityData The entity's data as a json string
-- @param callback The callback object
-- 
function GlobalEntity:updateEntity(EntityId, Version, Data, Callback)
	local Message = { entityId = EntityId, version = Version, data = Data or {} }
	self.client:sendRequest(SERVICE, OPS.UPDATE, Message, Callback)
end

--- Method updates an existing entity's Acl on the server.
-- Service Name - globalEntity
-- Service Operation - UPDATE_ACL
-- 
-- @param entityId The entity ID
-- @param version The version of the entity to update
-- @param jsonEntityAcl The entity's access control list as json.
-- @param callback The callback object
-- 
function GlobalEntity:updateEntityAcl(EntityId, Version, Acl, Callback)
	self.client:sendRequest(SERVICE, OPS.UPDATE_ACL, { entityId = EntityId, acl = Acl, version = Version }, Callback)
end

--- Method updates an existing entity's time to live on the server.
-- Service Name - globalEntity
-- Service Operation - UPDATE_TIME_TO_LIVE
-- 
-- @param entityId The entity ID
-- @param version The version of the entity to update
-- @param timeToLive Sets expiry time for entity in milliseconds if > 0
-- @param callback The callback object
-- 
function GlobalEntity:updateEntityTimeToLive(EntityId, Version, TimeToLive, Callback)
	self.client:sendRequest(
		SERVICE,
		OPS.UPDATE_TIME_TO_LIVE,
		{ entityId = EntityId, version = Version, timeToLive = TimeToLive },
		Callback
	)
end

--- Method uses a paging system to iterate through Global Entities
-- After retrieving a page of Global Entities with this method,
-- use GetPageOffset() to retrieve previous or next pages.
-- Service Name - globalEntity
-- Service Operation - GET_PAGE
-- 
-- @param context The json context for the page request.
--        See the portal appendix documentation for format.
-- @param callback The callback object
-- 
function GlobalEntity:getPage(Context, Callback)
	self.client:sendRequest(SERVICE, OPS.GET_PAGE, { context = Context }, Callback)
end

--- Method to retrieve previous or next pages after having called the GetPage method.
-- Service Name - globalEntity
-- Service Operation - GET_PAGE_BY_OFFSET
-- 
-- @param context The context string returned from the server from a
--        previous call to GetPage or GetPageOffset
-- @param pageOffset The positive or negative page offset to fetch. Uses the last page
--        retrieved using the context string to determine a starting point.
-- @param callback The callback object
-- 
function GlobalEntity:getPageOffset(Context, PageOffset, Callback)
	self.client:sendRequest(SERVICE, OPS.GET_PAGE_BY_OFFSET, { context = Context, pageOffset = PageOffset }, Callback)
end

--- Partial increment of global entity data field items. Partial set of items incremented as specified.
-- Service Name - globalEntity
-- Service Operation - INCREMENT_GLOBAL_ENTITY_DATA
-- 
-- @param entityId The id of the entity to update
-- @param jsonData The entity's data object
-- @param callback The callback object
-- 
function GlobalEntity:incrementGlobalEntityData(EntityId, Data, Callback)
	self.client:sendRequest(SERVICE, OPS.INCREMENT_GLOBAL_ENTITY_DATA, { entityId = EntityId, data = Data }, Callback)
end

--- Gets a list of up to randomCount randomly selected entities from the server based on the where condition and specified maximum return count.
-- Service Name - globalEntity
-- Service Operation - GET_RANDOM_ENTITIES_MATCHING
-- 
-- @param where Mongo style query string
-- @param maxReturn The maximum number of entities to return
-- @param callback The callback object
-- 
function GlobalEntity:getRandomEntitiesMatching(Where, MaxReturn, Callback)
	self.client:sendRequest(SERVICE, OPS.GET_RANDOM_ENTITIES_MATCHING, { where = Where, maxReturn = MaxReturn }, Callback)
end

--- Method updates an existing entity's Indexed Id
-- Service Name - globalEntity
-- Service Operation - UPDATE_ENTITY_OWNER_AND_ACL
-- 
-- @param entityId The entity ID
-- @param version The version of the entity to update
-- @param entityIndexedId the id index of the entity
-- @param callback The callback object
-- 
function GlobalEntity:updateEntityIndexedId(EntityId, Version, EntityIndexedId, Callback)
	local Message = { entityId = EntityId, version = Version, entityIndexedId = EntityIndexedId }
	self.client:sendRequest(SERVICE, OPS.UPDATE_ENTITY_INDEXED_ID, Message, Callback)
end

--- Method updates an existing entity's Owner and ACL on the server.
-- Service Name - globalEntity
-- Service Operation - UPDATE_ENTITY_OWNER_AND_ACL
-- 
-- @param entityId The entity ID
-- @param version The version of the entity to update
-- @param ownerId The owner ID
-- @param jsonEntityAcl The entity's access control list as JSON.
-- @param callback The callback object
-- 
function GlobalEntity:updateEntityOwnerAndAcl(EntityId, Version, OwnerId, Acl, Callback)
	local Message = { entityId = EntityId, version = Version, ownerId = OwnerId, acl = Acl }
	self.client:sendRequest(SERVICE, OPS.UPDATE_ENTITY_OWNER_AND_ACL, Message, Callback)
end

--- Method clears the owner id of an existing entity and sets the ACL on the server.
-- Service Name - globalEntity
-- Service Operation - MAKE_SYSTEM_ENTITY
-- 
-- @param entityId The entity ID
-- @param version The version of the entity to update
-- @param jsonEntityAcl The entity's access control list as JSON.
-- @param callback The callback object
-- 
function GlobalEntity:makeSystemEntity(EntityId, Version, Acl, Callback)
	self.client:sendRequest(SERVICE, OPS.MAKE_SYSTEM_ENTITY, { entityId = EntityId, version = Version, acl = Acl }, Callback)
end

return GlobalEntity

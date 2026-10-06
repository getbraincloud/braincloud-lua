--- Test_Entity.lua
--- Server integration tests for Entity service
local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Entity", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")
	local entity = client.entity
	assert(entity, "Entity module missing")

	local getPageContext = ""
	local createdEntityId = ""
	local sharedCreatedEntityId = ""

	local tests = {
		--- 1. CreateEntity
		{
			name = "CreateEntity",
			fn = function()
				local acl = { other = 1 }
				local s, res = TestUtils.await("CreateEntity", function(r)
					entity:createEntity("TestType", { value = 123 }, acl, r)
				end)
				assert(s, "CreateEntity failed")
				assert(res.data and type(res.data.entityId) == "string", "EntityId Missing")
				createdEntityId = res.data.entityId
			end,
		},

		--- 2. CreateSharedEntity
		{
			name = "CreateSharedEntity",
			fn = function()
				local acl = { other = 2 }
				local s, res = TestUtils.await("CreateSharedEntity", function(r)
					entity:createEntity("TestType", { value = 123 }, acl, r)
				end)
				assert(s, "CreateSharedEntity failed")
				assert(res.data and type(res.data.entityId) == "string", "EntityId Missing")
				sharedCreatedEntityId = res.data.entityId
			end,
		},

		--- 3. ReadEntity
		{
			name = "ReadEntity",
			fn = function()
				local s, res = TestUtils.await("ReadEntity", function(r)
					entity:getEntity(createdEntityId, r)
				end)
				assert(s, "ReadEntity failed")
				assert(res.data.entityId == createdEntityId, "EntityId mismatch")
			end,
		},

		--- 4. ReadEntitiesByType
		{
			name = "ReadEntitiesByType",
			fn = function()
				local s, res = TestUtils.await("ReadEntitiesByType", function(r)
					entity:getEntitiesByType("TestType", r)
				end)
				assert(s, "ReadEntitiesByType failed")
				assert(type(res.data.entities) == "table", "Expected entities table")
			end,
		},

		--- 5. ReadSharedEntity
		{
			name = "ReadSharedEntity",
			fn = function()
				local s, res = TestUtils.await("ReadSharedEntity", function(r)
					entity:getSharedEntityForProfileId(client.profileId, sharedCreatedEntityId, r)
				end)
				assert(s, "ReadSharedEntity failed")
				assert(res.data.entityId == sharedCreatedEntityId, "SharedEntityId mismatch")
			end,
		},

		--- 6. ReadSharedEntities
		{
			name = "ReadSharedEntities",
			fn = function()
				local s, res = TestUtils.await("ReadSharedEntities", function(r)
					entity:getSharedEntitiesForProfileId(client.profileId, r)
				end)
				assert(s, "ReadSharedEntities failed")
				assert(type(res.data.entities) == "table", "Expected shared entities table")
			end,
		},

		--- 7. ReadSharedEntitiesList
		{
			name = "ReadSharedEntitiesList",
			fn = function()
				local s, res = TestUtils.await("ReadSharedEntitiesList", function(r)
					entity:getSharedEntitiesListForProfileId(client.profileId, nil, nil, 5, r)
				end)
				assert(s, "ReadSharedEntitiesList failed")
				assert(type(res.data.entities) == "table", "Expected entities list")
			end,
		},

		--- 8. UpdateSingleton
		{
			name = "UpdateSingleton",
			fn = function()
				local acl = { other = 1 }
				local s, res = TestUtils.await("UpdateSingleton", function(r)
					entity:updateSingleton("SingletonType", { value = 555 }, acl, -1, r)
				end)
				assert(s, "UpdateSingleton failed")
			end,
		},

		--- 9. ReadSingleton
		{
			name = "ReadSingleton",
			fn = function()
				local s, res = TestUtils.await("ReadSingleton", function(r)
					entity:getSingleton("SingletonType", r)
				end)
				assert(s, "ReadSingleton failed")
				assert(res.data and res.data.entityType == "SingletonType", "SingletonType mismatch")
			end,
		},

		--- 10. UpdateEntity
		{
			name = "UpdateEntity",
			fn = function()
				local acl = { other = 1 }
				local s, res = TestUtils.await("UpdateEntity", function(r)
					entity:updateEntity(createdEntityId, "TestType", { value = 999 }, acl, -1, r)
				end)
				assert(s, "UpdateEntity failed")
			end,
		},

		--- 11. UpdateSharedEntity
		{
			name = "UpdateSharedEntity",
			fn = function()
				local s, res = TestUtils.await("UpdateSharedEntity", function(r)
					entity:updateSharedEntity(
						sharedCreatedEntityId,
						client.profileId,
						"TestType",
						{ value = 777 },
						-1,
						r
					)
				end)
				assert(s, "UpdateSharedEntity failed")
			end,
		},

		--- 12. IncrementUserEntityData
		{
			name = "IncrementUserEntityData",
			fn = function()
				local s, res = TestUtils.await("IncrementUserEntityData", function(r)
					entity:incrementUserEntityData(createdEntityId, { score = 1 }, r)
				end)
				assert(s, "IncrementUserEntityData failed")
			end,
		},

		--- 13. IncrementSharedUserEntityData
		{
			name = "IncrementSharedUserEntityData",
			fn = function()
				local s, res = TestUtils.await("IncrementSharedUserEntityData", function(r)
					entity:incrementSharedUserEntityData(sharedCreatedEntityId, client.profileId, { score = 1 }, r)
				end)
				assert(s, "IncrementSharedUserEntityData failed")
			end,
		},

		--- 14. DeleteEntity
		{
			name = "DeleteEntity",
			fn = function()
				local s, res = TestUtils.await("DeleteEntity", function(r)
					entity:deleteEntity(createdEntityId, -1, r)
				end)
				assert(s, "DeleteEntity failed")
			end,
		},

		--- 15. DeleteSingleton
		{
			name = "DeleteSingleton",
			fn = function()
				local s, res = TestUtils.await("DeleteSingleton", function(r)
					entity:deleteSingleton("SingletonType", -1, r)
				end)
				assert(s, "DeleteSingleton failed")
			end,
		},

		--- 16. GetList
		{
			name = "GetList",
			fn = function()
				local s, res = TestUtils.await("GetList", function(r)
					entity:getList({ entityType = "TestType" }, { createdAt = 1 }, 5, r)
				end)
				assert(s, "GetList failed")
				assert(type(res.data.entityList) == "table", "Expected entities table")
			end,
		},

		--- 17. GetListCount
		{
			name = "GetListCount",
			fn = function()
				local s, res = TestUtils.await("GetListCount", function(r)
					entity:getListCount({ entityType = "TestType" }, r)
				end)
				assert(s, "GetListCount failed")
				assert(type(res.data.entityListCount) == "number", "Expected count number")
			end,
		},

		--- 18. GetPage
		{
			name = "GetPage",
			fn = function()
				local s, res = TestUtils.await("GetPage", function(r)
					entity:getPage({
						pagination = { rowsPerPage = 5, pageNumber = 1 },
						searchCriteria = { entityType = "TestType" },
						sortCriteria = { createdAt = 1 },
					}, r)
				end)
				assert(s, "GetPage failed")
				assert(res.data.context, "Missing Context")
				getPageContext = res.data.context
			end,
		},

		--- 19. GetPageOffset
		{
			name = "GetPageOffset",
			fn = function()
				local s, res = TestUtils.await("GetPageOffset", function(r)
					entity:getPageOffset(getPageContext, 1, r)
				end)
				assert(s, "GetPageOffset failed")
				assert(type(res.data.results.items) == "table", "Expected entities table")
			end,
		},

		--- 20. BadUpdate (negative path — invalid entityId should fail)
		{
			name = "BadUpdate",
			fn = function()
				local s, res = TestUtils.await("BadUpdate", function(r)
					entity:updateEntity("bad-entity-id-wakawaka", "TestType", { value = 0 }, { other = 1 }, -1, r)
				end)
				assert(not s, "BadUpdate should have failed but succeeded")
				assert(res and res.status == 404 or (res and res.reason_code == 40332),
					"Expected 404/40332, got: " .. tostring(res and res.status))
			end,
		},
	}
	return tests
end)

--- Test_GlobalEntity.lua
--- Server integration tests for GlobalEntity service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("GlobalEntity", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")
	local globalEntity = client.globalEntity
	assert(globalEntity, "GlobalEntity module missing")

	local getPageContext = ""
	local createdEntityId = ""
	local indexedEntityId = ""
	local secondEntityId = ""
	local tests = {
		--- 1. CreateEntity
		{
			name = "CreateEntity",
			fn = function()
				local acl = { other = 1 }
				local s, res = TestUtils.await("CreateEntity", function(r)
					globalEntity:createEntity("testGlobalEntity", 60000, acl, { value = 123 }, r)
				end)
				assert(s, "CreateEntity failed")
				assert(res.data.entityId, "EntityId Missing")
				createdEntityId = res.data.entityId
			end,
		},

		--- 2. CreateEntityWithIndexedId
		{
			name = "CreateEntityWithIndexedId",
			fn = function()
				local acl = { other = 1 }
				local s, res = TestUtils.await("CreateEntityWithIndexedId", function(r)
					globalEntity:createEntityWithIndexedId("testGlobalEntity", "indexed123", 60000, acl, { value = 456 }, r)
				end)
				assert(s, "CreateEntityWithIndexedId failed")
				assert(res.data.entityId, "EntityId Missing")
				indexedEntityId = res.data.entityId
			end,
		},

		--- 3. ReadEntity
		{
			name = "ReadEntity",
			fn = function()
				local s, res = TestUtils.await("ReadEntity", function(r)
					globalEntity:readEntity(createdEntityId, r)
				end)
				assert(s, "ReadEntity failed")
				assert(res.data.entityId, "EntityId Missing")
			end,
		},

		--- 4. UpdateEntity
		{
			name = "UpdateEntity",
			fn = function()
				local s, res = TestUtils.await("UpdateEntity", function(r)
					globalEntity:updateEntity(createdEntityId, -1, { value = 999 }, r)
				end)
				assert(s, "UpdateEntity failed")
				assert(res.data.entityId, "EntityId Missing")
			end,
		},

		--- 5. UpdateEntityAcl
		{
			name = "UpdateEntityAcl",
			fn = function()
				local acl = { other = 2 }
				local s, res = TestUtils.await("UpdateEntityAcl", function(r)
					globalEntity:updateEntityAcl(createdEntityId, -1, acl, r)
				end)
				assert(s, "UpdateEntityAcl failed")
				assert(res.data.entityId, "EntityId Missing")
			end,
		},

		--- 6. UpdateEntityTimeToLive
		{
			name = "UpdateEntityTimeToLive",
			fn = function()
				local s, res = TestUtils.await("UpdateEntityTimeToLive", function(r)
					globalEntity:updateEntityTimeToLive(createdEntityId, -1, 120000, r)
				end)
				assert(s, "UpdateEntityTimeToLive failed")
				assert(res.data.entityId, "EntityId Missing")
			end,
		},

		--- 7. GetList
		{
			name = "GetList",
			fn = function()
				local s, res = TestUtils.await("GetList", function(r)
					globalEntity:getList({ entityType = "testGlobalEntity" }, { createdAt = 1 }, 5, r)
				end)
				assert(s, "GetList failed")
				assert(type(res.data.entityList) == "table", "Expected entityList table")
			end,
		},

		--- 8. GetListByIndexedId
		{
			name = "GetListByIndexedId",
			fn = function()
				local s, res = TestUtils.await("GetListByIndexedId", function(r)
					globalEntity:getListByIndexedId("indexed123", 5, r)
				end)
				assert(s, "GetListByIndexedId failed")
				assert(type(res.data.entityList) == "table", "Expected entityList table")
			end,
		},

		--- 9. GetListCount
		{
			name = "GetListCount",
			fn = function()
				local s, res = TestUtils.await("GetListCount", function(r)
					globalEntity:getListCount({ entityType = "testGlobalEntity" }, r)
				end)
				assert(s, "GetListCount failed")
				assert(res.data.entityListCount, "Expected entityListCount")
			end,
		},

		--- 10. GetPage
		{
			name = "GetPage",
			fn = function()
				local s, res = TestUtils.await("GetPage", function(r)
					globalEntity:getPage({
						pagination = { rowsPerPage = 5, pageNumber = 1 },
						searchCriteria = { entityType = "testGlobalEntity" },
						sortCriteria = { createdAt = 1 },
					}, r)
				end)
				assert(s, "GetPage failed")
				assert(res.data.context, "Missing context")
				getPageContext = res.data.context
			end,
		},

		--- 11. GetPageOffset
		{
			name = "GetPageOffset",
			fn = function()
				local s, res = TestUtils.await("GetPageOffset", function(r)
					globalEntity:getPageOffset(getPageContext, 1, r)
				end)
				assert(s, "GetPageOffset failed")
				assert(type(res.data.results.items) == "table", "Expected items table")
			end,
		},

		--- 12. IncrementGlobalEntityData
		{
			name = "IncrementGlobalEntityData",
			fn = function()
				local acl = { other = 1 }
				local s1, res1 = TestUtils.await("CreateForIncrement", function(r)
					globalEntity:createEntity("testGlobalEntity", 60000, acl, { counter = 0 }, r)
				end)
				assert(s1, "CreateEntity for increment failed")
				secondEntityId = res1.data.entityId

				local s2, res2 = TestUtils.await("IncrementGlobalEntityData", function(r)
					globalEntity:incrementGlobalEntityData(secondEntityId, { counter = 5 }, r)
				end)
				assert(s2, "IncrementGlobalEntityData failed")

				local s3 = TestUtils.await("DeleteIncrementEntity", function(r)
					globalEntity:deleteEntity(secondEntityId, -1, r)
				end)
				assert(s3, "DeleteEntity after increment failed")
			end,
		},

		--- 13. GetRandomEntitiesMatching
		{
			name = "GetRandomEntitiesMatching",
			fn = function()
				local s, res = TestUtils.await("GetRandomEntitiesMatching", function(r)
					globalEntity:getRandomEntitiesMatching({ entityType = "testGlobalEntity" }, 5, r)
				end)
				assert(s, "GetRandomEntitiesMatching failed")
				assert(type(res.data.entityList) == "table", "Expected entityList table")
			end,
		},

		--- 14. UpdateEntityIndexedId
		{
			name = "UpdateEntityIndexedId",
			fn = function()
				local s, res = TestUtils.await("UpdateEntityIndexedId", function(r)
					globalEntity:updateEntityIndexedId(indexedEntityId, -1, "indexed456", r)
				end)
				assert(s, "UpdateEntityIndexedId failed")
				assert(res.data.entityId, "EntityId Missing")
			end,
		},

		--- 15. UpdateEntityOwnerAndAcl
		{
			name = "UpdateEntityOwnerAndAcl",
			fn = function()
				local s, res = TestUtils.await("UpdateEntityOwnerAndAcl", function(r)
					globalEntity:updateEntityOwnerAndAcl(
						indexedEntityId,
						-1,
						TestUtils.TEST_USER_OPP_PROFILE_ID,
						{ other = 2 },
						r
					)
				end)
				assert(s, "UpdateEntityOwnerAndAcl failed")
				assert(res.data.entityId, "EntityId Missing")
			end,
		},

		--- 16. MakeSystemEntity
		{
			name = "MakeSystemEntity",
			fn = function()
				local acl = { other = 1 }
				local s1, res1 = TestUtils.await("CreateForSystem", function(r)
					globalEntity:createEntity("testGlobalEntity", 60000, acl, { sysField = true }, r)
				end)
				assert(s1, "CreateEntity for MakeSystemEntity failed")
				local sysEntityId = res1.data.entityId

				local s2 = TestUtils.await("MakeSystemEntity", function(r)
					globalEntity:makeSystemEntity(sysEntityId, -1, { other = 1 }, r)
				end)
				assert(s2, "MakeSystemEntity failed")
			end,
		},

		--- 17. DeleteEntity (indexed) — separate await for each delete
		{
			name = "DeleteCreatedEntity",
			fn = function()
				local s, res = TestUtils.await("DeleteCreatedEntity", function(r)
					globalEntity:deleteEntity(createdEntityId, -1, r)
				end)
				assert(s, "DeleteEntity (created) failed")
				assert(res.status == 200, "Expected status 200")
			end,
		},

		{
			name = "DeleteIndexedEntity",
			fn = function()
				local s, res = TestUtils.await("DeleteIndexedEntity", function(r)
					globalEntity:deleteEntity(indexedEntityId, -1, r)
				end)
				assert(s, "DeleteEntity (indexed) failed")
				assert(res.status == 200, "Expected status 200")
			end,
		},
	}

	return tests
end)

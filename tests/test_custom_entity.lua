--- Test_Custom_Entity.lua
--- Server integration tests for BrainCloud CustomEntity
--- Mirrors C# TestCustomEntityService.cs (custom entity type "athletes" on app 20001)

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("CustomEntity", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")

	local customEntity = client.customEntity
	local ENTITY_TYPE = "athletes"

	local function call(tag, fn)
		local s, r = TestUtils.await(tag, fn)
		return TestUtils.assertOk(tag, s, r)
	end

	local function createEntity(data)
		local r = call("CreateEntity", function(cb)
			customEntity:createEntity(ENTITY_TYPE, data or { test = "Testing" }, { other = 1 }, nil, true, cb)
		end)
		return r.data
	end

	local function test(name, fn)
		return { name = name, fn = fn }
	end

	return {
		test("CreateEntity", function()
			createEntity()
		end),
		test("GetEntityPage", function()
			call("GetEntityPage", function(cb)
				customEntity:getEntityPage(ENTITY_TYPE, { pagination = { rowsPerPage = 125, pageNumber = 1 } }, cb)
			end)
		end),
		test("GetEntityPageOffset", function()
			local r = call("GetEntityPage", function(cb)
				customEntity:getEntityPage(ENTITY_TYPE, { pagination = { rowsPerPage = 1, pageNumber = 1 } }, cb)
			end)
			call("GetEntityPageOffset", function(cb)
				customEntity:getEntityPageOffset(ENTITY_TYPE, r.data.context, 1, cb)
			end)
		end),
		test("ReadEntity", function()
			local entity = createEntity()
			call("ReadEntity", function(cb)
				customEntity:readEntity(ENTITY_TYPE, entity.entityId, cb)
			end)
		end),
		test("UpdateEntity", function()
			local entity = createEntity()
			call("UpdateEntity", function(cb)
				customEntity:updateEntity(ENTITY_TYPE, entity.entityId, 1, { test = "Testing" }, { other = 1 }, nil, cb)
			end)
		end),
		test("DeleteEntity", function()
			local entity = createEntity()
			call("DeleteEntity", function(cb)
				customEntity:deleteEntity(ENTITY_TYPE, entity.entityId, entity.version, cb)
			end)
		end),
		test("UpdateEntityFields", function()
			local entity = createEntity()
			call("UpdateEntityFields", function(cb)
				customEntity:updateEntityFields(ENTITY_TYPE, entity.entityId, entity.version, { test = "Testing" }, cb)
			end)
		end),
		test("UpdateEntityFieldsSharded", function()
			local entity = createEntity({ GamesPlayed = 2, Name = "Zoro", Goals = 7 })
			call("UpdateEntityFieldsSharded", function(cb)
				customEntity:updateEntityFieldsSharded(
					ENTITY_TYPE,
					entity.entityId,
					1,
					{ GamesPlayedTotal = 2, Goals = 10 },
					{ ownerId = entity.ownerId },
					cb
				)
			end)
		end),
		test("IncrementData", function()
			local entity = createEntity()
			call("IncrementData", function(cb)
				customEntity:incrementData(ENTITY_TYPE, entity.entityId, { goals = 3, assists = 5 }, cb)
			end)
		end),
		test("IncrementSingletonData", function()
			createEntity()
			call("IncrementSingletonData", function(cb)
				customEntity:incrementSingletonData(ENTITY_TYPE, { goals = 3, assists = 5 }, cb)
			end)
		end),
		test("DeleteEntities", function()
			call("DeleteEntities", function(cb)
				customEntity:deleteEntities(ENTITY_TYPE, { entityId = "Testing" }, cb)
			end)
		end),
		test("GetCount", function()
			call("GetCount", function(cb)
				customEntity:getCount(ENTITY_TYPE, { ["data.position"] = "defense" }, cb)
			end)
		end),
		test("GetRandomEntitiesMatching", function()
			call("GetRandomEntitiesMatching", function(cb)
				customEntity:getRandomEntitiesMatching(ENTITY_TYPE, { ["data.position"] = "defense" }, 2, cb)
			end)
		end),
		test("UpdateSingleton", function()
			call("UpdateSingleton", function(cb)
				customEntity:updateSingleton(ENTITY_TYPE, 1, { ["data.position"] = "defense" }, { other = 1 }, nil, cb)
			end)
		end),
		test("UpdateSingletonFields", function()
			call("UpdateSingletonFields", function(cb)
				customEntity:updateSingletonFields(ENTITY_TYPE, -1, { ["data.position"] = "defense" }, cb)
			end)
		end),
		test("ReadSingleton", function()
			call("ReadSingleton", function(cb)
				customEntity:readSingleton(ENTITY_TYPE, cb)
			end)
		end),
		test("DeleteSingleton", function()
			call("DeleteSingleton", function(cb)
				customEntity:deleteSingleton(ENTITY_TYPE, 1, cb)
			end)
		end),
	}
end)

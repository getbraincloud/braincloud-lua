local TestUtils = require("tests.shared")


return TestUtils.buildRunner("ItemCatalog", nil, function(client)
	local catalog = client.itemCatalog
	assert(catalog, "ItemCatalog module missing")

	local listContext

	return {
		{
			name = "GetCatalogItemDefinition",
			fn = function()
				local exampleItemId = "sword001" -- same as C#

				local success, res = TestUtils.await("GetCatalogItemDefinition", function(r)
					catalog:getCatalogItemDefinition(exampleItemId, r)
				end)

				assert(success, "GetCatalogItemDefinition failed")
				assert(res.data.defId == exampleItemId, "Unexpected defId in response")
			end,
		},

		{
			name = "GetCatalogItemsPage",
			fn = function()
				local s, res = TestUtils.await("GetCatalogItemsPage", function(r)
					catalog:getCatalogItemsPage({ page = 1 }, r)
				end)

				assert(s, "GetCatalogItemsPage failed")
				if res.data and res.data.context then
					listContext = res.data.context
				end
			end,
		},

		{
			name = "GetCatalogItemsPageOffset",
			fn = function()
				local context = listContext or ""
				local s, res = TestUtils.await("GetCatalogItemsPageOffset", function(r)
					catalog:getCatalogItemsPageOffset(context, 0, r)
				end)

				assert(s, "GetCatalogItemsPageOffset failed")
				assert(type(res.data.results.items) == "table", "Expected items table")
			end,
		},
	}
end)

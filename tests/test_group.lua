--- Test_Group.lua
--- Server integration tests for BrainCloud Group
--- Mirrors C# TestGroup.cs (UserA owns the group, UserB is invited / joins)

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Group", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")

	local group = client.group
	local GROUP_TYPE = "test"
	local ENTITY_TYPE = "test"
	local READ_WRITE_ACL = { member = 2, other = 2 }

	local groupId = nil

	local function call(tag, fn)
		local s, r = TestUtils.await(tag, fn)
		return TestUtils.assertOk(tag, s, r)
	end

	local function as(userKey)
		TestUtils.authenticateAs(client, userKey)
	end

	local function profileId(userKey)
		return TestUtils.users[userKey].profileId
	end

	local function createGroup(isOpen)
		local r = call("CreateGroup", function(cb)
			group:createGroup(
				"testGroup",
				GROUP_TYPE,
				isOpen == true,
				READ_WRITE_ACL,
				{ testInc = 123 },
				{ test = "test" },
				{ test = "test" },
				cb
			)
		end)
		groupId = r.data.groupId
	end

	local function createGroupWithSummaryData()
		local r = call("CreateGroupWithSummaryData", function(cb)
			group:createGroupWithSummaryData(
				"testGroup",
				GROUP_TYPE,
				false,
				READ_WRITE_ACL,
				{ testInc = 123 },
				{ test = "test" },
				{ test = "test" },
				{ summaryData = "summary" },
				cb
			)
		end)
		groupId = r.data.groupId
	end

	local function createGroupEntity()
		local r = call("CreateGroupEntity", function(cb)
			group:createGroupEntity(groupId, ENTITY_TYPE, false, READ_WRITE_ACL, { testInc = 123 }, cb)
		end)
		return r.data.entityId
	end

	local function deleteGroup()
		if groupId then
			call("DeleteGroup", function(cb)
				group:deleteGroup(groupId, -1, cb)
			end)
			groupId = nil
		end
	end

	local function createGroupAsUserA(isOpen)
		as("A")
		createGroup(isOpen)
	end

	local function deleteGroupAsUserA()
		as("A")
		deleteGroup()
	end

	local function context(searchKey, searchValue)
		return {
			pagination = { rowsPerPage = 1, pageNumber = 1 },
			searchCriteria = { [searchKey] = searchValue },
		}
	end

	-- each test runs as UserA; always tidy up the group, even when an assert fails
	local function test(name, fn)
		return {
			name = name,
			fn = function()
				groupId = nil
				local ok, err = pcall(fn)
				if groupId then
					pcall(deleteGroupAsUserA)
				end
				if not ok then
					error(err, 0)
				end
			end,
		}
	end

	return {
		test("AcceptGroupInvitation", function()
			createGroup()
			call("InviteGroupMember", function(cb)
				group:inviteGroupMember(groupId, profileId("B"), "ADMIN", nil, cb)
			end)
			as("B")
			call("AcceptGroupInvitation", function(cb)
				group:acceptGroupInvitation(groupId, cb)
			end)
		end),
		test("AddGroupMember", function()
			createGroup()
			call("AddGroupMember", function(cb)
				group:addGroupMember(groupId, profileId("B"), "ADMIN", nil, cb)
			end)
		end),
		test("ApproveGroupJoinRequest", function()
			createGroupAsUserA()
			as("B")
			call("JoinGroup", function(cb)
				group:joinGroup(groupId, cb)
			end)
			as("A")
			call("ApproveGroupJoinRequest", function(cb)
				group:approveGroupJoinRequest(groupId, profileId("B"), "MEMBER", nil, cb)
			end)
		end),
		test("AutoJoinGroup", function()
			createGroupAsUserA(true)
			as("B")
			call("AutoJoinGroup", function(cb)
				group:autoJoinGroup(GROUP_TYPE, "JoinFirstGroup", nil, cb)
			end)
		end),
		test("AutoJoinGroupMulti", function()
			createGroupAsUserA(true)
			as("B")
			call("AutoJoinGroupMulti", function(cb)
				group:autoJoinGroupMulti({ GROUP_TYPE, GROUP_TYPE }, "JoinFirstGroup", nil, cb)
			end)
		end),
		test("CancelGroupInvitation", function()
			createGroup()
			call("InviteGroupMember", function(cb)
				group:inviteGroupMember(groupId, profileId("B"), "ADMIN", nil, cb)
			end)
			call("CancelGroupInvitation", function(cb)
				group:cancelGroupInvitation(groupId, profileId("B"), cb)
			end)
		end),
		test("CreateGroup", function()
			createGroup()
			deleteGroup()
		end),
		test("CreateGroupWithSummaryData", function()
			createGroupWithSummaryData()
			deleteGroup()
		end),
		test("CreateGroupEntity", function()
			createGroup()
			createGroupEntity()
		end),
		test("DeleteGroup", function()
			createGroup()
			deleteGroup()
		end),
		test("DeleteGroupEntity", function()
			createGroup()
			local entityId = createGroupEntity()
			call("DeleteGroupEntity", function(cb)
				group:deleteGroupEntity(groupId, entityId, 1, cb)
			end)
		end),
		test("GetMyGroups", function()
			createGroup()
			call("GetMyGroups", function(cb)
				group:getMyGroups(cb)
			end)
		end),
		test("IncrementGroupData", function()
			createGroup()
			call("IncrementGroupData", function(cb)
				group:incrementGroupData(groupId, { testInc = 1 }, cb)
			end)
		end),
		test("IncrementGroupEntityData", function()
			createGroup()
			local entityId = createGroupEntity()
			call("IncrementGroupEntityData", function(cb)
				group:incrementGroupEntityData(groupId, entityId, { testInc = 1 }, cb)
			end)
		end),
		test("InviteGroupMember", function()
			createGroup()
			call("InviteGroupMember", function(cb)
				group:inviteGroupMember(groupId, profileId("B"), "MEMBER", nil, cb)
			end)
		end),
		test("JoinGroup", function()
			createGroupAsUserA()
			as("B")
			call("JoinGroup", function(cb)
				group:joinGroup(groupId, cb)
			end)
		end),
		test("LeaveGroup", function()
			createGroup()
			call("LeaveGroup", function(cb)
				group:leaveGroup(groupId, cb)
			end)
			local s, r = TestUtils.await("ReadGroup after leave", function(cb)
				group:readGroup(groupId, cb)
			end)
			-- the owner leaving deletes the group
			groupId = nil
			TestUtils.assertFail("ReadGroup after leave", s, r, 400, 40345)
		end),
		test("ListGroupsPage", function()
			call("ListGroupsPage", function(cb)
				group:listGroupsPage(context("groupType", GROUP_TYPE), cb)
			end)
		end),
		test("ListGroupsPageByOffset", function()
			local r = call("ListGroupsPage", function(cb)
				group:listGroupsPage(context("groupType", GROUP_TYPE), cb)
			end)
			call("ListGroupsPageByOffset", function(cb)
				group:listGroupsPageByOffset(r.data.context, 1, cb)
			end)
		end),
		test("ListGroupsWithMember", function()
			call("ListGroupsWithMember", function(cb)
				group:listGroupsWithMember(profileId("A"), cb)
			end)
		end),
		test("ReadGroup", function()
			createGroup()
			call("ReadGroup", function(cb)
				group:readGroup(groupId, cb)
			end)
		end),
		test("ReadGroupData", function()
			createGroup()
			call("ReadGroupData", function(cb)
				group:readGroupData(groupId, cb)
			end)
		end),
		test("ReadGroupEntitiesPage", function()
			createGroup()
			call("ReadGroupEntitiesPage", function(cb)
				group:readGroupEntitiesPage(context("groupId", groupId), cb)
			end)
		end),
		test("ReadGroupEntitiesPageByOffset", function()
			createGroup()
			local r = call("ReadGroupEntitiesPage", function(cb)
				group:readGroupEntitiesPage(context("groupId", groupId), cb)
			end)
			call("ReadGroupEntitiesPageByOffset", function(cb)
				group:readGroupEntitiesPageByOffset(r.data.context, 1, cb)
			end)
		end),
		test("ReadGroupEntity", function()
			createGroup()
			local entityId = createGroupEntity()
			call("ReadGroupEntity", function(cb)
				group:readGroupEntity(groupId, entityId, cb)
			end)
		end),
		test("ReadGroupMembers", function()
			createGroup()
			call("ReadGroupMembers", function(cb)
				group:readGroupMembers(groupId, cb)
			end)
		end),
		test("RejectGroupInvitation", function()
			createGroup()
			call("InviteGroupMember", function(cb)
				group:inviteGroupMember(groupId, profileId("B"), "ADMIN", nil, cb)
			end)
			as("B")
			call("RejectGroupInvitation", function(cb)
				group:rejectGroupInvitation(groupId, cb)
			end)
		end),
		test("RejectGroupJoinRequest", function()
			createGroupAsUserA()
			as("B")
			call("JoinGroup", function(cb)
				group:joinGroup(groupId, cb)
			end)
			as("A")
			call("RejectGroupJoinRequest", function(cb)
				group:rejectGroupJoinRequest(groupId, profileId("B"), cb)
			end)
		end),
		test("RemoveGroupMember", function()
			createGroupAsUserA(true)
			as("B")
			call("JoinGroup", function(cb)
				group:joinGroup(groupId, cb)
			end)
			as("A")
			call("RemoveGroupMember", function(cb)
				group:removeGroupMember(groupId, profileId("B"), cb)
			end)
		end),
		test("UpdateGroupData", function()
			createGroup()
			call("UpdateGroupData", function(cb)
				group:updateGroupData(groupId, 1, { testUpdate = 1 }, cb)
			end)
		end),
		test("UpdateGroupEntity", function()
			createGroup()
			local entityId = createGroupEntity()
			call("UpdateGroupEntityData", function(cb)
				group:updateGroupEntityData(groupId, entityId, 1, { testUpdate = 1 }, cb)
			end)
		end),
		test("UpdateGroupMember", function()
			createGroup()
			call("UpdateGroupMember", function(cb)
				group:updateGroupMember(groupId, profileId("A"), nil, nil, cb)
			end)
		end),
		test("UpdateGroupName", function()
			createGroup()
			call("UpdateGroupName", function(cb)
				group:updateGroupName(groupId, "testName", cb)
			end)
		end),
		test("SetGroupOpen", function()
			createGroup()
			call("SetGroupOpen", function(cb)
				group:setGroupOpen(groupId, true, cb)
			end)
		end),
		test("UpdateGroupAcl", function()
			createGroup()
			call("UpdateGroupAcl", function(cb)
				group:updateGroupAcl(groupId, { member = 2, other = 1 }, cb)
			end)
		end),
		test("UpdateGroupSummaryData", function()
			createGroupWithSummaryData()
			call("UpdateGroupSummaryData", function(cb)
				group:updateGroupSummaryData(groupId, 1, { testInc = 123 }, cb)
			end)
		end),
		test("GetRandomGroupsMatching", function()
			createGroupWithSummaryData()
			call("GetRandomGroupsMatching", function(cb)
				group:getRandomGroupsMatching({ groupType = "BLUE" }, 20, cb)
			end)
		end),
		test("DeleteGroupJoinRequest", function()
			createGroupAsUserA()
			as("B")
			call("JoinGroup", function(cb)
				group:joinGroup(groupId, cb)
			end)
			local r = call("GetMyGroups", function(cb)
				group:getMyGroups(cb)
			end)
			assert(r.data.requested and #r.data.requested > 0, "Expected a pending join request")
			call("DeleteGroupJoinRequest", function(cb)
				group:deleteGroupJoinRequest(groupId, cb)
			end)
			r = call("GetMyGroups", function(cb)
				group:getMyGroups(cb)
			end)
			assert(r.data.requested == nil or #r.data.requested == 0, "Join request was not deleted")
		end),
	}
end)

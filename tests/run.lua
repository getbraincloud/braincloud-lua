--- Integration test runner: luajit tests/run.lua [Module[,Module...]] [-t testNameFilter]
--- Needs BC_TEST_IDS=<path to test_ids file>. Exits non-zero on any failure.
--- gtest-style output like the cpp client; BC_TEST_VERBOSE=1 adds failure tracebacks, NO_COLOR=1 plain text.

package.path = "./?.lua;./?/init.lua;" .. package.path

local only, testFilter
local i = 1
while arg[i] do
	if arg[i] == "-t" then
		testFilter = arg[i + 1]
		i = i + 1
	else
		only = {}
		for name in arg[i]:gmatch("[^,]+") do
			only[name:lower():gsub("_", "")] = true
		end
	end
	i = i + 1
end

local modules = {}
local p = io.popen('ls tests/test_*.lua')
for line in p:lines() do
	local name = line:match("tests/(test_[%w_]+)%.lua$")
	if name then
		local short = name:sub(6):gsub("_", "")
		if not only or only[short] then
			modules[#modules + 1] = name
		end
	end
end
p:close()

local TestUtils = require("tests.shared")
local paint, GREEN, RED, YELLOW = TestUtils.paint, TestUtils.GREEN, TestUtils.RED, TestUtils.YELLOW

local function count(n, word)
	return n .. " " .. word .. (n == 1 and "" or "s")
end

local services, failedNames = {}, {}
local passed, failed, skipped = 0, 0, 0
local runStart = TestUtils.nowMs()

print(paint(GREEN, "[==========] ") .. "Running tests from " .. count(#modules, "service") .. ".\n")

for _, name in ipairs(modules) do
	local okLoad, moduleFn = pcall(require, "tests." .. name)
	local built, moduleObj = false, moduleFn
	if okLoad then
		built, moduleObj = pcall(moduleFn)
	end
	local svc = { name = built and moduleObj.name or name, passed = 0, failed = 0, skipped = 0, ms = 0 }
	services[#services + 1] = svc

	if not built then
		print(paint(RED, "[  FAILED  ] ") .. svc.name .. " setup: " .. tostring(moduleObj) .. "\n")
		svc.failed, svc.setupFailed = 1, true
		failedNames[#failedNames + 1] = svc.name .. " (setup)"
	else
		local ok, err = pcall(moduleObj.run, testFilter)
		if not ok then
			print(paint(RED, "[  FAILED  ] ") .. svc.name .. " aborted: " .. tostring(err) .. "\n")
			svc.failed = svc.failed + 1
			failedNames[#failedNames + 1] = svc.name .. " (aborted)"
		end
		for _, r in ipairs(moduleObj.results) do
			svc.ms = svc.ms + r.ms
			if r.status == "ok" then
				svc.passed = svc.passed + 1
			elseif r.status == "skipped" then
				svc.skipped = svc.skipped + 1
			else
				svc.failed = svc.failed + 1
				failedNames[#failedNames + 1] = r.name
			end
		end
	end
	passed, failed, skipped = passed + svc.passed, failed + svc.failed, skipped + svc.skipped
end

local total = passed + failed + skipped
local elapsed = math.floor(TestUtils.nowMs() - runStart + 0.5)

-- per-service results
local width = 7
for _, svc in ipairs(services) do
	width = math.max(width, #svc.name)
end
local row = "%-" .. width .. "s  %6s  %6s  %7s  %9s"
print(paint(GREEN, "[==========] ") .. "Results by service")
print(string.format(row, "Service", "Passed", "Failed", "Skipped", "Time"))
print(string.rep("-", width + 36))
for _, svc in ipairs(services) do
	local line = string.format(row, svc.name, svc.passed, svc.failed, svc.skipped, svc.setupFailed and "setup" or (svc.ms .. " ms"))
	print(svc.failed > 0 and paint(RED, line) or line)
end
print(string.rep("-", width + 36))
print(string.format(row, "Total", passed, failed, skipped, elapsed .. " ms") .. "\n")

print(paint(GREEN, "[==========] ") .. string.format("%s from %s ran. (%d ms total)", count(total, "test"), count(#services, "service"), elapsed))
print(paint(GREEN, "[  PASSED  ] ") .. count(passed, "test") .. ".")
if skipped > 0 then
	print(paint(YELLOW, "[  SKIPPED ] ") .. count(skipped, "test") .. ".")
end
if failed > 0 then
	print(paint(RED, "[  FAILED  ] ") .. count(failed, "test") .. ", listed below:")
	for _, n in ipairs(failedNames) do
		print(paint(RED, "[  FAILED  ] ") .. n)
	end
	print(string.format("\n %d FAILED %s", failed, failed == 1 and "TEST" or "TESTS"))
end
os.exit(failed == 0 and 0 or 1)

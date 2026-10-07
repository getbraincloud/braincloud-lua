-- require("braincloud") → the wrapper module. Client, ReasonCodes and VERSION hang off it.

local ROOT = ...

local Wrapper = require(ROOT .. ".wrapper")
Wrapper.Client = require(ROOT .. ".client")
Wrapper.ReasonCodes = require(ROOT .. ".reasoncodes")
Wrapper.json = require(ROOT .. ".lib.json")
Wrapper.VERSION = require(ROOT .. ".version")

return Wrapper

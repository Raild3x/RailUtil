-- Logan Hunt [Raildex]
--[=[
    @class FusionUtil

    **Current Latest FusionUtil Version:** [`0.3.0`]([0.3.0]%20FusionUtil)


    Inherits all the methods of the latest version of FusionUtil.
]=]

local v0_2_0 : typeof(require(script.FusionUtil_v0_2_0)) = nil
local v0_2_5 : typeof(require(script.FusionUtil_v0_2_5)) = nil
local v0_3_0 : typeof(require(script.FusionUtil_v0_3_0)) = nil

local LatestVersion = "0_3_0"
local Versions = {
    ["0.2.0"] = "0_2_0",
    ["0.2.5"] = "0_2_5",
    ["0.3.0"] = "0_3_0"
}

-- MODULE
local Util = {
    ["0.2.0"] = v0_2_0,
    ["0.2.5"] = v0_2_5,
    ["0.3.0"] = v0_3_0,
}

-- set the metatable here to generate typing
setmetatable(Util, {
    __index = Util[LatestVersion] :: typeof(v0_3_0),
})
export type FusionUtil = typeof(Util)

do -- Module redirection for lazy loading
    local mt = {
        __index = function(t, index: string)
            local v = Versions[index]
            if v then
                local module = require(script["FusionUtil_v" .. v])
                rawset(t, index, module)
                return module
            end
            return Util[LatestVersion][index]
        end
    }
    setmetatable(Util :: any, mt)
end


--[=[
    @within FusionUtil
    @prop 0.2.0 table
    [Util for Fusion 0.2.0]([0.2.0]%20FusionUtil)
    ```lua
    local fUtil = RailUtil.Fusion["0.2.0"]
    ```
]=]

--[=[
    @within FusionUtil
    @prop 0.2.5 table
    [Util for my forked version of Fusion 0.2.0]([0.2.5]%20FusionUtil)
    ```lua
    local fUtil = RailUtil.Fusion["0.2.5"]
    ```
]=]

--[=[
    @within FusionUtil
    @prop 0.3.0 table
    @tag Latest Version
    [Util for Fusion 0.3.0]([0.3.0]%20FusionUtil)
    ```lua
    local fUtil = RailUtil.Fusion["0.3.0"]
    ```
]=]

return Util
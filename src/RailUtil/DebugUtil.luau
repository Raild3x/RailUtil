--!strict
-- Logan Hunt [Raildex]
-- Nov 22, 2022
--[=[
    @class DebugUtil

    DebugUtil is a collection of functions that help with debugging.

    Look for the debug controls under ReplicatedStorage.
]=]

local RunService = game:GetService("RunService")

local Fusion = require(script.Parent.Parent:FindFirstChild("Fusion_v0_3_0"))

type UsedAs<T> = Fusion.UsedAs<T>
type State<T> = Fusion.StateObject<T>

local peek = Fusion.peek
local scope = Fusion:scoped()

local DEBUG_FOLDER_PARENT = game:GetService("ReplicatedStorage")
local DEBUG_FOLDER_NAME = "[RAILUTIL DEBUG CONTROL]"

--------------------------------------------------------------------------------
    --// Initialization //--
--------------------------------------------------------------------------------

local DebugFolder = DEBUG_FOLDER_PARENT:FindFirstChild(DEBUG_FOLDER_NAME)
if not DebugFolder then
    if RunService:IsServer() then
        DebugFolder = Instance.new("Configuration")
        DebugFolder.Name = DEBUG_FOLDER_NAME
        DebugFolder.Parent = DEBUG_FOLDER_PARENT 
        --print("Created Debug Folder")
    end
end

local DebugFlagValues = {}

local function upsertFlagState(flagName: string)
    if not DebugFlagValues[flagName] then
        local v = scope:Value(false)
        DebugFlagValues[flagName] = v

        task.defer(function()
            local debugFolder = DebugFolder or DEBUG_FOLDER_PARENT:WaitForChild(DEBUG_FOLDER_NAME)

            if debugFolder:GetAttribute(flagName) == nil then
                debugFolder:SetAttribute(flagName, peek(v))
            else
                v:set(debugFolder:GetAttribute(flagName))
            end

            scope:Hydrate(debugFolder) {
                [Fusion.Attribute(flagName)] = v,
                [Fusion.AttributeOut(flagName)] = v,
            }
        end)
    end
    return DebugFlagValues[flagName]
end

--------------------------------------------------------------------------------
    --// Class //--
--------------------------------------------------------------------------------
local DebugUtil = {}

-- Function to measure the average runtime of a given function
function DebugUtil.measureAvgRuntime<T...>(func: (T...) -> (...any), numRuns: number?, ...: T...): number
    local NumRuns = numRuns or 1000 -- Default to 100 runs if not specified
    local totalTime = 0

    for i = 1, NumRuns do
        local startTime = os.clock()
        func(...)  -- Call the function
        local endTime = os.clock()
        totalTime += (endTime - startTime)
    end

    return totalTime / NumRuns
end

--[=[
    Gets the current state of a debug flag.

    @param flagName -- The name of the debug flag.
    @param asState -- Whether to return the State object or the current value.
]=]
function DebugUtil.getDebugFlag(flagName: string, asState: boolean?): UsedAs<boolean>
    local state = upsertFlagState(flagName)
    return if asState then state else Fusion.peek(state)
end

--[=[
    Toggles the state of a debug flag.

    @param flagName
    @return boolean -- The new value of the flag.
]=]
function DebugUtil.toggleDebugFlag(flagName: string): boolean
    local state = upsertFlagState(flagName)
    state:set(not peek(state))
    return peek(state)
end

--[=[
    Sets the state of a debug flag.

    @param flagName
    @param value
    @return State<boolean> -- The new state of the flag.
]=]
function DebugUtil.setDebugFlag(flagName: string, value: boolean): State<boolean>
    assert(typeof(value) == "boolean", "Value must be a boolean")
    local state = upsertFlagState(flagName)
    state:set(value)
    return state
end

--[=[
    Observes the state of a debug flag.

    @param flagName
    @param callback
    @param onlyOnChange boolean? -- Whether to call the callback only on changes and not immediately.
    @return function -- The unbind function.
]=]
function DebugUtil.observeDebugFlag(flagName: string, callback: (boolean) -> (), onlyOnChange: boolean?): () -> ()
    local state = upsertFlagState(flagName)
    local observer = scope:Observer(state)
    local fn = function()
        callback(peek(state))
    end
    if onlyOnChange then
        return observer:onChange(fn)
    end
    return observer:onBind(fn)
end

--[=[
    Initializes the DebugUtil module.
]=]
function DebugUtil.setup()
    -- doesnt do anything other than ensure the debug folder is created
    --print("DebugUtil setup")
end

return table.freeze(DebugUtil)

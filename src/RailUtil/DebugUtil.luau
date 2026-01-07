--!strict
-- Logan Hunt [Raildex]
-- Nov 22, 2022
--[=[
    @class DebugUtil

    DebugUtil is a collection of functions that help with debugging.

    :::important
    Make sure you have `TestService` visible in your studio explorer!
    This is where the debug attributes are stored.
    :::
]=]
local Fusion = require(script.Parent.Parent:FindFirstChild("Fusion_v0_3_0"))
local Promise = require(script.Parent.Parent:FindFirstChild("Promise"))

type UsedAs<T> = Fusion.UsedAs<T>
type State<T> = Fusion.StateObject<T>

local peek = Fusion.peek
local scope = Fusion:scoped()

-- local DEBUG_FOLDER_PARENT = game:GetService("ReplicatedStorage")
-- local DEBUG_FOLDER_NAME = "[RAILUTIL DEBUG CONTROL]"

local DEBUG_INSTANCE = game:GetService("TestService")

local STEP_ATTRIBUTE_NAME = "Breakpoint_Step"
local PAUSE_ATTRIBUTE_NAME = "Breakpoint_Pause"

--------------------------------------------------------------------------------
    --// Initialization //--
--------------------------------------------------------------------------------

DEBUG_INSTANCE:SetAttribute(STEP_ATTRIBUTE_NAME, false)
DEBUG_INSTANCE:SetAttribute(PAUSE_ATTRIBUTE_NAME, false)

local function getDebugAttributeInstance(): Instance
    return DEBUG_INSTANCE --DebugFolder or DEBUG_FOLDER_PARENT:WaitForChild(DEBUG_FOLDER_NAME)
end

----------------------------------------------------------------------------------

local DebugFlagValues = {}

local function upsertFlagState(flagName: string)
    if not DebugFlagValues[flagName] then
        local v = scope:Value(false)
        DebugFlagValues[flagName] = v

        task.defer(function()
            local debugFolder = getDebugAttributeInstance()

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

--[=[
    @yields

    Add this to your code to mark it as a breakpoint. If the debug is marked as 'paused',
    then the system will yield at this point until the debug is 'stepped' or 'resumed'.

    You can pass arguments to the breakpoint function, which will be printed to the output
    when the breakpoint is hit.
    
    You can step by calling `DebugUtil.step()` or toggling the `Breakpoint_Step` attribute on `TestService`. 
    You can resume by calling `DebugUtil.resume()` or toggling the `Breakpoint_Pause` attribute off on `TestService`.

    ```lua
    local x = 0
    while true do
        x += 1
        DebugUtil.breakpoint(x)
        task.wait()
    end
    ```
]=]
function DebugUtil.breakpoint(...: any)
    local debugFolder = getDebugAttributeInstance()

    if debugFolder:GetAttribute(PAUSE_ATTRIBUTE_NAME) then
        local LINE =             "\n------------------------------------------------------------"
        local ARGS_HEADER =      "\n [BREAKPOINT ARGS]"
        local TRACEBACK_HEADER = "\n [BREAKPOINT TRACEBACK]"
        ARGS_HEADER = LINE .. ARGS_HEADER .. LINE .. "\n"
        TRACEBACK_HEADER = LINE .. TRACEBACK_HEADER .. LINE

        local args = {...}
        if #args > 0 then
            table.insert(args, 1, ARGS_HEADER)
            table.insert(args, "\n")
        end
        local traceback = debug.traceback(TRACEBACK_HEADER, 2)
        local lastLine = traceback:match("([^\n]*)\n$")
        if lastLine then -- Remove last line of the traceback to make it a bit cleaner
            traceback = traceback:gsub(lastLine, "", 1)
        end
        table.insert(args, traceback)
        warn("[HIT DEBUG BREAKPOINT] Waiting for resume...", table.unpack(args))
        debugFolder:SetAttribute(STEP_ATTRIBUTE_NAME, false)
        Promise.any({
            Promise.fromEvent(debugFolder:GetAttributeChangedSignal(PAUSE_ATTRIBUTE_NAME)),
            Promise.fromEvent(debugFolder:GetAttributeChangedSignal(STEP_ATTRIBUTE_NAME))
        }):await()
        debugFolder:SetAttribute(STEP_ATTRIBUTE_NAME, false)
        print("Resuming Debug...")
    end
end

--[=[
    Steps the debug once to the next step if it is paused.
]=]
function DebugUtil.step()
    local debugFolder = getDebugAttributeInstance()
    debugFolder:SetAttribute(STEP_ATTRIBUTE_NAME, true)
    debugFolder:SetAttribute(STEP_ATTRIBUTE_NAME, false)
end

--[=[
    Pauses the debug if it is not already paused.
]=]
function DebugUtil.pause()
    local debugFolder = getDebugAttributeInstance()
    debugFolder:SetAttribute(PAUSE_ATTRIBUTE_NAME, true)
end

--[=[
    Resumes the debug if it is paused.
]=]
function DebugUtil.resume()
    local debugFolder = getDebugAttributeInstance()
    debugFolder:SetAttribute(PAUSE_ATTRIBUTE_NAME, false)
end


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
    -- Doesnt do anything other than ensure the DebugModule is required at some point
end

return table.freeze(DebugUtil)

--!strict
-- Authors: Logan Hunt [Raildex], Marcus Mendonça [Mophyr];
-- March 23, 2023
--[=[
	@class FusionUtil

	A collection of utility functions for Fusion 0.3.0.

	DO NOT ACCESS THIS IN MULTIPLE VMs. Studio freaks out when
	fusion is loaded in multiple VMs for some unknown reason.

	:::warning
	This module is not yet ready for use.
	:::
]=]

--// Requires //--
local Util = script.Parent.Parent
local MathUtil = require(Util.MathUtil)
local Janitor = require(Util.Parent.Janitor)
local Promise = require(Util.Parent.Promise)
local Fusion = require(Util.Parent["Fusion_0.3.0"])

local peek = Fusion.peek
local scoped = Fusion.scoped
local Value = Fusion.Value
local Observer = Fusion.Observer
local Computed = Fusion.Computed

--// Types //--
type Scope<T> = Fusion.Scope<T>
type State<T> = Fusion.StateObject<T>
type UsedAs<T> = Fusion.UsedAs<T>
type Computed<T> = Fusion.Computed<T>
type Value<T> = Fusion.Value<T>
type Use = Fusion.Use

type Props = { [any]: any }

--// Helper Functions //--
local function isState(v: any): boolean
	return typeof(v) == "table" and v.type == "State"
end

local function isValue(v: any): boolean
	return isState(v) and v.set --v.kind == "Value"
end

--------------------------------------------------------------------------------

local FusionUtil = {}

FusionUtil.isState = isState;
FusionUtil.isValue = isValue;

--------------------------------------------------------------------------------
--// TASK METHODS //--
--------------------------------------------------------------------------------

type Task = Instance | () -> () | { [any]: any } | any
local TASK_SYMBOL = newproxy(false)

--[=[
	@within FusionUtil

	Removes a task from a scope by its taskId.

	@param scope       -- The scope to remove the task from
	@param taskId      -- The taskId of the task to remove
	@param dontCleanup -- Whether or not to run the cleanup function on the task
	@return Task?      -- The task that was removed

	```lua
	local s = scoped({Fusion, FusionUtil})

	local id = "Greeting"
	local task = s:addTask(function() print("Hello, World!") end, nil, id)

	s:removeTask(id) -- Hello, World!
	```
]=]
function FusionUtil.removeTask(scope: Scope<any>, taskId: any, dontCleanup: boolean?): Task?
	for i = 1, #scope do
		local task = (scope :: any)[i]
		if task[TASK_SYMBOL] and task.Id == taskId then
			table.remove(scope, i)
			if not dontCleanup then
				Fusion.doCleanup(task.Task)
			end
			return task.Task
		end
	end
	return nil
end

--[=[
	@within FusionUtil

	Adds a task to a scope. If a taskId is provided, it will remove any existing task with that taskId.

	@param scope    -- The scope to add the task to
	@param task     -- The task to add
	@param methodName -- The method to call when the task is removed
	@param taskId   -- The taskId of the task
	@return Task    -- The task that was added

	```lua
	local s = scoped({Fusion, FusionUtil})

	local id = "Greeting"
	local task = s:addTask(function() print("Hello, World!") end, nil, id)

	Fusion.doCleanup(s) -- Hello, World!
	```
]=]
function FusionUtil.addTask<T>(scope: Scope<any>, task: Task & T, methodName: any?, taskId: any?): T
	if taskId then
		FusionUtil.removeTask(scope, taskId)
	end

	local taskContainer = {
		[TASK_SYMBOL] = true,
		Id = taskId,
		Task = task, 
		Deconstructor = methodName, 
	}
	table.insert(scope, taskContainer :: any)
	return task
end

--[=[
	@within FusionUtil

	Gets a task from a scope by its taskId.

	@param scope  -- The scope to search for the task
	@param taskId -- The taskId of the task to find
	@return Task? -- The task if found, nil otherwise

	```lua
	local s = scoped({Fusion, FusionUtil})

	local id = "Greeting"
	local task = s:addTask(function() print("Hello, World!") end, nil, id)

	local foundTask = s:getTask(id)
	foundTask() -- Hello, World!
	```
]=]
function FusionUtil.getTask<T>(scope: Scope<any>, taskId: any): Task?
	for i = 1, #scope do
		local task = (scope :: any)[i]
		if task[TASK_SYMBOL] and task.Id == taskId then
			return task.Task
		end
	end
	return nil
end



--------------------------------------------------------------------------------
--// METHODS //--
--------------------------------------------------------------------------------

--[=[
    @within FusionUtil

    Ensures a passed data is a StateObject. If it is not, it will be converted to one.

    @param scope        -- The scope in which to create the new state object
    @param data         -- The potential state object
    @param defaultValue -- The default value to use if the data is nil
    @param datatype     -- The type or types of the data expected in the state
    
    @return StateObject<T> -- The existing or newly created state object
]=]
function FusionUtil.ensureIsState<T>(scope: Scope<any>, data: UsedAs<T>?, defaultValue: T?, datatype: (string | { string })?): State<T>
    -- Handle case where data is nil by defaulting to the defaultValue
    if data == nil then
        return Value(scope, defaultValue) :: any
    end

    -- If a datatype is specified, ensure data conforms to the expected type
    if datatype then
        -- Ensure datatype is a table
        if typeof(datatype) == "string" then
            datatype = { datatype }
        end

        -- Validate the data type
        local dType = typeof(peek(data))
        if not table.find(datatype :: {string}, dType) then
            warn(
                "FusionUtil.ensureIsState: Expected data to be of type",
                table.concat(datatype :: {string}, ", "),
                ", got " .. dType .. ". Defaulting to",
                defaultValue
            )
            return Value(scope, defaultValue) :: any
        end
    end

    -- Check if data is already a state object
    if isState(data) then
        return data :: any
    else
        -- Wrap non-state data in a state object within the given scope
        return Value(scope, data) :: any
    end
end

--[=[
	@within FusionUtil

	Syncronizes a StateObject to a Value. The Value will be set to the StateObject's value any time it changes.

	@param stateToWatch -- The state to watch for changes
	@param valueToSet   -- The value to set when the state changes
	@return () -> ()    -- A function that will disconnect the observer

	```lua
	local s = scoped({Fusion, FusionUtil})

	local a = s:Value(123)
	local b = s:Value(0)
	local disconnect = s:syncValues(a, b)

	print( peek(b) ) -- 123
	a:set(456)
	print( peek(b) ) -- 456

	disconnect()
	```
]=]
function FusionUtil.syncValues(scope: Scope<any>, stateToWatch: State<any>, valueToSet: Value<any>): () -> ()
	valueToSet:set(peek(stateToWatch))
	return Observer(scope, stateToWatch):onChange(function()
		valueToSet:set(peek(stateToWatch))
	end)
end

--[=[
	@within FusionUtil

	Takes an AssetId and formats it to a valid string.

	@param scope
	@param id               -- The AssetId to ensure
	@param default          -- The default AssetId to use if the id is nil
	@return CanBeState<string>   -- The State<string> that is synced with the AssetId

	```lua
	local s = scoped({Fusion, FusionUtil})

	local assetId = s:formatAssetId("rbxefsefawsetid://1234567890")
	print( peek(assetId) ) -- "rbxassetid://1234567890"
	```
	```lua
	local assetId = s:formatAssetId(1234567890)
	print( peek(assetId) ) -- "rbxassetid://1234567890"
	```
]=]
function FusionUtil.formatAssetId(scope: Scope<any>, id: UsedAs<string | number>, default: (string | number)?): UsedAs<string>
	local function transform(read)
		local assetId = read(id) or default
		if assetId then
			local t = typeof(assetId)
			assert(t == "string" or t == "number", "Expected a string or number, got " .. t)
			assetId = string.match(tostring(assetId), "%d+")
			return "rbxassetid://" .. assetId
		end
		return ""
	end
	return isState(id) and Computed(scope, transform) or transform(peek)
end

--[=[
	@within FusionUtil

	Generates a computed that calculates the ratio of two numbers as a State<number>.

	@param scope        -- The scope to create the State in
	@param numerator    -- The numerator of the ratio
	@param denominator  -- The denominator of the ratio
	@param mutator      -- An optional State to scale by or a function to mutate the ratio
	@return State<T>    -- The ratio (Potentially mutated)

	```lua
	local s = scoped({Fusion, FusionUtil})

	local numerator = s:Value(100)
	local denominator = s:Value(200)

	local ratio = s:ratio(numerator, denominator)
	print( peek(ratio) ) -- 0.5
	```
]=]
function FusionUtil.ratio<T>(
	scope: Scope<any>,
	numerator: UsedAs<number>,
	denominator: UsedAs<number>,
	mutator: (UsedAs<T> | (ratio: number, use: Use) -> T)?
): Computed<T>
	return Computed(scope, function(use)
		local a: number = use(numerator)
		local b: number = use(denominator)
		local ratio = a / b
		if mutator then
			if typeof(mutator) == "function" then
				return mutator(ratio, use)
			else
				return use(mutator) :: any * ratio
			end
		end
		return ratio :: T | any
	end)
end

--[=[
	@within FusionUtil

	Lerps between two number states. If no use function is given then it returns a state

	@param scope
	@param n1 -- The first number state
	@param n2 -- The second number state
	@param alpha -- The alpha state
	@param _use -- An optional function to use to get the values of the states
	@return UsedAs<number>	-- The resultant lerped number state/value

	```lua
	local a = Value(10)
	local b = Value(20)
	local alpha = Value(0.5)
	local z = FusionUtil.lerpNumber(a, b, alpha)
	print( peek(z) ) -- 15
	```
]=]
function FusionUtil.lerpNumber(scope: Scope<any>, n1: UsedAs<number>, n2: UsedAs<number>, alpha: UsedAs<number>, _use: ((any) -> (any))?): UsedAs<number>
	if _use then
		return MathUtil.lerp(_use(n1), _use(n2), _use(alpha))
	end
	return Computed(scope, function(use)
		return MathUtil.lerp(use(n1), use(n2), use(alpha)) :: number
	end)
end


--[=[
	@within FusionUtil

	A simple equality function that returns true if the two states are equal.
	
	@param scope
	@param stateToCheck1	-- The first potential state to check
	@param stateToCheck2	-- The second potential state to check
	@return State<boolean>	-- A state resolving to the equality of the two given arguments

	```lua
	local s = scoped({Fusion, FusionUtil})

	local a = s:Value(10)
	local b = s:Value(10)
	local c = s:eq(a, b)
	print( peek(c) ) -- true
	a:set(20)
	print( peek(c) ) -- false
	```
]=]
function FusionUtil.eq(scope: Scope<any>, stateToCheck1: UsedAs<any>, stateToCheck2: UsedAs<any>): State<boolean>
	return Computed(scope, function(use)
		return use(stateToCheck1) == use(stateToCheck2)
	end)
end

--[=[
    @within FusionUtil

    Calls the provided callback immediately with the initial state and then again anytime the state updates.

	@param scope
    @param fusionState  -- The state object to observe
    @param callback     -- The callback to call when the fusionState is updated
    @return () -> ()    -- A function that will disconnect the observer
]=]
function FusionUtil.observeState<T>(scope: Scope<any>, fusionState: UsedAs<T>, callback: (stateValue: T) -> ()): () -> ()
	local function onStateChange()
		callback(peek(fusionState))
	end
	onStateChange()
	if isState(fusionState) then
		return Observer(scope, fusionState):onChange(onStateChange)
	end
	warn("FusionUtil.observeState: Expected a State object, got " .. typeof(fusionState))
	return function() end
end




return table.freeze(FusionUtil)

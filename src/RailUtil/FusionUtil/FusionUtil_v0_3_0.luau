--!strict
-- Authors: Logan Hunt [Raildex];
-- March 23, 2023
--[=[
	@class [0.3.0] FusionUtil

	A collection of utility functions for Fusion 0.3.0.

	:::warning Multithreading
	DO NOT ACCESS THIS IN MULTIPLE VMs (Parallel Luau). Studio freaks out when
	fusion is loaded in multiple VMs for some unknown reason.
	:::

	:::tip
	If you see a variable `s` being used in the examples, you can assume it is a Fusion Scope equivalent to the following:
	```lua
	local s = RailUtil.Fusion:scoped()
	```
	:::
]=]

--// Services //--
local RunService = game:GetService("RunService")

--// Requires //--
local Util = script.Parent.Parent
local MathUtil = require(Util.MathUtil)
local Fusion = require(Util.Parent.Fusion_v0_3_0)
local Promise = require(Util.Parent.Promise)
local Types = require(Util.RailUtilTypes)

local peek = Fusion.peek
local Value = Fusion.Value
local Observer = Fusion.Observer
local Computed = Fusion.Computed

--// Types //--
type Promise = Types.Promise
type Use = Fusion.Use
type Scope<T> = Fusion.Scope<T>
type State<T> = Fusion.StateObject<T>
type UsedAs<T> = State<T> | T
type Computed<T> = Fusion.Computed<T>
type Observer = Fusion.Observer
type Value<T> = Fusion.Value<T, T>
type Spring<T> = Fusion.Spring<T>
type Tween<T> = Fusion.Tween<T>
type For<K, V> = Fusion.For<K, V>

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

--[=[
	@within [0.3.0] FusionUtil
	@function isState
	@param arg any
	@return boolean
	Checks if the arg is a Fusion StateObject.
]=]
FusionUtil.isState = isState;

--[=[
	@within [0.3.0] FusionUtil
	@function isValue
	@param arg any
	@return boolean
	Checks if the arg is a Fusion Value.
]=]
FusionUtil.isValue = isValue;

--[=[
	@within [0.3.0] FusionUtil
	@prop scope Scope<FusionUtil>
	
	The global scope for FusionUtil.
]=]
FusionUtil.scope = nil :: Scope<typeof(Fusion) & typeof(FusionUtil)>


--[=[
	@within [0.3.0] FusionUtil
	@prop scopeless table
	
	A table of convenience functions for creating Fusion objects.
	These functions do not require the use of a scope, they by default use the FusionUtil scope.
	These are meant to be used in places where you want to create persistent Fusion objects without needing to pass a scope.

	```lua
	local Value = FusionUtil.scopeless.Value

	local a = Value(10)
	```
]=]
FusionUtil.scopeless = table.freeze {
	Value = function<T>(value: T): Value<T, T>
		return FusionUtil.scope:Value(value)
	end;
	Computed = function<T>(fn: (use: Use) -> T): Computed<T>
		return FusionUtil.scope:Computed(fn)
	end;
	Observer = function<T>(watching: unknown): Observer
		return FusionUtil.scope:Observer(watching)
	end;
	Spring = function<T>(value: UsedAs<T>, speed: UsedAs<number>, damping: UsedAs<T>): Spring<T>
		return FusionUtil.scope:Spring(value)
	end;
	Tween = function<T>(goal: UsedAs<T>, tweenInfo: UsedAs<TweenInfo>): Tween<T>
		return FusionUtil.scope:Tween(goal, tweenInfo)
	end;
	New = function(className: string): (props: Props) -> Instance
		return FusionUtil.scope:New(className)
	end;
	Hydrate = function<T>(instance: T & Instance): (props: Props) -> T
		return FusionUtil.scope:Hydrate(instance)
	end;
	-- For = function<KI, VI, KO, VO>(
	-- 	inputTable: UsedAs<{[KI]: VI}>,
	-- 	processor: (
	-- 		scope: FUS, 
	-- 		value: State<{key: KI, value: VI}>
	-- 	) -> State<{key: KO, value: VO}>
	-- ): Fusion.For<KO, VO>
	-- 	return FusionUtil.scope:For(inputTable)
	-- end;
	ForKeys = function<KI, KO, V>(
		inputTable: UsedAs<{[KI]: V}>,
		processor: (
			use: Use,
			scope: FUS, 
			key: KI
		) -> KO,
		destructor: unknown
	): For<KO, V>
		return FusionUtil.scope:ForKeys(inputTable)
	end;
	ForValues = function<K, VI, VO>(
		inputTable: UsedAs<{[K]: VI}>,
		processor: (
			use: Use,
			scope: FUS, 
			value: VI
		) -> VO,
		destructor: unknown
	): For<K, VO>
		return FusionUtil.scope:ForValues(inputTable)
	end;
	ForPairs = function<KI, VI, KO, VO>(
		inputTable: UsedAs<{[KI]: VI}>,
		processor: (
			use: Use,
			scope: FUS, 
			key: KI,
			value: VI
		) -> {key: KO, value: VO},
		destructor: unknown
	): For<KO, VO>
		return FusionUtil.scope:ForPairs(inputTable)
	end;

}

--------------------------------------------------------------------------------
--// TASK METHODS //--
--------------------------------------------------------------------------------

type Task = Instance | () -> () | { [any]: any } | any
local TASK_SYMBOL = newproxy(false)

--[=[
	@within [0.3.0] FusionUtil

	Removes a task from a scope by its taskId.

	@param scope       -- The scope to remove the task from
	@param taskId      -- The taskId of the task to remove
	@param dontCleanup -- Whether or not to run the cleanup function on the task
	@return Task?      -- The task that was removed

	```lua
	local id = "Greeting"
	local task = s:addTask(function() print("Hello, World!") end, nil, id)

	s:removeTask(id) -- Hello, World!
	```
]=]
function FusionUtil.removeTask(scope: Scope<any>, taskId: any, dontCleanup: boolean?): Task?
	for i = 1, #scope do
		local tsk = (scope :: any)[i]
		if typeof(tsk) == "table" and tsk[TASK_SYMBOL] and tsk.Id == taskId then
			table.remove(scope, i)
			if not dontCleanup then
				tsk.Destroy()
			end
			return tsk.Task
		end
	end
	return nil
end
FusionUtil.RemoveTask = FusionUtil.removeTask

--[=[
	@within [0.3.0] FusionUtil

	Adds a task to a scope. If a taskId is provided, it will remove any existing task with that taskId.

	@param scope    -- The scope to add the task to
	@param tsk     -- The task to add
	@param methodName -- The method to call when the task is removed
	@param taskId   -- The taskId of the task
	@return Task    -- The task that was added

	```lua
	local s = RailUtil.Fusion.scoped()

	local id = "Greeting"
	local task = s:addTask(function() print("Hello, World!") end, nil, id)

	Fusion.doCleanup(s) -- Hello, World!
	```
]=]
function FusionUtil.addTask<T>(scope: Scope<any>, tsk: Task & T, methodName: any?, taskId: any?): T
	if taskId then
		FusionUtil.removeTask(scope, taskId)
	end

	if methodName and not (typeof(tsk) == "table" or typeof(tsk) == "Instance") then
		warn("FusionUtil.addTask: methodName not supported for tasks of type:", typeof(tsk))
	end

	local taskContainer = {
		[TASK_SYMBOL] = true,
		Id = taskId,
		Task = tsk,
		Destroy = function()
			if typeof(methodName) == "string" then
				(tsk :: any)[methodName](tsk)
			elseif typeof(tsk) == "thread" then
				task.cancel(tsk)
			else
				Fusion.doCleanup(tsk :: any)
			end
		end
	}
	table.insert(scope, taskContainer :: any)
	return tsk
end
FusionUtil.AddTask = FusionUtil.addTask

--[=[
	@within [0.3.0] FusionUtil

	Gets a task from a scope by its taskId.

	@param scope  -- The scope to search for the task
	@param taskId -- The taskId of the task to find
	@return Task? -- The task if found, nil otherwise

	```lua
	local s = RailUtil.Fusion.scoped()

	local id = "Greeting"
	local task = s:addTask(function() print("Hello, World!") end, nil, id)

	local foundTask = s:getTask(id)
	foundTask() -- Hello, World!
	```
]=]
function FusionUtil.getTask<T>(scope: Scope<any>, taskId: any): Task?
	for i = 1, #scope do
		local tsk = (scope :: any)[i]
		if typeof(tsk) == "table" and tsk[TASK_SYMBOL] and tsk.Id == taskId then
			return tsk.Task
		end
	end
	return nil
end
FusionUtil.GetTask = FusionUtil.getTask

--------------------------------------------------------------------------------
--// METHODS //--
--------------------------------------------------------------------------------

--[=[
	@within [0.3.0] FusionUtil

	Creates a promise that resolves when the given state changes. If a predicate is given then the promise will only resolve if the predicate returns true.
	If the third argument `canResolveImmediately` is true, the promise will will check the predicate immediately.

	```lua
	local a = s:Value(10)

	s:promiseState(a):andThen(function(value)
		print("Value is now", value)
	end)

	a:set(20) -- "Value is now 20"
	a:set(30) -- Promise has already resolved so no print
	```
]=]
function FusionUtil.promiseState<T>(scope: Scope<any>, state: State<T>, predicate: ((value: T) -> boolean)?, canResolveImmediately: boolean?): Promise
	local prom = Promise.new(function(resolve, _, onCancel)
		local disconnect = nil
		local function Check()
			local value = peek(state)
			if not predicate or predicate(value) then
				disconnect()
				resolve(value)
			end
		end

		disconnect = Observer(scope, state):onChange(Check)
		if canResolveImmediately then
			Check()
		end
		onCancel(disconnect) 
	end)

	if scope then
		table.insert(scope, function()
			prom:cancel()
		end)
	end

	return prom
end

--[=[
	@within [0.3.0] FusionUtil

	Binds a scope to the lifecycle of an instance. When the instance is destroyed, the scope will be cleaned up.
	Also applies vice versa; when the scope is cleaned up, the instance will be destroyed.

	```lua
	local s = RailUtil.Fusion.scoped()

	s:bindTo(s:New "Part" {
		Anchored = true;
	})
	```
]=]
function FusionUtil.bindTo(scope: Scope<any>, obj: Instance): Instance
	local isCleaned = false
	local function TryCleanup()
		if not isCleaned then
			isCleaned = true
			Fusion.doCleanup(scope)
		end
	end

	FusionUtil.addTask(scope, function()
		isCleaned = true
	end)
	table.insert(scope, obj.Destroying:Connect(TryCleanup))

	return obj
end

--[=[
    @within [0.3.0] FusionUtil

    Ensures a passed data is a StateObject. If it is not, it will be converted to one.

    @param scope        -- The scope in which to create the new state object
    @param data         -- The potential state object
    @param defaultValue -- The default value to use if the data is nil
    @param datatype     -- The type or types of the data expected in the state
    
    @return StateObject<T> -- The existing or newly created state object
]=]
function FusionUtil.ensureIsState<T>(scope: Scope<any>, data: UsedAs<T>?, defaultValue: T, datatype: (string | { string })?): State<T>
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
    @within [0.3.0] FusionUtil

    Ensures a passed data is a Value. If it is not, it will be converted to one.

    @param scope        -- The scope in which to create the new state object
    @param data         -- The potential state object
    @param defaultValue -- The default value to use if the data is nil
    @param datatype     -- The type or types of the data expected in the state
    
    @return Value<T> -- The existing or newly created state object
]=]
function FusionUtil.ensureIsValue<T>(scope: Scope<any>, data: UsedAs<T>, defaultValue: T, datatype: (string | { string })?): Value<T>
	-- Handle case where data is nil by defaulting to the defaultValue
	if data == nil then
		return Value(scope, defaultValue)
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
	if isValue(data) then
		return data
	else
		if isState(data) then
			warn("FusionUtil.ensureIsValue: Expected a Value, got a State. ", data, "\n", debug.traceback())
		end
		return Value(scope, peek(data))
	end
end

--[=[
	@within [0.3.0] FusionUtil

	Takes an AssetId and formats it to a valid string.

	@param scope
	@param id               -- The AssetId to ensure
	@param default          -- The default AssetId to use if the id is nil
	@return CanBeState<string>   -- The State<string> that is synced with the AssetId

	```lua
	local s = RailUtil.Fusion.scoped()

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
	@within [0.3.0] FusionUtil

	Generates a computed that calculates the ratio of two numbers as a State<number>.

	@param scope        -- The scope to create the State in
	@param numerator    -- The numerator of the ratio
	@param denominator  -- The denominator of the ratio
	@param mutator      -- An optional State to scale by or a function to mutate the ratio
	@return State<T>    -- The ratio (Potentially mutated)

	```lua
	local s = RailUtil.Fusion.scoped()

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
		local b: number = use(denominator) or 1
		local ratio = a / b
		mutator = use(mutator)
		if mutator then
			if typeof(mutator) == "function" then
				return (mutator :: any)(ratio, use)
			else
				return (mutator :: any) * ratio
			end
		end
		return ratio :: T | any
	end)
end

--[=[
	@within [0.3.0] FusionUtil

	Wraps FusionUtil.ratio with a handler for UDim2s

	@param scope
	@param numerator     -- The numerator of the ratio
	@param denominator   -- The denominator of the ratio
	@param v             -- The UDim2 to scale
	@return State<UDim2> -- The scaled UDim2

	```lua
	local numerator = s:Value(100)
	local denominator = s:Value(200)
	local size = s:Value(UDim2.new(0.2, 100, 0.2, 100))
	local sizeAdjusted = s:ratioUDim2(numerator, denominator, size)
	print( peek(sizeAdjusted) ) -- UDim2.new(0.1, 50, 0.1, 50)
	```
]=]
function FusionUtil.ratioUDim2(
	scope: Scope<any>,
	numerator: UsedAs<number>,
	denominator: UsedAs<number>,
	v: UsedAs<UDim2>
): State<UDim2>
	return FusionUtil.ratio(scope, numerator, denominator, function(ratio, use)
		v = use(v) :: UDim2
		return UDim2.new(v.X.Scale * ratio, v.X.Offset * ratio, v.Y.Scale * ratio, v.Y.Offset * ratio)
	end) :: any -- silence warning
end

--[=[
	@within [0.3.0] FusionUtil
	@unreleased
	@client

	This wraps FusionUtil.ratio with a handler for scaling states/functions with the Screen Height.

	@param mutator -- An optional State to scale by or a function to mutate the ratio
	@param ratioFn any -- An optional function to use for the ratio, defaults to FusionUtil.ratio, but could be given something like FusionUtil.ratioUDim2

	```lua
	local paddingOffset = s:Value(10)

	local paddingAdjusted = s:screenRatio(paddingOffset)
	```
	```lua
	local size = Value(UDim2.new(0, 100, 0, 100))

	local sizeAdjusted = s:screenRatio(size, FusionUtil.ratioUDim2)
	```
	```lua
	local x = s:Value(10)
	local y = s:Value(20)
	local z = s:screenRatio(function(ratio, use)
		return (use(x) + use(y)) * ratio
	end)
	```
]=]
function FusionUtil.screenRatio<T>(scope: Scope<any>, mutator: (UsedAs<T> | (ratio: number, use: Use) -> T)?, ratioFn)
	ratioFn = ratioFn or FusionUtil.ratio
	local CameraUtil = require(Util.CameraUtil)
	return ratioFn(scope, CameraUtil.ViewportSizeY :: any, 1080, mutator)
end

--[=[
	@within [0.3.0] FusionUtil

	Lerps between two number states. If no use function is given then it returns a state

	@param scope
	@param n1 -- The first number state
	@param n2 -- The second number state
	@param alpha -- The alpha state
	@param _use -- An optional function to use to get the values of the states
	@return UsedAs<number>	-- The resultant lerped number state/value

	```lua
	local a = s:Value(10)
	local b = s:Value(20)
	local alpha = s:Value(0.5)
	local z = s:lerpNumber(a, b, alpha)
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
	@within [0.3.0] FusionUtil

	A method to simplify Computeds that return simple UDims. If neither the scale nor offset are states
	then it will just return a raw UDim.

	```lua
	local scale = s:Value(10)
	local udim = s:UDim(scale, 0)
	```
]=]
function FusionUtil.UDim(scope: Scope<any>, scale: UsedAs<number>, offset: UsedAs<number>): UsedAs<UDim>
	if not isState(scale) and not isState(offset) then
		return UDim.new(scale, offset)
	end
	return Computed(scope, function(use)
		return UDim.new(use(scale), use(offset))
	end)
end


--[=[
	@within [0.3.0] FusionUtil

	A simple equality function that returns true if the two states are equal.
	
	@param scope
	@param stateToCheck1	-- The first potential state to check
	@param stateToCheck2	-- The second potential state to check
	@return State<boolean>	-- A state resolving to the equality of the two given arguments

	```lua
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
-- Backwards compat aliases
FusionUtil.Eq = FusionUtil.eq
FusionUtil.Equal = FusionUtil.eq
FusionUtil.Equals = FusionUtil.eq

--[=[
	@within [0.3.0] FusionUtil

	Checks if a given state is truthy. If it is, the state will resolve to 
	the second arg, otherwise it will resolve to the third arg.

	@param scope
	@param state -- The state to check
	@param trueValue -- The value to resolve to if the state is truthy
	@param falseValue -- The value to resolve to if the state is falsey

	```lua
	local s = RailUtil.Fusion.scoped()

	local a = s:Value(false)
	local b = s:Value(20)
	local c = s:If(a, b, 0)
	print( peek(c) ) -- 0
	a:set(true)
	print( peek(c) ) -- 20
	b:set(30)
	print( peek(c) ) -- 30
	```
]=]
function FusionUtil.If<U, V>(scope: Scope<any>, state: UsedAs<any>, trueValue: UsedAs<U>, falseValue: UsedAs<V>): State<U | V>
	return Computed(scope, function(use)
		return if use(state) then use(trueValue) else use(falseValue)
	end)
end

--[=[
	@within [0.3.0] FusionUtil

	Flips the Truthiness of the given state.

	@param scope
	@param state -- The state to flip
	@return State<boolean> -- The flipped state

	```lua
	local a = s:Value(false)
	local b = s:Not(a)
	print( peek(b) ) -- true
	```
]=]
function FusionUtil.Not(scope: Scope<any>, state: UsedAs<any>): State<boolean>
	return Computed(scope, function(use)
		return not use(state)
	end)
end

--[=[
	@within [0.3.0] FusionUtil

	Runs an `or` operation on two states and returns the result.
]=]
function FusionUtil.Or<U, V>(scope: Scope<any>, state1: UsedAs<U>, state2: UsedAs<V>): State<U | V>
	return Computed(scope, function(use)
		return use(state1) or use(state2)
	end)
end

--[=[
	@within [0.3.0] FusionUtil

	Runs an `and` operation on two states and returns the result.
]=]
function FusionUtil.And<U, V>(scope: Scope<any>, state1: UsedAs<U>, state2: UsedAs<V>): State<U | V>
	return Computed(scope, function(use)
		return use(state1) and use(state2)
	end)
end

--[=[
	@within [0.3.0] FusionUtil

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

--[=[
	@within [0.3.0] FusionUtil

	Copies the state of a state object to a new state object. If the state object is updated, the new state object will be updated as well.

	@param scope
	@param state UsedAs<T> -- The state object to copy
	@return State<T>  -- The new state object copied from the original state object 
	@return () -> () -- A function to disconnect the syncronization of the two states

	```lua
	local s = RailUtil.Fusion.scoped()

	local a = s:Value(10)
	local b, disconnect = s:copyState(a)

	print( peek(b) ) -- 10
	a:set(20)
	print( peek(b) ) -- 20
	```
]=]
function FusionUtil.copyState<T>(scope: Scope<any>, state: UsedAs<T>): (State<T>, () -> ())
	local stateCopy = Fusion.Value(scope, peek(state))
	if not isState(state) then
		return stateCopy, function() end
	end
	return stateCopy, Fusion.Observer(scope, state):onChange(function()
		stateCopy:set(peek(state))
	end) :: () -> ()
end

--[=[
	@within [0.3.0] FusionUtil

	Syncronizes a StateObject to a Value. The Value will be set to the StateObject's value any time it changes.
	Functions similarly to FusionUtil.copyState but requires you to give it the Value StateObject to update.

	@param stateToWatch -- The state to watch for changes
	@param valueToSet   -- The value to set when the state changes
	@return () -> ()    -- A function that will disconnect the observer

	```lua
	local s = RailUtil.Fusion.scoped()

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
	@within [0.3.0] FusionUtil

	Creates a State that is updated on RenderStepped.
	The value of the State will contain a number representing the amount of time
	that the clock has spent running.

	@param scope
	@param paused -- A State that can be used to pause the clock

	```lua
	local s = RailUtil.Fusion.scoped()

	local clock = s:clock()

	s:New "Part" {
		Position = s:Computed(function(use)
			local t = use(clock)
			return Vector3.new(0, 5 + math.sin(t) * 5, 0)
		end)
	}
	```
]=]
function FusionUtil.clock(scope: Scope<any>, paused: State<boolean>?): Value<number>
    local clockTime = Fusion.Value(scope, 0)
    
    local conn = RunService.RenderStepped:Connect(function(dt: number)
        if not peek(paused) then
            clockTime:set(peek(clockTime) + dt)
        end
    end)
    table.insert(scope, conn)

    return clockTime
end

-- --[=[
-- 	@within [0.3.0] FusionUtil
-- 	@unreleased

-- 	:::caution Unreleased
-- 	:::

-- 	Converts a state containing a dictionary into a similar dictionary where the values are states.
-- 	This enables easier listening to changes in the dictionary values when using Fusion For objects.
-- ]=]
-- function FusionUtil.mapValuesToStates<K, V, V2=V>(scope: Scope<any>, state: UsedAs<{[K]: V}>, mutator: ((key: K, value: V) -> (V2))?): State<{[K]: State<V2>}>
-- 	warn("FusionUtil.mapValuesToStates is not yet released")
-- 	-- TODO: Finish this method!!!!
-- 	local mappedDict = Fusion.Value(scope, {})
-- 	mutator = mutator or function(_, v) return v end
	
-- 	Fusion.Observer(scope, state):onBind(function()
-- 		local refDict = peek(state)
-- 		local valuesDict = peek(mappedDict)
-- 		local dictKeysChanged = false

-- 		for key, value in refDict do
-- 			if not valuesDict[key] then
-- 				valuesDict[key] = Fusion.Value(s, mutator(key, value))
-- 				dictKeysChanged = true
-- 			else
-- 				lastValue:set(mutator(value, key))
-- 				newDict[key] = lastValue
-- 			end
-- 		end

-- 		-- for key, value in valuesDict do
-- 		-- 	local mutatedKey = mutator(refDict[key], key)
-- 		-- 	if not refDict[key] then
-- 		-- 		valuesDict[key] = nil
-- 		-- 		dictKeysChanged = true
-- 		-- 	end
-- 		-- end

-- 		if dictKeysChanged then
-- 			mappedDict:set(newDict)
-- 		end
-- 	end)

-- 	return mappedDict
-- end

--------------------------------------------------------------------------------
	--// Array Util //--
--------------------------------------------------------------------------------

--[=[
	@within [0.3.0] FusionUtil

	Inserts a value into a container state object.
	Follows the structure of `table.insert` so giving an extra arg for the index will insert the value at that index.

	@param valueState -- The container state object
	@param ... (number, T) | T

	```lua
	local myArr = s:Value({"A", "B", "C"})

	FusionUtil.arrayInsert(myArr, 2, "X")
	print( peek(myArr) ) -- {"A", "X", "B", "C"}

	FusionUtil.arrayInsert(myArr, "Z")
	print( peek(myArr) ) -- {"A", "X", "B", "C", "Z"}
	```
]=]
function FusionUtil.arrayInsert<T>(valueState: Value<{T}>, ...)
	local containerArray = peek(valueState)
	table.insert(containerArray, ...)
	if isValue(valueState) then
		valueState:set(containerArray)
	else
		assert(not isState(valueState), "Expected a Value, got a State")
	end
end

--[=[
	@within [0.3.0] FusionUtil

	Removes a value from a container state object.

	@param valueState -- The container state object
	@param index      -- The index of the value to remove
	@param swapRemove -- Whether to swap the value with the last value before removing it. This is faster than a regular remove but does not maintain the order of the array.

	@return T -- The removed value

	```lua
	local myArr = s:Value({"A", "B", "C"})

	local removedValue = FusionUtil.arrayRemove(myArr, 2)
	print( peek(myArr) ) -- {"A", "C"}
	print( removedValue ) -- "B"
	```
]=]
function FusionUtil.arrayRemove<T>(valueState: Value<{T}>, index: number?, swapRemove: boolean?): T
	if swapRemove then
		assert(index, "Expected an index to swap remove")
		return FusionUtil.arraySwapRemove(valueState, index)
	end
	local containerArray = peek(valueState)
	local v = table.remove(containerArray, index)
	if isValue(valueState) then
		valueState:set(containerArray)
	else
		assert(not isState(valueState), "Expected a Value, got a State")
	end
	return v
end

--[=[
	@within [0.3.0] FusionUtil

	Swaps two values in a container state object.

	@param valueState -- The container state object
	@param index -- the index of the value to swap out

	@return T -- The value that was swapped out

	```lua
	local myArr = s:Value({"A", "B", "C"})

	local removedValue = FusionUtil.arraySwapRemove(myArr, 1)
	print( peek(myArr) ) -- {"C", "B"}
	print( removedValue ) -- "A"
	```
]=]
function FusionUtil.arraySwapRemove<T>(valueState: Value<{T}>, index: number): T
	local containerArray = peek(valueState)
	local v = containerArray[index]
	containerArray[index] = containerArray[#containerArray]
	table.remove(containerArray)
	if isValue(valueState) then
		valueState:set(containerArray)
	else
		assert(not isState(valueState), "Expected a Value, got a State")
	end
	return v
end

--[=[
	@within [0.3.0] FusionUtil

	Removes the first instance of a value from a container state object.

	@param valueState -- The container state object
	@param value      -- The value to remove
	@param swapRemove -- Whether to swap the value with the last value before removing it. This is faster than a regular remove but does not maintain the order of the array.

	@return number? -- The index of the removed value if found

	```lua
	local myArr = s:Value({"A", "B", "C"})

	local indexOfRemovedValue = FusionUtil.arrayRemoveFirstValue(myArr, "A")
	print( peek(myArr) ) -- {"B", "C"}
	print( indexOfRemovedValue ) -- 1
	```
]=]
function FusionUtil.arrayRemoveFirstValue<T>(valueState: Value<{T}>, value: T, swapRemove: boolean?): number?
	local containerArray = peek(valueState)
	local idx = table.find(containerArray, value)
	if idx then
		FusionUtil.arrayRemove(valueState, idx, swapRemove)
	end
	return idx
end

--[=[
	@within [0.3.0] FusionUtil

	Removes the first instance of a value from a container state object via swap replacement.
	Faster than normal removal but does not maintain order.

	@param valueState -- The container state object
	@param value      -- The value to remove

	@return number? -- The index of the removed value if found

	```lua
	local myArr = s:Value({"A", "B", "C"})

	FusionUtil.arraySwapRemoveFirstValue(myArr, "A")
	print( peek(myArr) ) -- {"C", "B"}
	```
]=]
function FusionUtil.arraySwapRemoveFirstValue<T>(valueState: Value<{T}>, value: T): number?
	return FusionUtil.arrayRemoveFirstValue(valueState, value, true)
end

--[=[
	@within [0.3.0] FusionUtil

	Sets a value in a container state object.

	@param valueState -- The container state object
	@param index      -- The index of the value to change
	@param newValue   -- The new value to change index to
	@param updateInsteadOfReplace -- Whether to update the value at the index if it is a ValueState instead of overwriting it

	```lua
	local myArr = s:Value({"A", "B", "C"})

	FusionUtil.arraySet(myArr, 2, "X")
	print( peek(myArr) ) -- {"A", "X", "C"}
	```
]=]
function FusionUtil.arraySet<T>(valueState: Value<{T}>, index: number, newValue: T, updateInsteadOfReplace: boolean?): T
	local containerArray = peek(valueState)
	if updateInsteadOfReplace then
		if isValue(containerArray[index]) then
			containerArray[index]:set(newValue)
			return newValue
		else
			warn("FusionUtil.arraySet: Expected a Value, got a " .. typeof(containerArray[index]))
		end
	end
	containerArray[index] = newValue
	if isValue(valueState) then
		valueState:set(containerArray)
	else
		assert(not isState(valueState), "Expected a Value, got a State")
	end
	return newValue
end

--[=[
	@within [0.3.0] FusionUtil

	Sets the first instance of a value in a container state object.

	@param valueState -- The container state object
	@param valueToFind -- The value to find
	@param valueToReplaceWith -- The value to replace the found value with
	@param updateInsteadOfReplace -- Whether to update the value at the index if it is a ValueState instead of overwriting it

	```lua
	local myArr = s:Value({"A", "B", "C"})

	FusionUtil.arraySetFirstValue(myArr, "B", "X")
	print( peek(myArr) ) -- {"A", "X", "C"}
	```
]=]
function FusionUtil.arraySetFirstValue<T>(valueState: Value<{T}>, valueToFind: T, valueToReplaceWith: T, updateInsteadOfReplace: boolean?): T?
	local containerArray = peek(valueState)
	local idx = table.find(containerArray, valueToFind)
	if idx then
		return FusionUtil.arraySet(valueState, idx, valueToReplaceWith)
	end
	return nil
end

--------------------------------------------------------------------------------
	--// SPECIAL //--
--------------------------------------------------------------------------------

-- This is an alias to allow for janitors to inherently clean up scopes without needing to specify doCleanup
function FusionUtil.destroy(scope: Scope<any>)
	Fusion.doCleanup(scope)
end

FusionUtil.scope = Fusion:scoped(FusionUtil)
export type FUS = typeof(FusionUtil.scope)

local comboTbl
local function getComboTbl()
	if comboTbl then
		return comboTbl
	end
	comboTbl = table.clone(Fusion)
	for k, v in pairs(FusionUtil) do
		comboTbl[k] = v
	end
	return comboTbl
end

FusionUtil.Scoped = function(...)
	return Fusion.scoped(getComboTbl(), ...)
end

setmetatable(FusionUtil, {
	__index = function(t, k)
		if k == "scoped" then
			return FusionUtil.Scoped
		end
		return Fusion[k]
	end;
})


return table.freeze(FusionUtil)

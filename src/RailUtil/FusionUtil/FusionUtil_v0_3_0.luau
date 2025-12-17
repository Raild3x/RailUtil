--!strict
-- Authors: Logan Hunt [Raildex];
-- March 23, 2023
--[=[
	@class FusionUtil

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
local doCleanup = Fusion.doCleanup
local innerScope = Fusion.innerScope

--// Types //--
type Promise = Types.Promise
type Use = Fusion.Use
type Scope<T> = Fusion.Scope<T>
type Value<T> = Fusion.Value<T, T>
type State<T> = Fusion.StateObject<T>
type UsedAs<T> = Fusion.UsedAs<T>
type Computed<T> = Fusion.Computed<T>
type Observer = Fusion.Observer
type Spring<T> = Fusion.Spring<T>
type Tween<T> = Fusion.Tween<T>
type For<K, V> = Fusion.For<K, V>

type DisconnectFn = () -> ()

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
	@within FusionUtil
	@function isState
	@param arg any
	@return boolean
	Checks if the arg is a Fusion StateObject.
]=]
FusionUtil.isState = isState;

--[=[
	@within FusionUtil
	@function isValue
	@param arg any
	@return boolean
	Checks if the arg is a Fusion Value.
]=]
FusionUtil.isValue = isValue;

--[=[
	@within FusionUtil
	@prop scope Scope<FusionUtil>
	
	The global scope for FusionUtil.
]=]
FusionUtil.scope = (nil :: any) :: Scope<typeof(Fusion) & typeof(FusionUtil)>

--[=[
	@within FusionUtil
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
	Value = function<T>(value: T): Value<T>
		return FusionUtil.scope:Value(value)
	end;
	Computed = function<T>(fn: (use: Use) -> T): Computed<T>
		return FusionUtil.scope:Computed(fn)
	end;
	Observer = function<T>(watching: unknown): Observer
		return FusionUtil.scope:Observer(watching)
	end;
	Spring = function<T>(value: UsedAs<T>, speed: UsedAs<number>?, damping: UsedAs<number>?): Spring<T>
		return FusionUtil.scope:Spring(value, speed, damping)
	end;
	Tween = function<T>(goal: UsedAs<T>, tweenInfo: UsedAs<TweenInfo>?): Tween<T>
		return FusionUtil.scope:Tween(goal, tweenInfo)
	end;
	New = function(className: string): (props: Props) -> Instance
		return FusionUtil.scope:New(className)
	end;
	Hydrate = function<T>(instance: T & Instance): (props: Props) -> T
		return FusionUtil.scope:Hydrate(instance) :: any
	end;

	ForKeys = function<KI, KO, V>(
		inputTable: UsedAs<{[KI]: V}>,
		processor: (
			use: Use,
			scope: FUS, 
			key: KI
		) -> KO
	): For<KO, V>
		return FusionUtil.scope:ForKeys(inputTable, processor)
	end;
	ForValues = function<K, VI, VO>(
		inputTable: UsedAs<{[K]: VI}>,
		processor: (
			use: Use,
			scope: FUS, 
			value: VI
		) -> VO
	): For<K, VO>
		return FusionUtil.scope:ForValues(inputTable, processor)
	end;
	ForPairs = function<KI, VI, KO, VO>(
		inputTable: UsedAs<{[KI]: VI}>,
		processor: (
			use: Use,
			scope: FUS, 
			key: KI,
			value: VI
		) -> (KO, VO)
	): For<KO, VO>
		return FusionUtil.scope:ForPairs(inputTable, processor)
	end;
}

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
	@within FusionUtil

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
	@within FusionUtil

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
	@within FusionUtil

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
		local resolved = false
		local function Check()
			if resolved then return end
			local value = peek(state)
			if not predicate or predicate(value) then
				resolved = true
				if disconnect then
					disconnect()
				end
				resolve(value)
			end
		end

		disconnect = Observer(scope, state):onChange(Check)
		onCancel(disconnect)
		
		if canResolveImmediately then
			Check()
		end
	end)

	if scope then
		table.insert(scope, function()
			prom:cancel()
		end)
	end

	return prom
end

--[=[
	@within FusionUtil

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
    @within FusionUtil

    Ensures a passed data is a StateObject. If it is not, it will wrap the given value in a Value StateObject.

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
    @within FusionUtil

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
		return data :: Value<T>
	else
		if isState(data) then
			warn("FusionUtil.ensureIsValue: Expected a Value, got a State. ", data, "\n", debug.traceback())
		end
		return Value(scope, peek(data))
	end
end

--[=[
	@within FusionUtil

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
	@within FusionUtil

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
	@within FusionUtil

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
		local rawV = use(v) :: UDim2
		return UDim2.new(rawV.X.Scale * ratio, rawV.X.Offset * ratio, rawV.Y.Scale * ratio, rawV.Y.Offset * ratio)
	end) :: any -- silence warning
end

--[=[
	@within FusionUtil
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
	local CameraUtil = require(Util.CameraUtil) :: any
	return ratioFn(scope, CameraUtil.ViewportSizeY :: any, 1080, mutator)
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
	@within FusionUtil

	A method to simplify Computeds that return simple UDims. If neither the scale nor offset are states
	then it will just return a raw UDim.

	```lua
	local scale = s:Value(10)
	local udim = s:UDim(scale, 0)
	```
]=]
function FusionUtil.UDim(scope: Scope<any>, scale: UsedAs<number>, offset: UsedAs<number>): UsedAs<UDim>
	if not isState(scale) and not isState(offset) then
		return UDim.new(scale :: number, offset :: number)
	end
	return Computed(scope, function(use)
		return UDim.new(use(scale), use(offset))
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
	@within FusionUtil

	Checks if a given state is truthy. If it is, the state will resolve to 
	the second arg, otherwise it will resolve to the third arg.

	@param scope
	@param state -- The state to check
	@param trueValue -- The value to resolve to if the state is truthy
	@param falseValue -- The value to resolve to if the state is falsey

	```lua
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
	@within FusionUtil

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
	@within FusionUtil

	Runs an `or` operation on two states and returns the result.
]=]
function FusionUtil.Or<U, V>(scope: Scope<any>, state1: UsedAs<U>, state2: UsedAs<V>): State<U | V>
	return Computed(scope, function(use)
		return use(state1) or use(state2)
	end)
end

--[=[
	@within FusionUtil

	Runs an `and` operation on two states and returns the result.
]=]
function FusionUtil.And<U, V>(scope: Scope<any>, state1: UsedAs<U>, state2: UsedAs<V>): State<U | V>
	return Computed(scope, function(use)
		return use(state1) and use(state2)
	end) :: any
end

--[=[
	@within FusionUtil

	Calls the provided callback immediately with the initial state and then again anytime the state updates.
	Just a simpler version of `scope:Observer(state):onBind(fn)`.
	Kept for backwards compatability.

	@param scope
	@param fusionState  -- The state object to observe
	@param callback     -- The callback to call when the fusionState is updated
	@return () -> ()    -- A function that will disconnect the observer
]=]
function FusionUtil.observeState<T>(scope: Scope<any>, fusionState: UsedAs<T>, callback: (stateValue: T) -> ()): DisconnectFn
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
	@within FusionUtil

	Observes an attribute of an instance and returns a state that is updated with the attribute's value.
	
	:::caution Does not memoize the state
]=]
function FusionUtil.outAttribute(scope: Scope<any>, instance: Instance, attributeName: string, valueToBindTo: Value<any>?): (Value<any>, RBXScriptConnection)
	local attributeState: Value<any> = valueToBindTo or Fusion.Value(scope, nil)
	attributeState:set(instance:GetAttribute(attributeName))
	local conn = instance:GetAttributeChangedSignal(attributeName):Connect(function()
		attributeState:set(instance:GetAttribute(attributeName))
	end)
	table.insert(scope, conn)
	return attributeState, conn
end

--[=[
	@within FusionUtil

	Observes a raw property of an instance and returns a state that is updated with the property's value.

	:::caution Does not memoize the state
]=]
function FusionUtil.outProperty(scope: Scope<any>, instance: Instance, propertyName: string, valueToBindTo: Value<any>?): (Value<any>, RBXScriptConnection)
	local propertyState: Value<any> = valueToBindTo or Fusion.Value(scope, nil)
	propertyState:set((instance :: any)[propertyName])
	local conn = instance:GetPropertyChangedSignal(propertyName):Connect(function()
		propertyState:set((instance :: any)[propertyName])
	end)
	table.insert(scope, conn)
	return propertyState, conn
end

--[=[
	@within FusionUtil

	Observes a styled property on an instance and returns a state that is updated whenever the property changes.

	:::caution Does not memoize the state
]=]
function FusionUtil.outStyledProperty(scope: Scope<any>, instance: Instance, propertyName: string, valueToBindTo: Value<any>?): (Value<any>, RBXScriptConnection)
	local propertyState: Value<any> = valueToBindTo or Fusion.Value(scope, nil)
	propertyState:set(instance:GetStyled(propertyName))
	local conn = instance:GetStyledPropertyChangedSignal(propertyName):Connect(function()
		propertyState:set(instance:GetStyled(propertyName))
	end)
	table.insert(scope, conn)
	return propertyState, conn
end

--[=[
	@within FusionUtil

	Binds an attribute of an instance to a state object. Whenever the state changes, the attribute will be updated.
	This is an alternative to hydrating an instance with a state object.

	@param scope
	@param instance -- The instance to bind the attribute to
	@param attributeName -- The name of the attribute to bind
	@param state -- The state object to bind to the attribute
	@return () -> () -- A function that will disconnect the observer

	```lua
	local s = RailUtil.Fusion.scoped()

	local a = s:Value(10)
	local part = Instance.new("Part")

	s:bindAttributeToState(part, "MyAttribute", a)

	print( part:GetAttribute("MyAttribute") ) -- 10
	a:set(20)
	print( part:GetAttribute("MyAttribute") ) -- 20
	```
]=]
function FusionUtil.bindAttributeToState(
	scope: Scope<any>,
	instance: Instance,
	attributeName: string,
	state: UsedAs<any>,
	twoWayBind: boolean?
): DisconnectFn
	local disconnects:{() -> () | RBXScriptConnection} = {}

	local function onStateChange()
		instance:SetAttribute(attributeName, peek(state))
	end

	onStateChange()
	if isState(state) then
		table.insert(disconnects, Fusion.Observer(scope, state):onChange(onStateChange))
	else
		warn("FusionUtil.bindAttributeToState: Expected a State object, got " .. typeof(state))
	end

	if twoWayBind then
		if isValue(state) then
			local function onAttributeChange()
				state:set(instance:GetAttribute(attributeName))
			end
			table.insert(disconnects, instance:GetAttributeChangedSignal(attributeName):Connect(onAttributeChange))
		else
			warn("FusionUtil.bindAttributeToState: Expected a Value object for two-way binding, got " .. typeof(state))
		end
	end

	local didClean = false
	local function cleanup()
		if didClean then return end
		didClean = true
		for _, disconnect in ipairs(disconnects) do
			if typeof(disconnect) == "function" then
				disconnect()
			else
				disconnect:Disconnect()
			end
		end
	end
	table.insert(scope, cleanup)

	return cleanup
end

--[=[
	@within FusionUtil

	Binds a property of an instance to a state object. Whenever the state changes, the property will be updated.
	This is an alternative to hydrating an instance with a state object.

	@param scope
	@param instance -- The instance to bind the property to
	@param propertyName -- The name of the property to bind
	@param state -- The state object to bind to the property
	@param twoWayBind -- Whether or not to bind the property back to the value state (default: false)
	@return () -> () -- A function that will disconnect the observer

	```lua
	local s = RailUtil.Fusion.scoped()

	local a = s:Value(10)
	local part = Instance.new("Part")

	s:bindPropertyToState(part, "Size", a)

	print( part.Size ) -- Vector3.new(10, 10, 10)
	a:set(Vector3.new(20, 20, 20))
	print( part.Size ) -- Vector3.new(20, 20, 20)
	```
]=]
function FusionUtil.bindPropertyToState(
	scope: Scope<any>,
	instance: Instance,
	propertyName: string,
	state: UsedAs<any>,
	twoWayBind: boolean?
): DisconnectFn
	local disconnects:{() -> () | RBXScriptConnection} = {}

	local function onStateChange()
		(instance :: any)[propertyName] = peek(state)
	end

	onStateChange()
	if isState(state) then
		table.insert(disconnects, Fusion.Observer(scope, state):onChange(onStateChange))
	else
		warn("FusionUtil.bindPropertyToState: Expected a State object, got " .. typeof(state))
	end

	if twoWayBind then
		if isValue(state) then
			local function onPropertyChange()
				state:set((instance :: any)[propertyName])
			end
			table.insert(disconnects, instance:GetPropertyChangedSignal(propertyName):Connect(onPropertyChange))
		else
			warn("FusionUtil.bindPropertyToState: Expected a Value object for two-way binding, got " .. typeof(state))
		end
	end

	local didClean = false
	local function cleanup()
		if didClean then return end
		didClean = true
		for _, disconnect in ipairs(disconnects) do
			if typeof(disconnect) == "function" then
				disconnect()
			else
				disconnect:Disconnect()
			end
		end
	end
	table.insert(scope, cleanup)

	return cleanup
end

--[=[
	@within FusionUtil

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
function FusionUtil.copyState<T>(scope: Scope<any>, state: UsedAs<T>): (State<T>, DisconnectFn)
	local stateCopy = Fusion.Value(scope, peek(state))
	if not isState(state) then
		return stateCopy, function() end
	end
	return stateCopy, Fusion.Observer(scope, state):onChange(function()
		stateCopy:set(peek(state))
	end) :: () -> ()
end

--[=[
	@within FusionUtil

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
function FusionUtil.syncValues(scope: Scope<any>, stateToWatch: State<any>, valueToSet: Value<any>): DisconnectFn
	valueToSet:set(peek(stateToWatch))
	return Observer(scope, stateToWatch):onChange(function()
		valueToSet:set(peek(stateToWatch))
	end)
end

--[=[
	@within FusionUtil

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

--[=[
	@within FusionUtil
	@unreleased

	:::caution Unreleased
	This method is not finalized for release and may change in the future. Lock your version if you utilize it.
	:::

	:::warning Performance Consideration
	This function creates a new scope for each key in the input table. For large tables or frequently
	changing tables, this could lead to performance issues. Consider memoization strategies.
	:::

	Converts a state containing a dictionary into a similar dictionary where the values are states.
	This enables easier listening to changes in the dictionary values when using Fusion `For` objects.
	It can be used to prevent re-creating entire UI elements when all you actually need is to update
	some aspect of it.

	**How it works:**
	1. Observes the input table for changes
	2. For each key-value pair, creates a Value state that tracks that specific value
	3. If a mutator function is provided, wraps each Value in a Computed that applies the mutation
	4. Returns a State containing a dictionary where each value is itself a State
	5. When values in the input table change, only the corresponding Value states are updated
	6. When keys are added/removed, the output dictionary is regenerated

	**Parameters:**
	- `scope`: The parent scope for lifecycle management
	- `inputTable`: A State containing a dictionary, or a raw dictionary
	- `_mutator`: Optional function to transform each value. Receives (use, scope, key, value) and returns transformed value

	**Known Issues:**
	- Type system struggles with Value<VI> vs Value<VO> conversion
	- No cleanup verification when scope is destroyed before table changes
	- Mutator can't be changed after creation (state is captured once)
	- Keys being removed and re-added quickly may cause memory churn

	```lua
	-- Basic usage: Wrap values in states
	local map = s:Value({A = 1, B = 2, C = 3})
	local mappedStates = s:mapValuesToStates(map)

	s:ForPairs(mappedStates, function(_, fs, key: string, value: State<number>)
		return key, fs:New "TextLabel" {
			Name = key,
			Text = fs:Computed(function(use)
				return "Current Value:" .. use(value)
			end)
		}
	end)

	-- When you update the source map, only the affected state updates
	FusionUtil.tableSet(map, "A", 10) -- Only the "A" state updates
	```

	```lua
	-- With mutator: Transform values
	local positions = s:Value({
		Player1 = Vector3.new(0, 5, 0),
		Player2 = Vector3.new(10, 5, 0)
	})
	
	local mappedPositions = s:mapValuesToStates(positions, function(use, scope, key, value)
		-- Add offset to each position
		return value + Vector3.new(0, 10, 0)
	end)
	```
]=]
function FusionUtil.mapValuesToStates<K, VI, VO>(
	scope: Scope<any>,
	inputTable: UsedAs<{[K]: VI?}>,
	_mutator: UsedAs<(
		(use: Use, scope: Scope<any>, key: K, value: VI) -> (VO)
	)>?
): State<{[K]: State<VO>?}>
	warn("FusionUtil.mapValuesToStates is not yet released")
	
	-- Output: A Value state containing a dictionary where each value is a State
	-- This allows consumers to observe individual value changes without recreating
	-- the entire structure
	local outputMap: Value<{[K]: State<VO>?}> = Fusion.Value(scope, {})
	
	-- Internal tracking map: For each key, we store:
	-- - Scope: An inner scope for cleanup when the key is removed
	-- - Value: The Value state that tracks this specific value
	-- This enables us to update individual values without recreating the entire map
	local internalMap: {
		[K]: {
			Scope: Scope<any>,
			Value: Value<VO>
		}?
	} = {}
	
	-- Watch the input table for any changes using onBind (fires immediately + on changes)
	Fusion.Observer(scope, inputTable):onBind(function()
		-- Validate input type
		if typeof(peek(inputTable)) ~= "table" then
			warn("FusionUtil.mapValuesToStates: Expected a table, got " .. typeof(peek(inputTable)))
			return
		end

		-- Get the current state of both input and output tables
		local refDict: {[K]: VI?} = peek(inputTable)
		local outputMapRaw = peek(outputMap) :: {[K]: State<VO>?}
		local dictKeysChanged = false -- Track if we need to trigger an update

		-- PHASE 1: ADD OR UPDATE KEYS
		-- Iterate through all keys in the input table
		for key: K, refValue: VI? in refDict do
			if internalMap[key] == nil then
				-- NEW KEY: This key doesn't exist in our internal tracking
				-- Create a new inner scope for this key's lifecycle
				local innerScope = innerScope(scope)
				
				-- Create a Value state to hold this specific value
				-- Cast to Value<any> to work around type system limitations
				local valueState = Fusion.Value(innerScope, refValue) :: Value<any>

				-- Store the scope for cleanup and value state for future updates
				internalMap[key] = {
					Scope = innerScope,
					Value = valueState
				}

				-- Create the output state for this key
				-- If a mutator is provided, wrap in a Computed to apply transformation
				-- Otherwise, just use the raw value state
				outputMapRaw[key] = Fusion.Computed(innerScope, function(use, cScope)
					if use(_mutator) then
						-- Apply the mutator function
						return use(_mutator)(use, cScope, key, use(valueState))
					end
					-- No mutator, return raw value
					return use(valueState)
				end) :: State<VO>

				-- Mark that we added a key
				dictKeysChanged = true
			else
				-- EXISTING KEY: Update the value in the existing Value state
				-- This triggers any observers of this specific value state
				(internalMap[key] :: any).Value:set(refValue)
				-- Note: We don't set dictKeysChanged here because the key structure didn't change,
				-- only the value within an existing state changed
			end
		end

		-- PHASE 2: REMOVE KEYS
		-- Check for keys that exist in output but not in input (keys that were removed)
		for key in outputMapRaw do
			if refDict[key] == nil then
				-- KEY REMOVED: Clean up the inner scope and remove from tracking
				-- This will cleanup all Fusion objects created in that scope
				doCleanup((internalMap[key] :: any).Scope)
				
				-- Remove from internal tracking
				internalMap[key] = nil
				
				-- Remove from output map
				outputMapRaw[key] = nil
				
				-- Mark that we removed a key
				dictKeysChanged = true
			end
		end

		-- PHASE 3: UPDATE OUTPUT IF STRUCTURE CHANGED
		-- Only trigger the output state update if keys were added or removed
		-- Value updates within existing keys don't require this because they
		-- update their own Value states directly
		if dictKeysChanged then
			outputMap:set(outputMapRaw)
		end
	end)

	return outputMap
end

--------------------------------------------------------------------------------
	--// Array Util //--
--------------------------------------------------------------------------------

--[=[
	@within FusionUtil

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
	if typeof(containerArray) ~= "table" then
		error("FusionUtil.arrayInsert: Expected a table, got " .. typeof(containerArray))
	end
	table.insert(containerArray, ...)
	if isValue(valueState) then
		valueState:set(containerArray)
	else
		assert(not isState(valueState), "Expected a Value, got a State")
	end
end

--[=[
	@within FusionUtil

	Removes a value from a container state object.

	@param valueState -- The container state object
	@param index      -- The index of the value to remove
	@param swapRemove -- Whether to swap the value with the last value before removing it. This is faster than a regular remove but does not maintain the order of the array.

	@return T? -- The removed value if the index is valid

	```lua
	local myArr = s:Value({"A", "B", "C"})

	local removedValue = FusionUtil.arrayRemove(myArr, 2)
	print( peek(myArr) ) -- {"A", "C"}
	print( removedValue ) -- "B"
	```
]=]
function FusionUtil.arrayRemove<T>(valueState: Value<{T}>, index: number?, swapRemove: boolean?): T?
	if swapRemove then
		assert(index, "Expected an index to swap remove")
		return FusionUtil.arraySwapRemove(valueState, index)
	end
	local containerArray: {T} = peek(valueState)
	if typeof(containerArray) ~= "table" then
		error("FusionUtil.arrayRemove: Expected a table, got " .. typeof(containerArray))
	end
	local v = table.remove(containerArray, index)
	if isValue(valueState) then
		valueState:set(containerArray)
	else
		assert(not isState(valueState), "Expected a Value, got a State")
	end
	return v
end

--[=[
	@within FusionUtil

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
	if typeof(containerArray) ~= "table" then
		error("FusionUtil.arraySwapRemove: Expected a table, got " .. typeof(containerArray))
	end
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
	@within FusionUtil

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
	@within FusionUtil

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
	@within FusionUtil

	Sets the key in a table (State) to a given value and returns the previous value.
	`tableSet` is a more general version of `arraySet`.

	@param tableState -- The container state object
	@param key -- The index of the value to change
	@param newValue -- The new value to change index to
	@param updateInsteadOfReplace -- Whether to update the value at the index if it is a ValueState instead of overwriting it

	```lua
	local myTable = s:Value({A = 1, B = 2, C = 3})

	FusionUtil.tableSet(myTable, "B", 10)
	print( peek(myTable) ) -- {A = 1, B = 10, C = 3}
	```
]=]
function FusionUtil.tableSet<K, V>(tableState: Value<{[K]: V}> | {[K]: V}, key: K, newValue: V, updateInsteadOfReplace: boolean?): V?
	local containerTable = peek(tableState)
	local currentValue = containerTable[key]
	if updateInsteadOfReplace then
		if isValue(currentValue) then
			currentValue:set(newValue)
			return currentValue
		else
			error("FusionUtil.tableSet: Expected a Fusion.Value, got a " .. typeof(currentValue))
		end
	end

	containerTable[key] = newValue
	if isValue(tableState) then
		(tableState :: any):set(containerTable)
	else
		assert(not isState(tableState), "Expected a Value, got a State")
	end
	return currentValue
end


--[=[
	@within FusionUtil

	Sets the index in an array (State) to a given value and returns the previous value.
	`arraySet` is a more specific version of `tableSet` meant to be used only with array types.

	@param arrayState -- The container state object
	@param index      -- The index of the value to change
	@param newValue   -- The new value to change index to
	@param updateInsteadOfReplace -- Whether to update the value at the index if it is a ValueState instead of overwriting it

	```lua
	local myArr = s:Value({"A", "B", "C"})

	FusionUtil.arraySet(myArr, 2, "X")
	print( peek(myArr) ) -- {"A", "X", "C"}
	```
]=]
function FusionUtil.arraySet<V>(arrayState: Value<{V}> | {V}, index: number, newValue: V, updateInsteadOfReplace: boolean?): V?
	if typeof(index) ~= "number" then
		error("[FusionUtil.arraySet] Expected typeof 'number' for the index, got " .. typeof(index)..". Did you mean to use [FusionUtil.tableSet]?")
	end

	local containerArray = peek(arrayState)
	local currentValue = containerArray[index]
	if updateInsteadOfReplace then
		if isValue(currentValue) then
			currentValue:set(newValue)
			return currentValue
		else
			error("FusionUtil.arraySet: Expected a Fusion.Value, got a " .. typeof(currentValue))
		end
	end

	containerArray[index] = newValue
	if isValue(arrayState) then
		(arrayState :: any):set(containerArray)
	else
		assert(not isState(arrayState), "Expected a Value, got a State")
	end
	return currentValue
end

--[=[
	@within FusionUtil

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
		return FusionUtil.arraySet(valueState, idx, valueToReplaceWith, updateInsteadOfReplace)
	end
	return nil
end


--------------------------------------------------------------------------------
	--// SPECIAL //--
--------------------------------------------------------------------------------

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

setmetatable(FusionUtil, {
	__index = Fusion,
})


FusionUtil.Scoped = function(...)
	return (Fusion.scoped(getComboTbl(), ...) :: any) :: Fusion.Scope<typeof(FusionUtil)>
end
FusionUtil.scoped = FusionUtil.Scoped

return table.freeze(FusionUtil)

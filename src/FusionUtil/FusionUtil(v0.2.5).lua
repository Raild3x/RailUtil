--!strict
-- Authors: Logan Hunt [Raildex], Marcus Mendonça [Mophyr];
-- March 23, 2023
--[=[
	@class FusionUtil

	A collection of utility functions for Fusion.

	DO NOT ACCESS THIS IN MULTIPLE VMs. Studio freaks out when
	fusion is loaded in multiple VMs for some unknown reason.

	This was originally written for an unreleased version of Fusion and should no longer be directly used.
]=]

--// Requires //--
local Util = script.Parent
local Dependencies = Util.Dependencies

local MathUtil = require(Util.MathUtil) ---@module RailUtil.MathUtil

local Janitor = require(Dependencies._Janitor)
local Promise = require(Dependencies._Promise)
local Fusion = require(Dependencies._Fusion)

local peek = Fusion.peek
local Value = Fusion.Value
local Observer = Fusion.Observer
local Computed = Fusion.Computed


--// Types //--
type State<T> = Fusion.StateObject<T>
type CanBeState<T> = Fusion.CanBeState<T>
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

--------------------------------------------------------------------------------
--// METHODS //--
--------------------------------------------------------------------------------

FusionUtil.isState = isState;
FusionUtil.isValue = isValue;

--[=[
	@within FusionUtil

	Creates a promise that resolves when the given state changes.
	If a callback is given then the callback must return true for the promise to resolve.

	@param state     -- The state to observe
	@param callback  -- An optional condition to check before resolving the promise
	@return Promise  -- The promise that will resolve when the state changes

	```lua
	local a = Value(10)
	FusionUtil.promiseStateChange(a, function(value)
		return value > 10
	end):andThen(function(value)
		print("Value is now greater than 10")
	end)

	a:set(5) -- Promise does not resolve
	a:set(15) -- Promise resolves
	```
]=]
function FusionUtil.promiseStateChange(state: State<any>, callback: ((value: any) -> boolean)?)
    assert(callback == nil or typeof(callback) == "function", "FusionUtil.promiseStateChange: Expected callback to be a function or nil")
	local observerDisconnect
	return Promise.new(function(resolve, reject, onCancel)
		observerDisconnect = Fusion.Observer(state):onChange(function()
			if callback == nil or callback(peek(state)) then
                resolve(peek(state))
            end
		end)
	end)
	:finallyCall(observerDisconnect)
end

--[=[
    @within FusionUtil

    Similar to a shallow reconcile, but also moves any children at numeric indices

    @param explicitProps    -- The props to use
    @param defaultProps     -- The default props that to fill in the gaps of explicit
    @return table           -- The reconciled props
]=]
function FusionUtil.defaultProps(explicitProps: Props, defaultProps: Props): Props
	local tbl = table.clone(defaultProps)
	for Idx, Value in explicitProps do
		if typeof(Idx) == "number" then
			table.insert(tbl, Value)
		else
			tbl[Idx] = if Value ~= nil then Value else tbl[Idx]
		end
	end
	return tbl
end

--[=[
    @within FusionUtil

    Ensures a passed data is a StateObject. If it is not, it will be converted to one.

    @param data     	 -- The potential state object
    @param defaultValue  -- The default value to use if the data is nil
    @param datatype 	 -- The type or types of the data expected in the state
    
    @return StateObject<T> -- The existing or newly created state object
]=]
function FusionUtil.ensureIsState<T>(data: CanBeState<T>?, defaultValue: T?, datatype: (string | { string })?): State<T>
	if data ~= nil then
		if datatype then
			local dType = typeof(peek(data))
			if typeof(datatype) == "string" then
				datatype = { datatype }
			end
			if not table.find(datatype, dType) then
				warn(
					"FusionUtil.ensureIsState: Expected data to be of type",
					datatype,
					", got " .. dType .. ". Defaulting to",
					defaultValue
				)
				return Value(data)
			end
		end
		if isState(data) then
			--assert(typeof(data:get()) == datatype, "FusionUtil.ensureIsState: Expected data to be of type "..datatype..", got "..typeof(data.get()))
			return data
        else
            return Value(data)
		end
	end
	return Value(defaultValue)
end

--[=[
    @within FusionUtil

    Ensures the given data is a settable Value. Allows for passing of a default value and a datatype to check against.
    
    @param data         -- The potential value
    @param defaultValue -- The default value to use if the data is nil or an invalid type
    @param datatype     -- The type or types of the data expected in the value
    @return Value<T>    -- The existing or newly created value
]=]
function FusionUtil.ensureIsValue<T>(data: T | Value<T>, defaultValue: T?, datatype: (string | { string })?): Value<T>
	if datatype then
		local dType = typeof(peek(data))
		if typeof(datatype) == "string" then
			datatype = { datatype }
		end
		if not table.find(datatype, dType) then
			warn(
				"FusionUtil.ensureIsValue: Expected data to be of type",
				datatype,
				", got " .. dType .. ". Defaulting to",
				defaultValue
			)
			if isValue(data) then
				data:set(defaultValue)
			else
				data = defaultValue
			end
		end
	end

	if isValue(data) then
		return data
	elseif isState(data) then
		warn("FusionUtil.ensureIsValue: Expected data to be a Value, got a State.") -- TODO: add proper handling
		return data
	end
	return Value(data or defaultValue)
end

--[=[
	@within FusionUtil

	Syncronizes a StateObject to a Value. The Value will be set to the StateObject's value any time it changes.

	@param stateToWatch -- The state to watch for changes
	@param valueToSet   -- The value to set when the state changes
	@return () -> ()    -- A function that will disconnect the observer

	```lua
	local a = Value(123)
	local b = Value(0)
	local disconnect = FusionUtil.syncValues(a, b)

	print( peek(b) ) -- 123
	a:set(456)
	print( peek(b) ) -- 456

	disconnect()
	```
]=]
function FusionUtil.syncValues(stateToWatch: State<any>, valueToSet: Value<any>): () -> ()
	valueToSet:set(peek(stateToWatch))
	return Observer(stateToWatch):onChange(function()
		valueToSet:set(peek(stateToWatch))
	end)
end

--[=[
	@within FusionUtil

	Takes an AssetId and ensures it to a valid State<string>.

	@param id               -- The AssetId to ensure
	@param default          -- The default AssetId to use if the id is nil
	@return CanBeState<string>   -- The State<string> that is synced with the AssetId

	```lua
	local assetId = FusionUtil.ensureAssetId("rbxassetid://1234567890")
	print( peek(assetId) ) -- "rbxassetid://1234567890"
	```
	```lua
	local assetId = FusionUtil.ensureAssetId(1234567890)
	print( peek(assetId) ) -- "rbxassetid://1234567890"
	```
]=]
function FusionUtil.ensureAssetId(id: CanBeState<string | number>, default: (string | number)?): CanBeState<string>
	local function Tranform(read)
		local assetId = read(id) or default
		if assetId and typeof(assetId) ~= "string" then
			assert(typeof(assetId) == "number", "AssetId must be a string or number")
			return "rbxassetid://" .. assetId
		elseif assetId and typeof(assetId) == "string" and tonumber(assetId) then
			assetId = "rbxassetid://" .. assetId
		end
		return assetId or ""
	end
	return if isState(id) then Computed(Tranform) else Tranform(peek)
end

--[=[
	@within FusionUtil

	Generates a computed that calculates the ratio of two numbers as a State<number>.

	@param numerator    -- The numerator of the ratio
	@param denominator  -- The denominator of the ratio
	@param mutator      -- An optional State to scale by or a function to mutate the ratio
	@return State<T>    -- The ratio (Potentially mutated)

	```lua
	local numerator = Value(100)
	local denominator = Value(200)

	local ratio = FusionUtil.ratio(numerator, denominator)
	print( peek(ratio) ) -- 0.5
	```
]=]
function FusionUtil.ratio<T>(
	numerator: CanBeState<number>,
	denominator: CanBeState<number>,
	mutator: (CanBeState<T> | (ratio: number, use: Use) -> T)?
): Computed<T>
	return Computed(function(use)
		local a: number = use(numerator)
		local b: number = use(denominator)
		local ratio = a / b
		if mutator then
			if typeof(mutator) == "function" then
				return mutator(ratio, use)
			else
				return use(mutator) * ratio
			end
		end
		return ratio
	end)
end

--[=[
	@within FusionUtil

	Wraps FusionUtil.ratio with a handler for UDim2s

	@param numerator     -- The numerator of the ratio
	@param denominator   -- The denominator of the ratio
	@param v             -- The UDim2 to scale
	@return State<UDim2> -- The scaled UDim2

	```lua
	local numerator = Value(100)
	local denominator = Value(200)
	local size = Value(UDim2.new(0.2, 100, 0.2, 100))
	local sizeAdjusted = FusionUtil.ratioUDim2(numerator, denominator, size)
	print( peek(sizeAdjusted) ) -- UDim2.new(0.1, 50, 0.1, 50)
	```
]=]
function FusionUtil.ratioUDim2(
	numerator: CanBeState<number>,
	denominator: CanBeState<number>,
	v: CanBeState<UDim2>
): State<UDim2>
	return FusionUtil.ratio(numerator, denominator, function(ratio, use)
		v = use(v) :: UDim2
		return UDim2.new(v.X.Scale * ratio, v.X.Offset * ratio, v.Y.Scale * ratio, v.Y.Offset * ratio)
	end) :: any -- silence warning
end

--[=[
	@within FusionUtil
	@client

	This wraps FusionUtil.ratio with a handler for scaling states/functions with the Screen Height.

	@param mutator -- An optional State to scale by or a function to mutate the ratio
	@param ratioFn any -- An optional function to use for the ratio, defaults to FusionUtil.ratio, but could be given something like FusionUtil.ratioUDim2

	```lua
	local paddingOffset = Value(10)

	local paddingAdjusted = FusionUtil.screenRatio(paddingOffset)
	```
	```lua
	local size = Value(UDim2.new(0, 100, 0, 100))

	local sizeAdjusted = FusionUtil.screenRatio(size, FusionUtil.ratioUDim2)
	```
	```lua
	local x = Value(10)
	local y = Value(20)
	local z = FusionUtil.screenRatio(function(ratio, use)
		return (use(x) + use(y)) * ratio
	end)
	```
]=]
function FusionUtil.screenRatio<T>(mutator: (CanBeState<T> | (ratio: number, use: Use) -> T)?, ratioFn)
	ratioFn = ratioFn or FusionUtil.ratio
	local CameraUtil = require(Util.CameraUtil)
	return ratioFn(CameraUtil.ViewportSizeY :: any, 1080, mutator)
end

--[=[
	@within FusionUtil

	Lerps between two number states. If no use function is given then it returns a state

	@param n1 CanBeState<number>	-- The first number state
	@param n2 CanBeState<number>	-- The second number state
	@param alpha CanBeState<number>	-- The alpha state
	@param _use ((any) -> (any))?	-- An optional function to use to get the values of the states
	@return State<number> | number	-- The resultant lerped number state

	```lua
	local a = Value(10)
	local b = Value(20)
	local alpha = Value(0.5)
	local z = FusionUtil.lerpNumber(a, b, alpha)
	print( peek(z) ) -- 15
	```
]=]
function FusionUtil.lerpNumber(n1: CanBeState<number>, n2: CanBeState<number>, alpha: CanBeState<number>, _use: ((any) -> (any))?): State<number> | number
	if _use then
		return MathUtil.lerp(_use(n1), _use(n2), _use(alpha))
	end
	return Computed(function(use)
		return MathUtil.lerp(use(n1), use(n2), use(alpha))
	end)
end

--[=[
	@within FusionUtil

	A simple swap function that returns the first value if the condition is true, otherwise returns the second value.
	Helps with simplifying lots of bulky computeds.

	@param stateToCheck State<boolean>	-- The condition to check
	@param trueOutcome CanBeState<X> 	-- The value to return if the condition is true
	@param falseOutcome CanBeState<Y> 	-- The value to return if the condition is false
	@return State<X|Y>			-- The value that was returned

	```lua
	local a = Value(10)
	local b = Value(20)

	local y = Value(false)
	local z = FusionUtil.ifThenElse(y, a, b)

	print( peek(z) ) -- 20
	y:set(true)
	print( peek(z) ) -- 10
	```
]=]
function FusionUtil.ifThenElse(stateToCheck: State<boolean>, trueOutcome: CanBeState<any>?, falseOutcome: CanBeState<any>?): State<any>
	return Computed(function(use)
		return if use(stateToCheck) then use(trueOutcome) else use(falseOutcome)
	end)
end

--[=[
	@within FusionUtil

	A simple equality function that returns true if the two states are equal.
		
	@param stateToCheck1	-- The first potential state to check
	@param stateToCheck2	-- The second potential state to check
	@return State<boolean>	-- A state resolving to the equality of the two given arguments

	```lua
	local a = Value(10)
	local b = Value(10)
	local c = FusionUtil.eq(a, b)
	print( peek(c) ) -- true
	a:set(20)
	print( peek(c) ) -- false
	```
]=]
function FusionUtil.eq(stateToCheck1: CanBeState<any>, stateToCheck2: CanBeState<any>): State<boolean>
	return Computed(function(use)
		return use(stateToCheck1) == use(stateToCheck2)
	end)
end

--[=[
    @within FusionUtil

    Checks if a given value exists, if it does then this returns the returned value of the passed function.

    @param value                -- Value to check existance.
    @param fn (T...) -> U...   -- Callback to run if 'value' exists.
    @param ... any                 -- Args to be passed to the callback.
    @return U...?               -- The returned value of the callback if 'value' exists.
]=]
function FusionUtil.ifExists(value: any?, fn: (...any) -> ...any, ...): ...any?
	return (if value then fn(...) else nil)
end

--[=[
    @within FusionUtil

    Checks if a given value is a state, if it does then this returns the returned value of the passed function.

    @param state                -- State to check existence.
    @param fn (T...) -> U...   -- Callback to run if 'value' is a state.
    @param ... any                 -- Args to be passed to the callback.
    @return U...?               -- The returned value of the callback if 'value' exists.
]=]
function FusionUtil.ifIsState(state: any?, fn: (...any) -> ...any, ...): (...any?)
    return (if isState(state) then fn(...) else nil)
end

--[=[
    @within FusionUtil

    Calls the provided callback immediately with the initial state and again anytime the state updates.

    @param fusionState  -- The state object to observe
    @param callback     -- The callback to call when the fusionState is updated
    @return () -> ()    -- A function that will disconnect the observer
]=]
function FusionUtil.observeState(fusionState: State<any>, callback: (stateValue: any) -> ()): () -> ()
	local function onStateChange()
		callback(peek(fusionState))
	end
	onStateChange()
	return Observer(fusionState):onChange(onStateChange)
end


--[=[
	@within FusionUtil
	@deprecated v1.0.0 -- Use Fusion's Attribute System instead

	Syncronizes an instances attribute to a Value. The value will be set to the attribute's value any time it changes.
	This is superceded by Fusion's Attribute System and should no longer be used.

	@param parent       -- The parent instance to watch for attribute changes
	@param attribute    -- The name of the attribute to watch
	@param defaultValue -- The default value to use if the attribute is nil
	@return State       -- The state object that is synced with the value
	@return () -> ()    -- A function that will disconnect the observer
]=]
function FusionUtil.watchAttribute(parent: Instance, attribute: string, defaultValue: any?): (State<any>, () -> ())
	assert(typeof(parent) == "Instance", "parent must be an instance")
	assert(typeof(attribute) == "string", "attribute must be a string")

	local jani = Janitor.new()
	local state = Value()

	local function updateState()
		local newValue = parent:GetAttribute(attribute)
		if newValue == nil and defaultValue ~= nil then
			newValue = defaultValue
		end
		state:set(newValue)
	end

	updateState()
	jani:Add(parent:GetAttributeChangedSignal(attribute):Connect(updateState))
	jani:LinkToInstance(parent)

	local function cleanup()
		jani:Destroy()
	end

	return state, cleanup
end

return table.freeze(FusionUtil)

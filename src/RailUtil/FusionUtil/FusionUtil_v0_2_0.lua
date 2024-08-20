--!strict
-- Authors: Logan Hunt [Raildex], Marcus Mendonça [Mophyr];
-- March 23, 2023
--[=[
	@class [0.2.0] FusionUtil

	A collection of utility functions for Fusion.

	DO NOT ACCESS THIS IN MULTIPLE VMs. Studio freaks out when
	fusion is loaded in multiple VMs for some unknown reason.

	:::warning
	This module is not yet ready for use.
	:::
]=]

--// Requires //--
local RailUtil = script.Parent.Parent
local Promise = require(RailUtil.Parent.Promise)
local Fusion = require(RailUtil.Parent.Fusion)

local Value = Fusion.Value
local Observer = Fusion.Observer
local Computed = Fusion.Computed

--// Types //--
type State<T> = Fusion.StateObject<T>
type CanBeState<T> = Fusion.CanBeState<T>
type Computed<T> = Fusion.Computed<T>
type Value<T> = Fusion.Value<T>

type Props = { [any]: any }

--// Helper Functions //--
local function isState(v: any): boolean
	return typeof(v) == "table" and v.type == "State"
end

local function isValue(v: any): boolean
	return isState(v) and v.set --v.kind == "Value"
end

local function use<T>(initialValue: CanBeState<T> | any): T
	if isState(initialValue) then
		return initialValue:get() :: T
	else
		return initialValue :: T
	end
end

--------------------------------------------------------------------------------

local FusionUtil = {}

FusionUtil.use = use
FusionUtil.isState = isState;
FusionUtil.isValue = isValue;

--------------------------------------------------------------------------------
--// METHODS //--
--------------------------------------------------------------------------------

--[=[
	@within [0.2.0] FusionUtil

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
			if callback == nil or callback(use(state)) then
                resolve(use(state))
            end
		end)
	end)
	:finallyCall(observerDisconnect)
end

--[=[
	@within [0.2.0] FusionUtil

	Takes an AssetId and ensures it to a valid State<string>.

	@param id               -- The AssetId to format
	@param default          -- The default AssetId to use if the id is nil
	@return CanBeState<string>   -- The State<string> that is synced with the AssetId

	```lua
	local assetId = FusionUtil.formatAssetId("rbxassetid://1234567890")
	print( peek(assetId) ) -- "rbxassetid://1234567890"
	```
	```lua
	local assetId = FusionUtil.formatAssetId(1234567890)
	print( peek(assetId) ) -- "rbxassetid://1234567890"
	```
]=]
function FusionUtil.formatAssetId(id: CanBeState<string | number>, default: (string | number)?): CanBeState<string>
	local function Tranform(read)
		read = read or use
		local assetId = read(id) or default
		if assetId and typeof(assetId) ~= "string" then
			assert(typeof(assetId) == "number", "AssetId must be a string or number")
			return "rbxassetid://" .. assetId
		elseif assetId and typeof(assetId) == "string" and tonumber(assetId) then
			assetId = "rbxassetid://" .. assetId
		end
		return assetId or ""
	end
	return if isState(id) then Computed(Tranform :: any) else Tranform(use)
end


--[=[
	@within [0.2.0] FusionUtil

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
	mutator: (CanBeState<T> | (ratio: number) -> T)?
): Computed<T>
	return Computed(function()
		local a: number = use(numerator)
		local b: number = use(denominator)
		local ratio = a / b
		mutator = use(mutator)
		if mutator then
			if typeof(mutator) == "function" then
				return (mutator :: any)(ratio)
			else
				return (mutator :: any) * ratio
			end
		end
		return ratio
	end)
end

--[=[
	@within [0.2.0] FusionUtil

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
	return Computed(function()
		return use(stateToCheck1) == use(stateToCheck2)
	end)
end


return table.freeze(FusionUtil)

--!strict
-- Authors: Logan Hunt [Raildex], Marcus Mendonça [Mophyr];
-- March 23, 2023
--[=[
	@class FusionUtil

	A collection of utility functions for Fusion.

	DO NOT ACCESS THIS IN MULTIPLE VMs. Studio freaks out when
	fusion is loaded in multiple VMs for some unknown reason.

	:::warning
	This module is not yet ready for use.
	:::
]=]

--// Requires //--
local Util = script.Parent
local Janitor = require(Util.Parent.Janitor)
local Promise = require(Util.Parent.Promise)
local Fusion = require(Util.Parent.Fusion)

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

return table.freeze(FusionUtil)

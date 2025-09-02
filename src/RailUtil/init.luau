--!strict
-- Logan Hunt (Raildex)
-- November 22, 2022
--[=[
	@class RailUtil

	RailUtil is a collection of utility libraries created by Logan Hunt (Raildex).

	This module serves as an entrypoint to each of the sub libraries.

	- [Math](/api/MathUtil)
	- [Vector](/api/VectorUtil)
	- [Table](/api/TableUtil)
	- [String](/api/StringUtil)
	- [Player](/api/PlayerUtil)
	- [Instance](/api/InstanceUtil)
	- [Input](/api/InputUtil)
	- [Signal](/api/SignalUtil)
	- [Camera](/api/CameraUtil)
	- [Fusion](/api/FusionUtil)
	- [Draw](/api/DrawUtil)
	- [Debug](/api/DebugUtil)

	Reference the desired utility modules via the RailUtil package to get started:

	```lua
	local RailUtil = require(Packages.RailUtil)
	local MathUtil = RailUtil.Math
	local TableUtil = RailUtil.Table
	local StringUtil = RailUtil.String
	local VectorUtil = RailUtil.Vector
	local SignalUtil = RailUtil.Signal
	local PlayerUtil = RailUtil.Player
	local InstanceUtil = RailUtil.Instance
	local InputUtil = RailUtil.Input
	local CameraUtil = RailUtil.Camera
	local FusionUtil = RailUtil.Fusion
	local DrawUtil = RailUtil.Draw
	local DebugUtil = RailUtil.Debug
	```
]=]

local MathUtil : typeof(require(script.MathUtil)) = nil
local TableUtil : typeof(require(script.TblUtil)) = nil
local VectorUtil : typeof(require(script.VectorUtil)) = nil
local PlayerUtil : typeof(require(script.PlayerUtil)) = nil
local InstanceUtil : typeof(require(script.InstanceUtil)) = nil
local StringUtil : typeof(require(script.StringUtil)) = nil
local CameraUtil : typeof(require(script.CameraUtil)) = nil
local InputUtil : typeof(require(script.InputUtil)) = nil
local FusionUtil : typeof(require(script.FusionUtil)) = nil
local DrawUtil : typeof(require(script.DrawUtil)) = nil
local DebugUtil : typeof(require(script.DebugUtil)) = nil
local SignalUtil : typeof(require(script.SignalUtil)) = nil

local scriptRefs = {
	Math = script:FindFirstChild("MathUtil"),
	Vector = script:FindFirstChild("VectorUtil"),
	Table = script:FindFirstChild("TblUtil"),
	Debug = script:FindFirstChild("DebugUtil"),
	Signal = script:FindFirstChild("SignalUtil"),
	Player = script:FindFirstChild("PlayerUtil"),
	Instance = script:FindFirstChild("InstanceUtil"),
	Fusion = script:FindFirstChild("FusionUtil"),
	String = script:FindFirstChild("StringUtil"),
	Camera = script:FindFirstChild("CameraUtil"),
	Draw = script:FindFirstChild("DrawUtil"),
	Input = script:FindFirstChild("InputUtil"),
}

-- I have a metatable redirecting all these because roblox
-- freaks out when trying to access some of this in a separate VM
local UtilMT = {
	__metatable = "RailUtil's Metatable is locked.",
	__index = function(self, index) -- Lazy load modules
		local module = scriptRefs[index] :: ModuleScript
		assert(module, "Invalid index: " .. tostring(index))
		rawset(self, index, require(module) :: any)
		return self[index]
	end,
	__newindex = function(self, index, value)
		error(
			"RailUtil is externally immutable! Attempted to change index: "
				.. tostring(index)
				.. " to value: "
				.. tostring(value)
		)
	end,
}

local Util = {
	Math = MathUtil,
	Vector = VectorUtil,
	Table = TableUtil,
	Debug = DebugUtil,
	Draw = DrawUtil,
	Signal = SignalUtil,
	Player = PlayerUtil,
	Instance = InstanceUtil,
	Fusion = FusionUtil,
	String = StringUtil,
	Camera = CameraUtil,
	Input = InputUtil,
}

setmetatable(Util, UtilMT)

return Util

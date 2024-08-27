--!strict
-- Logan Hunt (Raildex)
-- November 22, 2022
--[=[
	@class RailUtil

	RailUtil is a collection of utility libraries created by Logan Hunt (Raildex).

	This module serves as an entrypoint to each of the sub libraries.
]=]

--[=[
	@within RailUtil
	@prop Math MathUtil
	The MathUtil module.
]=]

--[=[
	@within RailUtil
	@prop Vector VectorUtil
	The VectorUtil module.
]=]

--[=[
	@within RailUtil
	@prop Table TableUtil
	The TableUtil module.
]=]

--[=[
	@within RailUtil
	@prop Signal SignalUtil
	The SignalUtil module.
]=]

--[=[
	@within RailUtil
	@prop Player PlayerUtil
	The PlayerUtil module.
]=]

--[=[
	@within RailUtil
	@prop Instance InstanceUtil
	The InstanceUtil module.
]=]

--[=[
	@within RailUtil
	@prop Fusion FusionUtil
	The FusionUtil module.
]=]

--[=[
	@within RailUtil
	@prop String StringUtil
	The StringUtil module.
]=]

--[=[
	@within RailUtil
	@prop Camera CameraUtil
	The CameraUtil module.
]=]

local DrawUtil : typeof(require(script.DrawUtil)) = nil
local MathUtil : typeof(require(script.MathUtil)) = nil
local VectorUtil : typeof(require(script.VectorUtil)) = nil
local TableUtil : typeof(require(script.TblUtil)) = nil
local DebugUtil : typeof(require(script.DebugUtil)) = nil
local SignalUtil : typeof(require(script.SignalUtil)) = nil
local PlayerUtil : typeof(require(script.PlayerUtil)) = nil
local InstanceUtil : typeof(require(script.InstanceUtil)) = nil
local FusionUtil : typeof(require(script.FusionUtil)) = nil
local StringUtil : typeof(require(script.StringUtil)) = nil
local CameraUtil : typeof(require(script.CameraUtil)) = nil

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
}

setmetatable(Util, UtilMT)

return Util

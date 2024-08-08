--!strict
-- Logan Hunt [Raildex]
-- November 21, 2022
--[=[
	@class CameraUtil
	@client
]=]

--// Services //--
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
	warn("[RailUtil.Camera] CameraUtil is a client-only module!")
end

--// Requires //--
local RailUtil = script.Parent
local Fusion = require(RailUtil.Parent.Fusion)
local FusionUtil = require(RailUtil.FusionUtil)

--// Types //--
type State<T> = Fusion.StateObject<T>
type CanBeState<T> = Fusion.CanBeState<T>
type Computed<T> = Fusion.Computed<T>
type Value<T> = Fusion.Value<T>

--// Constants //--
local CurrentCamera = workspace.CurrentCamera

local Value = Fusion.Value
local Computed = Fusion.Computed

local IS_EDIT = false
pcall(function()
	IS_EDIT = game:GetService("RunService"):IsEdit()
end)

--------------------------------------------------------------------------------
--// Class //--
--------------------------------------------------------------------------------

local CameraUtil = {}

--[=[
	@prop Instance Camera
	@within CameraUtil
	The current camera instance.
]=]
CameraUtil.Instance = CurrentCamera :: Camera

--[=[
	@prop CameraCFrame State<CFrame>
	@within CameraUtil
	A Fusion State containing the current camera's CFrame.
]=]
CameraUtil.CameraCFrame = Value(CurrentCamera.CFrame) :: State<CFrame>

--[=[
	@prop ViewportSize State<Vector2>
	@within CameraUtil
	A Fusion State containing the current camera's ViewportSize.
]=]
CameraUtil.ViewportSize = Value(CurrentCamera.ViewportSize) :: State<Vector2>

--[=[
	@prop ViewportSizeY State<number>
	@within CameraUtil
	A Fusion Computed containing the current camera's ViewportSize.Y.
]=]
CameraUtil.ViewportSizeY = Computed(function()
	return FusionUtil.use(CameraUtil.ViewportSize).Y
end) :: Computed<number>


-- INITIALIZATION HANDLING OF STATES --
if RunService:IsClient() or (IS_EDIT) then
	-- Init State Updates --
	CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		CameraUtil.ViewportSize:set(CurrentCamera.ViewportSize)
	end)

	workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Connect(function()
		CameraUtil.CameraCFrame:set(workspace.CurrentCamera.CFrame)
	end)
end

--------------------------------------------------------------------------------
--// Class Functions //--
--------------------------------------------------------------------------------

--[=[
	A function that takes a world position and returns whether or not that
	point is on screen within the camera's viewport.

	@param worldPoint -- The world position to check.
	@param viewportMargin -- The acceptable margin of viewport space to be considered on screen. Defaults to 50.
	
	@return boolean -- Whether or not the position is on screen.
	@return number -- The distance the point is from the camera
]=]
function CameraUtil.isOnScreen(worldPoint: Vector3, viewportMargin: number?): (boolean, number)
	debug.profilebegin(":IsOnScreen()")
	viewportMargin = viewportMargin or 50

	local viewport: Vector2 = CurrentCamera.ViewportSize
	local viewportX: number = viewport.X + (viewportMargin :: number)
	local viewportY: number = viewport.Y + (viewportMargin :: number)
	local screenPos: Vector3 = CurrentCamera:WorldToViewportPoint(worldPoint)
	local onScreen: boolean = (
		screenPos.X >= -(viewportMargin :: number)
		and screenPos.X <= viewportX
		and screenPos.Y >= -(viewportMargin :: number)
		and screenPos.Y <= viewportY
	)
	debug.profileend()
	return onScreen, screenPos.Z
end

return table.freeze(CameraUtil)

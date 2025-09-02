-- February 12, 2025

local RailUtil = require(script.Parent.Parent)

local DISTANCE_FROM_CAMERA = 20
local POINT_BOUNDS = 15
local GENERATED_POINTS = math.random(12, 20)

return function(parent: ScreenGui)
	local camera = workspace.CurrentCamera
	local camPos = (camera.CFrame + camera.CFrame.LookVector * DISTANCE_FROM_CAMERA).Position

	local StoryFolder = Instance.new("Folder")
	StoryFolder.Name = "HullStory"
	StoryFolder.Archivable = false
	StoryFolder:AddTag("Destroy")

	local Plate = Instance.new("Part")
	Plate.Name = "PLATE"
	Plate.Size = Vector3.new(60, 0.1, 60)
	Plate.BrickColor = BrickColor.DarkGray()
	Plate.Transparency = 0.5
	Plate.Anchored = true
	Plate.CanCollide = false
	Plate.Position = camPos - Vector3.yAxis
	Plate.Locked = true
	Plate.Parent = StoryFolder
	
	for i = 1, GENERATED_POINTS do
		local point = Instance.new("Part")
		point.Name = "PolygonPoint"
		point.Size = Vector3.one * 2
		point.CanCollide = false
		point.Anchored = true
		point.Transparency = 0
		point.Position = camPos + Vector3.new(math.random(-POINT_BOUNDS, POINT_BOUNDS), 0, math.random(-POINT_BOUNDS, POINT_BOUNDS))
		point.Parent = StoryFolder
	end
	StoryFolder.Parent = workspace

	local HullParts = Instance.new("Model")
	HullParts.Name = "HullEdges"
	HullParts.Parent = StoryFolder

	local function generateHull()
		HullParts:ClearAllChildren()
		local points = {}

		local avgHeight = 0
		for _, point in ipairs(StoryFolder:GetChildren()) do
			if point.Name ~= "PolygonPoint" then
				continue
			end
			avgHeight += point.Position.Y
			table.insert(points, Vector2.new(point.Position.X, point.Position.Z))
		end
		avgHeight /= #points

		local hull = RailUtil.Vector.calculateConvexHullGrahamScan(points)
		for i = 1, #hull do
			local nextIndex = i + 1
			if nextIndex > #hull then
				nextIndex = 1
			end
			local v1 = Vector3.new(hull[nextIndex].X, avgHeight, hull[nextIndex].Y)
			local v2 = Vector3.new(hull[i].X, avgHeight, hull[i].Y)
			local line = RailUtil.Draw.line(tostring(i), v1, v2)
			line.Locked = true
			line.CanCollide = false
			line.CanQuery = false
			line.Parent = HullParts
		end
	end

	local shouldUpdate = true

	for _, point in ipairs(StoryFolder:GetChildren()) do
		if point.Name ~= "PolygonPoint" then
			continue
		end

		point:GetPropertyChangedSignal("Position"):Connect(function()
			shouldUpdate = true
		end)
	end

	local t = task.defer(function()
		while true do
			if shouldUpdate then
				shouldUpdate = false
				generateHull()
			end
			task.wait(0.05)
		end
	end)

	return function()
		task.cancel(t)
		StoryFolder:Destroy()
	end
end
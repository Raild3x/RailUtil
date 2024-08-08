--!strict
-- Logan Hunt [Raildex]
-- Feb 8, 2023
--[=[
	@class DrawUtil
	@deprecated This class is currently unsupported.

	DrawUtil is a collection of functions that allow you to draw things in the world.

	USAGE:
	Below is some example code that shows how to utilize DrawUtil to draw a vector.
	```lua
		local DrawUtil = require(game:GetService("ReplicatedStorage").DrawUtil)

		DrawUtil.vector("MyVector", Vector3.new(0, 0, 0), Vector3.new(0, 10, 0), Color3.new(1, 0, 0), 1)
	```
]=]

type PartProps = {
	Name: string?,
	CFrame: CFrame?,
	Position: Vector3?,
	Orientation: Vector3?,
	Size: Vector3?,
	Color: Color3?,
	Transparency: number?,
	Parent: Instance?,
	[string]: any,
}

local function clearItemFromFolder(folderName, itemName)
	local folder = workspace:FindFirstChild(folderName)

	if folder == nil then
		return
	end

	local item = folder:FindFirstChild(itemName)
	if item then
		item:Destroy()
	end
end

--------------------------------------------------------------------------------
	--// Class //--
--------------------------------------------------------------------------------

local DrawUtil = {}

function DrawUtil.vectorFromCFrame(name: string, cf: CFrame, color, scale)
	return DrawUtil.vector(name, cf.Position, cf.Position + cf.LookVector, color, scale)
end

function DrawUtil.vector(name: string, from: Vector3, to: Vector3, color: Color3?, scale: number?)
	color = color or BrickColor.random().Color
	scale = scale or 1

	if typeof(from) == "Instance" then
		if from:IsA("BasePart") then
			from = from.CFrame
		elseif from:IsA("Attachment") then
			from = from.WorldCFrame
		end

		if to ~= nil then
			from = from.p
		end
	end

	if typeof(to) == "Instance" then
		if to:IsA("BasePart") then
			to = to.Position
		elseif to:IsA("Attachment") then
			to = to.WorldPosition
		end
	end

	if typeof(from) == "CFrame" and to == nil then
		local look = from.lookVector
		to = from.p
		from = to + (look * -10)
	end

	if to == nil then
		to = from
		from = to + Vector3.new(0, 10, 0)
	end

	assert(typeof(from) == "Vector3" and typeof(to) == "Vector3", "Passed parameters are of invalid types")

	local container = workspace:FindFirstChild("Arrows") or Instance.new("Folder")
	container.Name = "Arrows"
	container.Parent = workspace

	local arrow = container:FindFirstChild(name) or Instance.new("Folder")
	arrow.Name = name

	local shaft = arrow:FindFirstChild(name .. "_shaft") or Instance.new("CylinderHandleAdornment")
	shaft.Height = (from - to).Magnitude - 2
	shaft.CFrame = CFrame.lookAt(((from + to) / 2) - ((to - from).unit * 1), to)

	if shaft.Parent == nil then
		shaft.Name = name .. "_shaft"
		shaft.Color3 = color
		shaft.Radius = 0.15
		shaft.Adornee = workspace.Terrain
		shaft.Transparency = 0
		shaft.Radius = 0.15 * scale
		shaft.Transparency = 0
		shaft.AlwaysOnTop = true
		shaft.ZIndex = 5 - math.ceil(scale)
	end

	shaft.Parent = arrow

	local pointy = arrow:FindFirstChild(name .. "_head") or Instance.new("ConeHandleAdornment")

	scale = scale == 1 and 1 or 1.4

	if pointy.Parent == nil then
		pointy.Name = name .. "_head"
		pointy.Color3 = color
		pointy.Radius = 0.5 * scale
		pointy.Transparency = 0
		pointy.Adornee = workspace.Terrain
		pointy.Height = 2 * scale
		pointy.AlwaysOnTop = true
		pointy.ZIndex = 5 - math.ceil(scale)
	end

	pointy.CFrame = CFrame.lookAt((CFrame.lookAt(to, from) * CFrame.new(0, 0, -2 - ((scale - 1) / 2))).p, to)

	arrow.Parent = container

	if scale == 1 then
		DrawUtil.vector(name .. "_backdrop", from, to, Color3.new(0, 0, 0), 2)
	end
end

--[=[
	Clears a vector from the world.
	@param name The name of the vector to clear.
]=]
function DrawUtil.clearVector(name: string)
	clearItemFromFolder("Arrows", name)
	clearItemFromFolder("Arrows", name .. "_backdrop")
end

--[=[
	Draws a point in the world.
]=]
function DrawUtil.point(name: string, position: Vector3 | CFrame, radius: number?, color: Color3?)
	local container = workspace:FindFirstChild("Points") or Instance.new("Folder")
	container.Name = "Points"
	container.Parent = workspace

	radius = radius or 0.25
	color = color or Color3.new(1, 1, 1)

	local point = container:FindFirstChild(name) or Instance.new("Part")

	if point.Parent == nil then
		point.Name = name
		point.CanQuery = false
		point.Anchored = true
		point.CanCollide = false
		point.CastShadow = false
		point.Shape = Enum.PartType.Ball
	end

	if typeof(position) == "CFrame" then
		position = position.Position
	end

	point.Position = position
	point.Size = Vector3.one * radius
	point.Color = color

	point.Parent = container

	return point
end

--[=[
	Clears a point from the world.
	@param name The name of the point to clear.
]=]
function DrawUtil.clearPoint(name: string)
	clearItemFromFolder("Points", name)
end

--[=[
	Draws a line between two points in the world.
]=]
function DrawUtil.line(name: string, from: Vector3, to: Vector3, radius: number?, color: Color3?)
	local container = workspace:FindFirstChild("Lines") or Instance.new("Folder")
	container.Name = "Lines"
	container.Parent = workspace

	radius = radius or 0.25

	local line = container:FindFirstChild(name) or Instance.new("Part")

	if line.Parent == nil then
		line.Name = name
		line.CanQuery = false
		line.Anchored = true
		line.CanCollide = false
		line.CastShadow = false
		line.Shape = Enum.PartType.Cylinder
	end
	
	line.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -((from - to).Magnitude / 2))
	line.Size = Vector3.new((from - to).Magnitude, radius, radius)
	line.Color = color or Color3.new(1, 1, 1)

	line.Parent = container

	return line
end

--[=[
	Clears a line from the world.
	@param name The name of the line to clear.
]=]
function DrawUtil.clearLine(name: string)
	clearItemFromFolder("Lines", name)
end

return DrawUtil

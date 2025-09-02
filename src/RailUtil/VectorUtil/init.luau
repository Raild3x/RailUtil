--!strict
--!native
-- Logan Hunt [Raildex]
-- Nov 22, 2022

local random = Random.new(os.clock())
local MathUtil = require(script.Parent.MathUtil)

--[=[
	@type Vector Vector3 | Vector2
	@within VectorUtil
]=]
type Vector = Vector3 | Vector2

--[=[
	@type Plane {number}
	@within VectorUtil
	Data type representing a plane. The plane is represented by a table with 4 values. Typically used for plane intersection calculations.
]=]
type Plane = {number}


-- Function to determine orientation of three points
local function orientation(p: Vector2, q: Vector2, r: Vector2): number
	local val = (q.Y - p.Y) * (r.X - q.X) - (q.X - p.X) * (r.Y - q.Y)
	if val == 0 then return 0 -- Collinear
	elseif val > 0 then return 1 -- Clockwise
	else return 2 -- Counterclockwise
	end
end

--------------------------------------------------------------------------------
--[=[
	@class VectorUtil

	A library of useful vector functions.
]=]
local VectorUtil = {}


--[=[
	Splits a Vector into its components.
]=]
function VectorUtil.unpack(Vector: Vector): (...number)
	if typeof(Vector) == "Vector3" then
		return Vector.X, Vector.Y, Vector.Z
	end
	return Vector.X, Vector.Y
end

--[=[
	Snaps a Vector to the nearest multiple of the given number for each coordinate.
]=]
function VectorUtil.snap<T>(vector: T & Vector, snapToNearestMultiple: number): Vector
	if typeof(vector) == "Vector3" then
		return Vector3.new(
			MathUtil.round(vector.X, snapToNearestMultiple),
			MathUtil.round(vector.Y, snapToNearestMultiple),
			MathUtil.round(vector.Z, snapToNearestMultiple)
		)
	end
	return Vector2.new(
		MathUtil.round(vector.X, snapToNearestMultiple),
		MathUtil.round(vector.Y, snapToNearestMultiple)
	)
end

--[=[
	@tag Vector2
	@tag Vector3
	Rounds a Vectors length to the nearest multiple of the given number.
]=]
function VectorUtil.roundLength<T>(vector: T & Vector, increment: number): T
	return VectorUtil.normalize(vector) * MathUtil.round(vector.Magnitude, increment) :: any
end


--[=[
	Returns a random unit vector3. Evenly distributes around the unit sphere.
]=]
function VectorUtil.randomUnitVector(): Vector3
	return random:NextUnitVector()
end

--[=[
	Truncates the length of a vector such that if it exceeds the given length, it will be truncated to that length.
	@param Vector -- The vector to truncate.
	@param maxLength -- The maximum length of the vector.
	@return Vector -- The truncated vector.
]=]
function VectorUtil.truncate<T>(Vector: T & Vector, maxLength: number): T
	local magnitude = Vector.Magnitude
	if magnitude > maxLength then
		return (Vector :: any) * (maxLength / magnitude)
	end
	return Vector
end

--[=[
	Returns the angle of a Vector2 relative to the X axis.
]=]
function VectorUtil.getAngle(vector: Vector2): number
	return math.atan2(vector.Y, vector.X)
end

--[=[
	Returns the shortest angle between two vectors in Radians.
]=]
function VectorUtil.getAngleBetween(firstVector: Vector, secondVector: Vector): number
	return math.acos((firstVector.Unit :: any):Dot(secondVector.Unit))
end

--[=[
	Returns a signed angle in radians between two Vector3s around a given axis.
	The sign is calculated counter-clockwise, left of first vector is positive, right of first vector is negative.
	@param firstVector -- The start of the angle
	@param secondVector -- The end of the angle
	@param axis -- The axis to rotate around
	@return number -- The signed angle between the two vectors in radians.
]=]
function VectorUtil.getSignedAngleBetweenVector3s(firstVector: Vector3, secondVector: Vector3, axis: Vector3): number
	local angle = VectorUtil.getAngleBetween(firstVector, secondVector)

	-- Calculate the cross product of the vectors
	local crossProduct = firstVector:Cross(secondVector)

	-- Determine the sign of the angle using the dot product with the axis
	local dotProduct = crossProduct:Dot(axis)

	if dotProduct < 0 then
		angle = -angle  -- Reverse the angle if it's negative
	end

	return angle
end

--[=[
	Returns a signed angle in radians between two vectors.
	The sign is calculated counter-clockwise, left of first
	vector is positive, right of first vector is negative.
	@param firstVector -- The start of the angle
	@param secondVector -- The end of the angle
	@return number -- The signed angle between the two vectors in radians.
]=]
function VectorUtil.getSignedAngleBetweenVector2s(firstVector: Vector2, secondVector: Vector2): number
	return VectorUtil.getAngle(secondVector) - VectorUtil.getAngle(firstVector)
end

--[=[
	@ignore
	Returns a CFrame that ... [DOCUMENTATION NEEDED] (Used for Slerping)
]=]
-- function VectorUtil.getRotationBetween(u: Vector3, v: Vector3, axis: Vector3): CFrame
-- 	local dot, uxv = u:Dot(v), u:Cross(v)
-- 	if dot < -0.99999 then
-- 		return CFrame.fromAxisAngle(axis, math.pi)
-- 	end
-- 	return CFrame.new(0, 0, 0, uxv.X, uxv.Y, uxv.Z, 1 + dot)
-- end

--[=[
	Checks if a given vector is NaN.
]=]
function VectorUtil.isNaN(vector: Vector): boolean
	return vector ~= vector
end

--[=[
	Returns the absolute value of the Vector
]=]
function VectorUtil.abs<T>(Vector: T & Vector): T
	if typeof(Vector) == "Vector3" then
		return Vector3.new(math.abs(Vector.X), math.abs(Vector.Y), math.abs(Vector.Z)) :: any
	end
	return Vector2.new(math.abs(Vector.X), math.abs(Vector.Y)) :: any
end

--[=[
	Returns a Vector where each component is the sign of the original Vector.
]=]
function VectorUtil.sign<T>(Vector: T & Vector): T
	if typeof(Vector) == "Vector3" then
		return Vector3.new(math.sign(Vector.X), math.sign(Vector.Y), math.sign(Vector.Z)) :: any
	end
	return Vector2.new(math.sign(Vector.X), math.sign(Vector.Y)) :: any
end

--[=[
	Safely Normalizes a Vector.
]=]
function VectorUtil.normalize<T>(Vector: T & Vector): T
	return (if Vector.Magnitude == 0 then Vector else Vector.Unit) :: any
end

--[=[
	Flattens a Vector3 on its Y axis
	@param Vector -- The Vector3 to flatten.
	@param newY -- the height to flatten the vector to. Defaults to 0.
	@return Vector3 -- The flattened Vector3.
]=]
function VectorUtil.flattenY(Vector: Vector3, newY: number?): Vector3
	return Vector3.new(Vector.X, newY or 0, Vector.Z)
end

--[=[
	Flattens a given Vector3 on a specified axis
	@param Vector -- The Vector3 to flatten.
	@param axis -- The axis to flatten the vector on. Defaults to "Y".
	@param defaultValue -- The value to set the flattened axis to. Defaults to 0.
	@return Vector3 -- The flattened Vector3.
]=]
function VectorUtil.flatten(Vector: Vector3, axis: Enum.Axis, defaultValue: number?): Vector3
	if axis then
		if axis == Enum.Axis.X then
			return Vector3.new(defaultValue or 0, Vector.Y, Vector.Z)
		elseif axis == Enum.Axis.Y then
			return Vector3.new(Vector.X, defaultValue or 0, Vector.Z)
		elseif axis == Enum.Axis.Z then
			return Vector3.new(Vector.X, Vector.Y, defaultValue or 0)
		end
	end
	return Vector3.new(Vector.X, defaultValue or 0, Vector.Z)
end

--[=[
	Takes a Vector and removes all values except the specified Axis.
	@param vector -- The Vector to pull from
	@param axis -- The axis to get
	@return Vector3 -- The returned Vector containing only the specified axis.
]=]
function VectorUtil.getAxis(vector: Vector3, axis: Enum.Axis): Vector3
	return vector * Vector3.FromAxis(axis)
end

--[=[
	Takes a Vector and sets the axis value to the specified number.
	@param vector -- The Vector to change from
	@param axis -- The axis to set
	@param value -- The new value of the axis
	@return Vector3 -- The adjusted Vector
]=]
function VectorUtil.setAxis(vector: Vector3, axis: Enum.Axis, value: number): Vector3
	local X, Y, Z = vector.X, vector.Y, vector.Z
	if axis == Enum.Axis.X then
		return Vector3.new(value, Y, Z)
	elseif axis == Enum.Axis.Y then
		return Vector3.new(X, value, Z)
	elseif axis == Enum.Axis.Z then
		return Vector3.new(X, Y, value)
	end
	error("Invalid Axis")
end

--[=[
	Rotates a vector about its axis by the given angles.
	Takes a CFrame.Angles object as the angles to rotate by. Works similarly to rotating a CFrame.
	@param vectorToRotate Vector3 -- The vector to rotate.
	@param anglesToRotate ({number} | Vector3 | CFrame) -- The angles to rotate the vector by. 
	@return Vector3 -- The rotated vector.

	rotateVector(Vector3.new(1,0,0), CFrame.Angles(0,math.pi,0)) -- Output: Vector3.new(-1,0,0)
]=]
function VectorUtil.rotateVector3(
	vectorToRotate: Vector3,
	anglesToRotate: ({number} | Vector3 | CFrame)
): Vector3
	if typeof(anglesToRotate) == "table" then
		anglesToRotate = CFrame.Angles(table.unpack(anglesToRotate))
	elseif typeof(anglesToRotate) == "Vector3" then
		anglesToRotate = CFrame.Angles(anglesToRotate.X, anglesToRotate.Y, anglesToRotate.Z)
	end
	return (anglesToRotate :: CFrame):VectorToWorldSpace(vectorToRotate)
end

--[=[
	Rotates a vector2 by a given amount of radians.
	@param vectorToRotate -- The vector to rotate.
	@param angle -- The angle [In Radians] to rotate the vector by.
	@return Vector2 -- The rotated vector.
]=]
function VectorUtil.rotateVector2(vectorToRotate: Vector2, angle: number): Vector2
	local s = math.sin(angle)
	local c = math.cos(angle)
	local x = vectorToRotate.X * c - vectorToRotate.Y * s
	local y = vectorToRotate.X * s + vectorToRotate.Y * c
	return Vector2.new(x, y)
end

--[=[
	Rotates a vector.
	@ignore

	@param ... any
	@return Vector
]=]
function VectorUtil.rotateVector(vector: Vector, ...): Vector
	if typeof(vector) == "Vector3" then
		return VectorUtil.rotateVector3(vector, ...)
	elseif typeof(vector) == "Vector2" then
		return VectorUtil.rotateVector2(vector, ...)
	end
	error("VectorUtil.rotateVector: Invalid Vector Type")
end

--[=[
	Finds the closest point on a line to a given point.
	@param refPoint -- The point to find the closest point to.
	@param linePoint -- A point along the line.
	@param lineDirection -- The direction of the line.
	@return Vector3 -- The closest point on the line to the reference point.
]=]
function VectorUtil.closestPointOnLine(refPoint: Vector3, linePoint: Vector3, lineDirection: Vector3): Vector3
	local t = lineDirection:Dot(refPoint - linePoint) / lineDirection:Dot(lineDirection)
	return linePoint + lineDirection * t
end

--[=[
	Finds the closest two points on two lines.
	The lines are defined by some point along them and a direction
	@param point1 -- A point along the first line.
	@param direction1 -- The direction of the first line.
	@param point2 -- A point along the second line.
	@param direction2 -- The direction of the second line.
	@return Vector2 --The closest point on the first line.
	@return Vector2 -- The closest point on the second line.
]=]
function VectorUtil.closestPointsBetweenLines(point1: Vector3, direction1: Vector3, point2: Vector3, direction2: Vector3): (Vector3, Vector3)
	local a = direction1:Dot(direction1)
	local b = direction1:Dot(direction2)
	local c = direction2:Dot(direction2)
	local d = (point1 - point2):Dot(direction1)
	local e = (point1 - point2):Dot(direction2)

	local t1 = (b * e - c * d) / (a * c - b * b)
	local t2 = (a * e - b * d) / (a * c - b * b)

	local closest1 = point1 + direction1 * t1
	local closest2 = point2 + direction2 * t2

	return closest1, closest2
end

--[=[
	Finds the intersection point of a line and a plane.
	@param lineOrigin -- A point along the line.
	@param lineDirection -- The direction of the line.
	@param planeOrigin -- A point on the plane.
	@param planeNormal -- The normal of the plane.
	@return Vector3? -- The intersection point of the line and the plane if one exists.
]=]
function VectorUtil.planeIntersectionPoint(lineOrigin: Vector3, lineDirection: Vector3, planeOrigin: Vector3, planeNormal: Vector3): Vector3?
	local t = (planeNormal:Dot(planeOrigin) - planeNormal:Dot(lineOrigin)) / planeNormal:Dot(lineDirection)
	if t < 0 then
		-- The line and the plane are parallel or the intersection point is behind the line
		return nil
	else
		-- Calculate the intersection point
		local intersectionPoint = lineOrigin + lineDirection * t
		return intersectionPoint
	end
end

--[=[
	Tests whether or not a line of infinite length intersects a sphere at some point.
	@param lineOrigin -- A point along the line.
	@param lineDirection -- The direction of the line.
	@param sphereOrigin -- The origin of the sphere.
	@param sphereRadius -- The radius of the sphere.
	@return boolean -- Whether or not the line intersects the sphere.
]=]
function VectorUtil.lineIntersectsSphere(lineOrigin: Vector3, lineDirection: Vector3, sphereOrigin: Vector3, sphereRadius: number): boolean
	local closestPoint = VectorUtil.closestPointOnLine(sphereOrigin, lineOrigin, lineDirection)
	local distance = (closestPoint - sphereOrigin).Magnitude
	return distance <= sphereRadius
end

--[=[
	Tests whether or not a line **segment** intersects a sphere at some point.
	Only returns true if the intersection point is between the two points of the line segment.

	@param linePoint1 -- The start point of the line segment.
	@param linePoint2 -- The end point of the line segment.
	@param sphereOrigin -- The center point of the sphere.
	@param sphereRadius -- The radius of the sphere.
	@return boolean -- Whether or not the line segment intersects the sphere.
]=]
function VectorUtil.lineSegmentIntersectsSphere(linePoint1: Vector3, linePoint2: Vector3, sphereOrigin: Vector3, sphereRadius: number): boolean
    local dir = linePoint2 - linePoint1
    local lineToCenter = sphereOrigin - linePoint1

    local t = lineToCenter:Dot(dir) / dir.Magnitude^2

    if t < 0 then
        t = 0
    elseif t > 1 then
        t = 1
    end

    local closestPoint = linePoint1 + (dir * t)
    local distanceSq = (sphereOrigin - closestPoint).Magnitude^2

    return distanceSq <= (sphereRadius^2)
end

--[=[
	Creates a plane from three points. The normal of the plane is determined by the input order of the points.
	Planes are used by other RailUtil.Vector functions in order to allow precomputation.
	@param p1 -- The first point.
	@param p2 -- The second point.
	@param p3 -- The third point.
	@return Plane -- The plane defined by the three points.
]=]
function VectorUtil.calculatePlaneFromPoints(p1: Vector3, p2: Vector3, p3: Vector3): Plane
	local normal = (p2 - p1):Cross(p3 - p1).Unit
	return VectorUtil.calculatePlaneFromPointAndNormal(p1, normal)
end

--[=[
	Creates a plane from a point and a normal.
	Planes are used by other RailUtil.Vector functions in order to allow precomputation.
	@param point -- A point on the plane.
	@param normal -- The normal of the plane.
	@return Plane -- The plane defined by the point and normal.
]=]
function VectorUtil.calculatePlaneFromPointAndNormal(point: Vector3, normal: Vector3): Plane
	local d = point.X * normal.X + point.Y * normal.Y + point.Z * normal.Z
	return {normal.X, normal.Y, normal.Z, d}
end

--[=[
	Checks if a point lies on a plane. Use one of the `calculatePlane` functions to generate a plane.
	@param point -- The point to check.
	@param plane -- The plane to check against.
	@return boolean -- Whether or not the point lies on the plane.

	```lua
	local plane = VectorUtil.calculatePlaneFromPoints(Vector3.new(0,0,0), Vector3.new(1,0,0), Vector3.new(0,1,0))
	local point = Vector3.new(1,1,0)

	VectorUtil.pointLiesOnPlane(point plane) -- Output: true
	```
]=]
function VectorUtil.pointLiesOnPlane(point: Vector3, plane: Plane): boolean
	local X, Y, Z = plane[1], plane[2], plane[3]
	return (X * point.X + Y * point.Y + Z * point.Z) == plane[4]
end

--[=[
	Projects a vector onto a plane defined by a normal.
	@param dir -- The vector to project.
	@param normal -- The normal of the plane to project onto. Defaults to Vector3.new(0, 1, 0).
	@return Vector3 -- The projected vector.

	```lua
	local dir = Vector3.new(1, 1, 1)
	local normal = Vector3.new(0, 1, 0)

	VectorUtil.projectVectorToPlane(dir, normal) -- Output: Vector3.new(1, 0, 1)
	```
]=]
function VectorUtil.projectVectorToPlane(dir: Vector3, normal: Vector3?): Vector3
    -- Normalize the plane's normal vector to ensure correct projection
    local normalizedNormal = (normal or Vector3.yAxis).Unit

    -- Project the vector onto the normal and subtract to flatten it to the plane
    local projectionOntoNormal = dir:Dot(normalizedNormal) * normalizedNormal
    local flattenedVector = dir - projectionOntoNormal

    return flattenedVector
end


--[=[
	Checks if a point is inside a polygon defined by a set of points.
	The points *must* be in order within the array, this order defines the winding of the polygon.

	@param point -- The point to check.
	@param polygon -- The polygon to check against.
	@return boolean -- Whether or not the point is inside the polygon.

	```lua
	local point = Vector2.new(0, 0)
	local polygon = {
		Vector2.new(1, 0),
		Vector2.new(0, 1),
		Vector2.new(0, 0)
	}

	VectorUtil.pointInPolygon2D(point, polygon) -- Output: true
	```
]=]
function VectorUtil.pointInPolygon2D(point: Vector2, polygon: {Vector2}): boolean
    local crossings = 0
    local count = #polygon

    for i = 1, count do
        local v1 = polygon[i]
        local v2 = polygon[i % count + 1] -- Wrap around to the first point

        -- Check if the ray crosses the edge
        if (v1.Y > point.Y) ~= (v2.Y > point.Y) then
            local intersectX = (v2.X - v1.X) * (point.Y - v1.Y) / (v2.Y - v1.Y) + v1.X
            if point.X < intersectX then
                crossings += 1
            end
        end
    end

    return crossings % 2 == 1 -- Odd number of crossings means inside
end

--[=[
	Checks if a point is inside a polygon defined by a set of points and a normal. The polygon has infinite height, extending in both directions
	of the surface normal. The points that define the polygon must be in order within the array if you aren't using the Hull flag.
	The order of the points defines the winding of the polygon.

	Allows for checking against the convex hull of the polygon by setting the `_useHull` parameter to true.
	This should be used only when needed as it can result in a higher computational cost in some scenarios.

	@param point -- The point to check.
	@param polygon -- The polygon to check against.
	@param _normal -- The normal of the polygon. Defaults to Vector3.new(0, 1, 0).
	@param _useHull -- Whether or not to use the convex hull of the polygon. Defaults to false.
	@return boolean -- Whether or not the point is inside the polygon.

	```lua
	local point = Vector3.new(0, 0, 0)
	local polygon = {
		Vector3.new(1, 0, 0),
		Vector3.new(0, 1, 0),
		Vector3.new(0, 0, 1)
	}
	local normal = Vector3.new(1, 1, 1)

	VectorUtil.pointInPolygon3D(point, polygon, normal) -- Output: true
	```
]=]
function VectorUtil.pointInPolygon3D(point: Vector3, polygon: {Vector3}, _normal: Vector3?, _useHull: boolean?): boolean
	if #polygon < 3 then
        return false -- Not a valid polygon
    end

	local normal = _normal or Vector3.yAxis

    -- Pick a reference point on the plane
    local planePoint = polygon[1]

	local function projectPointOntoPlane(point: Vector3, normal: Vector3): Vector3
		local toPoint = point - planePoint
		local distance = toPoint:Dot(normal)
		return point - normal * distance -- Projected point
	end

    -- Project all points and the test point onto the plane
    local projectedPoints = {}
    for _, p in pairs(polygon) do
        table.insert(projectedPoints, projectPointOntoPlane(p, normal))
    end
    local projectedTestPoint = projectPointOntoPlane(point, normal)

    -- Generate a 2D basis using two edges of the polygon
    local u = (projectedPoints[2] - projectedPoints[1]).Unit
    local v = normal:Cross(u) -- Perpendicular vector

    -- Convert 3D projected points into 2D
    local polygon2D = {}
    for _, p in pairs(projectedPoints) do
        local relative = p - planePoint
        table.insert(polygon2D, Vector2.new(relative:Dot(u), relative:Dot(v)))
    end

    -- Convert the test point to 2D
    local relativeTest = projectedTestPoint - planePoint
    local testPoint2D = Vector2.new(relativeTest:Dot(u), relativeTest:Dot(v))

	if _useHull then
		polygon2D = VectorUtil.calculateConvexHullGiftWrap(polygon2D)
	end

    -- Check if the test point is inside the polygon
    return VectorUtil.pointInPolygon2D(testPoint2D, polygon2D)
end

--[=[
	Uses Graham's scan algorithm to calculate the convex hull of a set of 2D points.
	Graham's scan is better suited for larger sets of points than Giftwrapping.
	However, they will produce the same result.

	@param points -- The points to calculate the convex hull of.
	@return {Vector2} -- The convex hull of the points.

	```lua
	local points = {
		Vector2.new(0, 0),
		Vector2.new(1, 0),
		Vector2.new(0.5, 0.5)
		Vector2.new(0, 1),
		Vector2.new(1, 1),
	}

	local hull = VectorUtil.calculateConvexHullGrahamScan(points) -- Output: {Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(1, 1), Vector2.new(0, 1)}
	```
]=]
function VectorUtil.calculateConvexHullGrahamScan(points: {Vector2}): {Vector2}
	local n = #points
	if n < 3 then
		warn("Cannot calculate convex hull with less than 3 points.")
		return points
	end

	-- Find the lowest point (break ties by X)
	local lowest = 1
	for i = 2, n do
		if points[i].Y < points[lowest].Y or (points[i].Y == points[lowest].Y and points[i].X < points[lowest].X) then
			lowest = i
		end
	end

	-- Swap lowest point to front
	points[1], points[lowest] = points[lowest], points[1]
	local p0 = points[1]

	-- Sort by polar angle with respect to the lowest point
	table.sort(points, function(a, b)
		local o = orientation(p0, a, b)
		if o == 0 then -- If collinear, keep the farthest point
			return (p0 - a).Magnitude < (p0 - b).Magnitude
		end
		return o == 2 -- Sort counterclockwise
	end)

	-- Process points using a stack
	local hullSize = 2
	local hull = {points[1], points[2]}

	for i = 3, n do
		while hullSize >= 2 and orientation(hull[hullSize - 1], hull[hullSize], points[i]) ~= 2 do
			table.remove(hull, hullSize) -- Remove the last point if it makes a right turn (clockwise)
			hullSize -= 1
		end
		hullSize += 1
		table.insert(hull, hullSize, points[i]) -- Add the current point to the hull
	end

	return hull
end

--[=[
	Uses the Giftwrapping algorithm (Jarvis March) to calculate the convex hull of a set of 2D points.
	Giftwrapping is better suited for smaller sets of points than Graham's scan.
	However, they will produce the same result.

	@param points -- The points to calculate the convex hull of.
	@return {Vector2} -- The convex hull of the points.

	```lua
	local points = {
		Vector2.new(0, 0),
		Vector2.new(1, 0),
		Vector2.new(0.5, 0.5)
		Vector2.new(0, 1),
		Vector2.new(1, 1),
	}

	local hull = VectorUtil.calculateConvexHullGiftWrap(points) -- Output: {Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(1, 1), Vector2.new(0, 1)}
	```
]=]
function VectorUtil.calculateConvexHullGiftWrap(points: {Vector2}): {Vector2}
	local n = #points
	if n < 3 then
		warn("Cannot calculate convex hull with less than 3 points.")
		return points
	end
	
	-- find leftmost point
	local l = 1
	for i = 2, n do
		if points[i].X < points[l].X or (points[i].X == points[l].X and points[i].Y < points[l].Y) then
			l = i
		end
	end

	local hull = table.create(math.floor(n/2)) -- try to do a little space preallocation

	-- Start from leftmost point, keep moving counterclockwise until we reach the start point again
	-- This loop runs O(h) times where h is the number of points in the hull
	local p, q = l, 0
	repeat
		-- Add current point to hull
		table.insert(hull, points[p])

		-- Search for a point 'q' such that  
		-- orientation(p, x, q) is counterclockwise  
		-- for all points 'x'. The idea is to keep  
		-- track of last visited most counterclock- 
		-- wise point in q. If any point 'i' is more  
		-- counterclock-wise than q, then update q.
		q = (p + 1) % n + 1

		for i = 1, n do
			-- If i is more counterclockwise than current q, then update q
			if orientation(points[p], points[i], points[q]) == 2 then
				q = i
			end
		end

		-- Now q is the most counterclockwise with respect to p
		-- Set p as q for next iteration, so that q is added to hull
		p = q

	-- While we don't come to the first point
	until p == l

	return hull
end

--[=[
	Reflects a vector off a surface normal.
	@param dir -- The vector to reflect.
	@param normal -- The normal of the surface to reflect off of.
	@return Vector3 -- The reflected vector.
]=]
function VectorUtil.reflect(dir: Vector3, normal: Vector3): Vector3
	return dir - 2 * dir:Dot(normal) * normal
end

--[=[
	Reflects a vector ignoring the Y component of the surface normal.
	This is useful when you want to keep reflections on a 2D plane.
	@param dir -- The vector to reflect.
	@param surfaceNormal -- The normal of the surface to reflect off of.
	@return Vector3 -- The reflected vector.
]=]
function VectorUtil.reflectIgnoringY(dir: Vector3, surfaceNormal: Vector3): Vector3
    -- Flatten the surface normal by setting the Y component to 0
    local flattenedNormal = Vector3.new(surfaceNormal.X, 0, surfaceNormal.Z)
    
    -- Normalize the flattened normal to make sure it's a unit vector
    local normalizedNormal = flattenedNormal.Magnitude > 0 and flattenedNormal.Unit or Vector3.zero

    -- Calculate the reflection using the flattened normal
    local reflectedVector = dir - 2 * dir:Dot(normalizedNormal) * normalizedNormal

    return reflectedVector
end


return table.freeze(VectorUtil)

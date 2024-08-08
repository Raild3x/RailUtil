--!strict
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
	return VectorUtil.normalize(vector) * MathUtil.round(vector.Magnitude, increment)
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
function VectorUtil.abs<T>(Vector: T & Vector): Vector
	if typeof(Vector) == "Vector3" then
		return Vector3.new(math.abs(Vector.X), math.abs(Vector.Y), math.abs(Vector.Z))
	end
	return Vector2.new(math.abs(Vector.X), math.abs(Vector.Y))
end

--[=[
	Returns a Vector where each component is the sign of the original Vector.
]=]
function VectorUtil.sign<T>(Vector: T & Vector): Vector
	if typeof(Vector) == "Vector3" then
		return Vector3.new(math.sign(Vector.X), math.sign(Vector.Y), math.sign(Vector.Z))
	end
	return Vector2.new(math.sign(Vector.X), math.sign(Vector.Y))
end

--[=[
	Safely Normalizes a Vector.
]=]
function VectorUtil.normalize<T>(Vector: T & Vector): Vector
	return if Vector.Magnitude == 0 then Vector else Vector.Unit
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


return table.freeze(VectorUtil)

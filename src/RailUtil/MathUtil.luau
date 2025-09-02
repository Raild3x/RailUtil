--!strict
--!native
-- Logan Hunt [Raildex]
-- Nov 22, 2022
--[=[
	@class MathUtil

	A library of useful math functions.
]=]

--[=[
	@type MathOperation ("+" | "-" | "*" | "/" | "^" | "%")
	@within MathUtil
	A type consisting of all the valid math operations in string format.
]=]
export type MathOperation = "+" | "-" | "*" | "/" | "^" | "%"

local EPSILON = 0.001

local MathUtil = {}

--[=[
	Takes a value and snaps it to the closest one of the following values.
	@param v 		-- The value to snap.
	@param ... 		-- The array or variadic of number values to snap to.
	@return number 	-- The closest value to the given value.
]=]
function MathUtil.snap(v: number, ...: number | { number }): number
	local minDiff = math.huge
	local closestValue = v
	local snapValues: {number} = (if typeof(...) == "number" then { ... :: number } else ...) :: {number}

	for _, snapV in ipairs(snapValues) do
		local diff = math.abs(v - snapV)

		if diff < minDiff then
			minDiff = diff
			closestValue = snapV
		end
	end

	return closestValue
end

--[=[
	Returns a random float between the given min and max.
	@param min -- The minimum value.
	@param max -- The maximum value.
	@return number -- The random float.
]=]
function MathUtil.random(min: number, max: number): number
	if max < min then
		error("Max must be greater than min.")
	end
	return math.random() * (max - min) + min
end

--[=[
	Returns a random float in the given number range.
	@param numberRange -- The number range to generate a random number from.
	@return number -- The generated random number.
]=]
function MathUtil.randomFromNumberRange(numberRange: NumberRange): number
	return MathUtil.random(numberRange.Min, numberRange.Max)
end

--[=[
	Gets a random number within the given array.
	@param tbl {number} -- The array to get a random number from.
	@return number -- The random number.

]=]
function MathUtil.randomFromArray(tbl: { number }): number
	return tbl[math.random(1, #tbl)]
end

--[=[
	Gets a random number within the given ranges.
	By default the numbers within the ranges have an equal chance of being selected
	(unless the given table has a `Weight` index)

	```lua
	local n = MathUtil.randomFromRanges({1, 10}, {20, 40}) -- Returns a random number between 1 and 10 or 20 and 40.
	```
]=]
function MathUtil.randomFromRanges(...: {number} | NumberRange): number
	local ranges = {...} :: { any }
	local totalWeight = 0

	for i, range in ipairs(ranges) do
		if typeof(range) == "NumberRange" then
			range = { range.Min, range.Max }
			ranges[i] = range
		end
		
		if range[2] < range[1] then -- fix order
			range[1], range[2] = range[2], range[1]
		end
		range.Weight = range.Weight or (range[2] - range[1])
		totalWeight += range.Weight
	end
	
	local randomWeight = math.random() * totalWeight
	for _, range in ipairs(ranges) do
		randomWeight -= range.Weight
		if randomWeight <= 0 then
			return MathUtil.random(range[1], range[2])
		end
	end

	error("Failed to generate random number from ranges.")
end

--[=[
	@unreleased
	@private
	
	Generates a random number from a NumberSequence. It uses the sequence like a weight table
	and returns a random number from the sequence.
	@param sequence -- The sequence to generate a random number from.
	@return number -- The generated random number.
]=]
function MathUtil.randomFromNumberSequence(sequence: NumberSequence): number
	error(".randomFromNumberSequence Not implemented yet.")
	return 0
end

--[=[
	Trys to return a random number from the given data. It parses the data to try and figure out
	which random methodology to use.
	@param data -- The data to try and generate a random number from.
	@param ... any -- The optional arguments to pass to the random function.
]=]
function MathUtil.tryRandom(data: number | NumberRange | NumberSequence | { number }, ...): number
	if typeof(data) == "number" then
		local max = ...
		if not max then
			return data
		end
		assert(typeof(max) == "number", "If data is a number, max must be a number.")
		return MathUtil.random(data, max)
	elseif typeof(data) == "table" then
		local tuple = ...
		if tuple then
			return MathUtil.randomFromRanges(data, ...)
		else
			return MathUtil.randomFromArray(data)
		end
	elseif typeof(data) == "NumberRange" then
		return MathUtil.randomFromNumberRange(data)
	elseif typeof(data) == "NumberSequence" then
		return MathUtil.randomFromNumberSequence(data)
	else
		error("Invalid data type. Got type: " .. typeof(data))
	end
end

--[=[
	Rounds a number to the nearest specified multiple.
	@param numToRound -- The number to round.
	@param multiple -- The multiple to round to. If not specified, will round to the nearest integer.
	@return The rounded number.
]=]
function MathUtil.round(numToRound: number, multiple: number?): number
	assert(typeof(numToRound) == "number", "numToRound must be a number.")
	if not multiple then
		return math.round(numToRound)
	end
	assert(typeof(multiple) == "number", "multiple must be a number.")
	local roundedNum = numToRound + multiple / 2
	roundedNum -= roundedNum % multiple
	return roundedNum
end

--[=[
	Lerps a `number` between two other numbers based on a given alpha.
	@param a -- The first number.
	@param b -- The second number.
	@param t -- The alpha to lerp between the two numbers.
	@return The lerped number.
]=]
function MathUtil.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

--[=[
	Checks if a number is between two other numbers.
	@param numToCheck -- The number to check.
	@param bound1 -- The first bound.
	@param bound2 -- The second bound.
	@return boolean -- Whether or not the number is between the two bounds.
]=]
function MathUtil.isBetween(numToCheck: number, bound1: number, bound2: number): boolean
	assert(typeof(numToCheck) == "number", "numToCheck must be a number.")
	assert(typeof(bound1) == "number", "bound1 must be a number.")
	assert(typeof(bound2) == "number", "bound2 must be a number.")
	return (numToCheck >= bound1 and numToCheck <= bound2) or (numToCheck >= bound2 and numToCheck <= bound1)
end

--[=[
	Checks if two numbers are close to each other within a given epsilon.
	@param num1 -- The first number.
	@param num2 -- The second number.
	@param epsilon -- The epsilon to check between the two numbers. Defaults to `0.0001`.
	@return boolean -- Whether or not the two numbers are close to each other.
]=]
function MathUtil.isClose(num1: number, num2: number, epsilon: number?): boolean
	epsilon = epsilon or EPSILON
	assert(typeof(epsilon) == "number", "epsilon must be a number.")
	return MathUtil.isBetween(num1, num2 - epsilon, num2 + epsilon)
end

--[=[
	Converts a table of numbers to a NumberSequence grouped by split points. This is very useful when working with UI Gradient's transparency.
	@param values { number } | number -- The values to convert to a NumberSequence.
	@param splitPoints ({number} | number)? -- The points along the line at which the values are split. Optional only if there is one value.
	@return NumberSequence -- The generated NumberSequence.

	```lua
	local values = {4, 8}
	local sequence = MathUtil.numbersToSequence(values, 0.5)

	-- The sequence will be 4 at 0, 4 at 0.5, 8 at 0.5 + EPSILON, and 8 at 1.
	```
]=]
function MathUtil.numbersToSequence(
	values: {number} | number,
	splitPoints: ({number} | number)?
): NumberSequence
	
	splitPoints = splitPoints or {}
	if typeof(splitPoints) == "number" then
		splitPoints = { splitPoints }
	end

	if typeof(values) == "number" then
		values = { values }
	end

	local ValuesCount = #(values :: { number })

	assert(ValuesCount > 0, "You must have at least one value")
	assert(ValuesCount - 1 == #(splitPoints :: { number }), "You must have one less sequence point than values")

	if ValuesCount == 1 then
		return NumberSequence.new((values :: { number })[1])
	end

	local keypoints = {}
	for i = 1, ValuesCount do
		local value = (values :: { number })[i]
		local startPoint = (splitPoints :: { number })[i - 1]
		local endPoint = (splitPoints :: { number })[i]

		startPoint = if not startPoint or #keypoints == 0 then 0 else startPoint + EPSILON
		endPoint = endPoint or 1

		startPoint = math.clamp(startPoint, 0, 1)
		endPoint = math.clamp(endPoint, 0, 1)

		if startPoint >= endPoint then
			continue
		end

		table.insert(keypoints, NumberSequenceKeypoint.new(startPoint, value))

		if endPoint + EPSILON >= 1 then
			table.insert(keypoints, NumberSequenceKeypoint.new(1, value))
			break
		end
		
		table.insert(keypoints, NumberSequenceKeypoint.new(endPoint, value))
	end

	return NumberSequence.new(keypoints)
end

--[=[
	Performs a math operation on two numbers.
]=]
function MathUtil.operate(a: number, operator: string, b: number): number
	if operator == "+" then
		return a + b
	elseif operator == "-" then
		return a - b
	elseif operator == "*" then
		return a * b
	elseif operator == "/" then
		return a / b
	elseif operator == "^" then
		return a ^ b
	elseif operator == "%" then
		return a % b
	else
		error("Invalid operator: " .. operator)
	end
end


return table.freeze(MathUtil)

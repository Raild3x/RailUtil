--!strict
-- Authors: Logan Hunt [Raildex]
-- July 13, 2023
--[=[
	@class StringUtil

	Utility library of useful string functions.
]=]


--[=[
	@within StringUtil
	@interface StrokeData
	.Color Color3? -- The color of the stroke.
	.Joins ("miter" | "round" | "bevel")? | Enum.LineJoinMode? -- The type of joins the stroke has.
	.Thickness number? -- The thickness
	.Transparency number? -- The transparency of the stroke.
]=]
type StrokeData = {
	Color: Color3?,
	Joins: ("miter" | "round" | "bevel") | Enum.LineJoinMode?,
	Thickness: number?,
	Transparency: number?,
}

local function colorToString(color: Color3): string
	assert(typeof(color) == "Color3", "Color must be a Color3")
	local r = math.round(color.R * 255) :: any
	local g = math.round(color.G * 255) :: any
	local b = math.round(color.B * 255) :: any
	return string.format("rgb(%s,%s,%s)", r, g, b)
end

--------------------------------------------------------------------------------
	--// Class //--
--------------------------------------------------------------------------------
local StringUtil = {}

--[=[
    Returns a string with the given color applied to it.
    @param text -- The text to apply the color to.
    @param color -- The color to apply to the text.
    @return string -- The new string with the color applied.
]=]
function StringUtil.color(text: string, color: Color3): string
	return string.format(`<font color="%s">%s</font>`, colorToString(color), text)
end

--[=[
    Returns a string with the given stroke applied to it.
    @param text -- The text to apply the stroke to.
    @param data -- The stroke data to apply to the text.
    @return string -- The new string with the stroke applied.
]=]
function StringUtil.stroke(text: string, data: StrokeData): string
	assert(typeof(data) == "table", "Stroke data must be a table")
	local color = colorToString(data.Color or Color3.fromRGB(0, 0, 0))
	local joins = data.Joins
	joins = if typeof(joins) == "EnumItem" and joins.EnumType == Enum.LineJoinMode then string.lower(joins.Name) else joins
	local thickness = data.Thickness or 1
	local transparency = data.Transparency or 0

	return `<stroke color="{color}" joins="{joins}" thickness="{thickness}" transparency="{transparency}">{text}</stroke>`
end

--[=[
    Returns a string with the given options applied to it.
    @param text -- The text to apply the options to.
    @param options -- The options to apply to the text.
    @return string -- The new string with the options applied.
]=]
function StringUtil.rich(
	text: string,
	options: {
		Color: Color3?,
		Stroke: StrokeData?,
		Bold: boolean?,
		Italic: boolean?,
		Underline: boolean?,
	}
): string
	local newStr = text

	if options.Color then
		newStr = StringUtil.color(newStr, options.Color)
	end
	if options.Stroke then
		newStr = StringUtil.stroke(newStr, options.Stroke)
	end
	if options.Bold then
		newStr = string.format("<b>%s</b>", newStr)
	end
	if options.Italic then
		newStr = string.format("<i>%s</i>", newStr)
	end
	if options.Underline then
		newStr = string.format("<u>%s</u>", newStr)
	end

	return newStr
end

--[=[
	Ensures a given number or string is formatted as an asset id.
	```lua
	StringUtil.formatAssetId(123456) -- "rbxassetid://123456"
	StringUtil.formatAssetId("123456") -- "rbxassetid://123456"
	StringUtil.formatAssetId("rbxassetid://123456") -- "rbxassetid://123456"
	```
	@param id -- The asset id to format.
	@return string -- The formatted asset id.
]=]
function StringUtil.formatAssetId(id: string | number): string
	return "rbxassetid://" .. string.match(tostring(id), "%d+") :: string or ""
end

--[=[
	Formats a number with commas.
	```lua
	StringUtil.formatNumberWithCommas("12") -- "12"
	StringUtil.formatNumberWithCommas(1234) -- "1,234"
	StringUtil.formatNumberWithCommas(123456) -- "123,456"
	StringUtil.formatNumberWithCommas("1234567") -- "1,234,567"
	StringUtil.formatNumberWithCommas(12345.6789) -- "12,345.6789"
	```
]=]
function StringUtil.formatNumberWithCommas(num: number | string): string
	local formatted, k = tostring(num), 0
	while true do
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return formatted
end

--[=[
	Truncates a number to its nearest factor of 1000 and replaces the chopped off numbers
	with an appropriate suffix to enable easier reading.

	- MaxDecimals: The maximum number of decimals to show. [Default: 1]
	- ShowZeroes: Whether to always show zeroes after the decimal point.
	- AddSpace: Whether to add a space between the number and the suffix

	```lua
	StringUtil.truncateNumberWithSuffix(1.234) -- 1.2
	StringUtil.truncateNumberWithSuffix(123) -- 123
	StringUtil.truncateNumberWithSuffix(123, {MaxDecimals = 2, ShowZeroes = true}) -- 123.00
	StringUtil.truncateNumberWithSuffix(1234) -- 1.2K

	StringUtil.truncateNumberWithSuffix(123456) -- 123.5K
	StringUtil.truncateNumberWithSuffix(123456, {MaxDecimals = 1}) -- 123.4K
	StringUtil.truncateNumberWithSuffix("123456", {MaxDecimals = 2}) -- 123.45K
	StringUtil.truncateNumberWithSuffix(123456, {MaxDecimals = 3}) -- 123.456K

	StringUtil.truncateNumberWithSuffix(123456789) -- 123.4M
	StringUtil.truncateNumberWithSuffix(1234567890) -- 1.2B
	```
]=]
function StringUtil.truncateNumberWithSuffix(num: number | string, config: {
		MaxDecimals: number?,
		ShowZeroes: boolean?,
		AddSpace: boolean?,
	}?): string

	if not config then config = {} end
	assert(typeof(config) == "table", "Config must be a table")

	local maxDecimals = config.MaxDecimals or 1
	local showZeroes = config.ShowZeroes or false
	local addSpace = config.AddSpace or false

	local numSuffixes = {
		"K", -- Thousand (1,000)
		"M", -- Million (1,000,000)
		"B", -- Billion (1,000,000,000)
		"T", -- Trillion (1,000,000,000,000)
		"Q", -- Quadrillion (1,000,000,000,000,000)
		"Qt", -- Quintillion (1,000,000,000,000,000,000)
		"S", -- Sextillion (1,000,000,000,000,000,000,000)
		"St", -- Septillion (1,000,000,000,000,000,000,000,000)
		"O", -- Octillion (1,000,000,000,000,000,000,000,000,000)
		"N", -- Nonillion (1,000,000,000,000,000,000,000,000,000,000)
		"D", -- Decillion (1,000,000,000,000,000,000,000,000,000,000,000)
		"U", -- Undecillion (1,000,000,000,000,000,000,000,000,000,000,000,000)
		"Du", -- Duodecillion (1,000,000,000,000,000,000,000,000,000,000,000,000,000)
		"T", -- Tredecillion (1,000,000,000,000,000,000,000,000,000,000,000,000,000,000)
		"Qa", -- Quattuordecillion (1,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000)
	}

	-- Convert num to a number if it's a string
	if type(num) == "string" then
		num = num:gsub(",", "") -- remove commas
		num = tonumber(num) :: number
	end
	assert(type(num) == "number", "Invalid number input:"..tostring(num))

	local absNum = math.abs(num)
	local suffix = ""
	local value = num

	for i = #numSuffixes, 1, -1 do
		local threshold = 10^(3 * i)
		if absNum >= threshold then
			value = num / threshold
			suffix = numSuffixes[i]
			break
		end
	end

	local factor = 10^maxDecimals
	value = math.floor(value * factor) / factor
	local formattedValue = string.format("%."..maxDecimals.."f", value)

	if not showZeroes then
		-- Remove trailing zeros and the decimal point if there are no decimals
		formattedValue = string.gsub(formattedValue, "%.?0+$", "")
	end

	if addSpace then
		return formattedValue .. " " .. suffix
	else
		return formattedValue .. suffix
	end
end

--[=[
	Takes a number, a string defining the type of time given, and an output format and formats it to a pleasing structure ideal for displaying time.

	@param inputTime -- The time to format.
	@param inputTimeType -- The type of time that is being given to format. (d, h, m, s, ds, cs, ms)
	@param outputStringFormat -- The format of the output string. Must separated by colons, if you put a number before the timetype it will make sure the number has atleast that length, adding zeroes before it as needed. By default it will be (2h:2m:2s)
	@param config
	@return string -- The formatted time string.

	Examples:
	```lua
	StringUtil.formatTime(3600, "s", "2h:2m:2s") -- "01:00:00"
	StringUtil.formatTime(125, "s", "2h:2m:2s") -- "00:02:05"
	StringUtil.formatTime(125, "s", "1h:1m:1s") -- "0:2:5"
	StringUtil.formatTime(125, "s", "h:m:s") -- "0:2:5"
	StringUtil.formatTime(125, "s", "2h:2m:2s", {HideParentZeroValues = true}) -- "02:05"
	StringUtil.formatTime(125, "s", "h:m:s:ds") -- "0:2:5:0"
	StringUtil.formatTime(125, "s", "h:m:s:ds", {HideParentZeroValues = true}) -- "2:5:0"
	StringUtil.formatTime(3725, "s", "h:s") -- "1:125"
	StringUtil.formatTime(1000, "ms", "s") -- "1"
	```
]=]
function StringUtil.formatTime(inputTime: number, inputTimeType: string?, outputStringFormat: string?, config: {
	HideParentZeroValues: boolean?,
	Delimeter: string?,
}?): string

	-- conversion table for time types relative to seconds
	local timeTypes = table.freeze {
		d = 86400, -- day
		h = 3600, -- hour
		m = 60, -- minute
		s = 1,
		ds = 0.1, -- deciseconds
		cs = 0.01, -- centiseconds
		ms = 0.001, -- milliseconds
		["μs"] = 10^-6, -- micro seconds
		ns = 10^-9, -- nano seconds
	}

	config = config or {}
	inputTime = inputTime or 0
	local timeType = inputTimeType or "s"
	local stringFormat = outputStringFormat or "2h:2m:2s"
	local delimeter = config.Delimeter or ":"

	-- Convert input time to seconds
	local timeInSeconds = inputTime * timeTypes[timeType]

	-- Parse the output string format
	local formatParts = {}
	for part in stringFormat:gmatch("[^:]+") do
		local minWidth, formatType = part:match("(%d*)(%a+)")
		formatParts[#formatParts + 1] = { width = tonumber(minWidth) or 1, type = formatType }
	end

	-- Calculate time values based on the format parts
	local timeValues = {}
	for _, formatPart in ipairs(formatParts) do
		local timeType = formatPart.type
		local value = math.floor(timeInSeconds / timeTypes[timeType])
		timeInSeconds = timeInSeconds % timeTypes[timeType]
		timeValues[timeType] = value
	end

	-- Build the output string
	local outputParts = {}
	local parentZeroHidden = false
	for i, formatPart in ipairs(formatParts) do
		local timeType = formatPart.type
		local value = timeValues[timeType]
		local formattedValue = string.format("%0" .. formatPart.width .. "d", value)

		if config.HideParentZeroValues and value == 0 and not parentZeroHidden and i < #formatParts then
			-- Skip leading zero values if HideParentZeroValues is enabled
		else
			outputParts[#outputParts + 1] = formattedValue
			parentZeroHidden = true
		end
	end

	return table.concat(outputParts, delimeter)
end

--------------------------------------------------------------------------------
	--// Test Cases //--
--------------------------------------------------------------------------------

local err
local testAssert = function(input, expectation, messagePrefix)
	assert(
		input == expectation,
		(messagePrefix or "").."| Expected: "..tostring(expectation)..", got: "..tostring(input)
	)
end

-- Test Cases for StringUtil.truncateNumber
err = "Failed to truncate number"
testAssert(StringUtil.truncateNumberWithSuffix(1.234), "1.2", err)
testAssert(StringUtil.truncateNumberWithSuffix(123), "123", err)
testAssert(StringUtil.truncateNumberWithSuffix(1234), "1.2K", err)
testAssert(StringUtil.truncateNumberWithSuffix(123456), "123.4K", err)
testAssert(StringUtil.truncateNumberWithSuffix(123456, {MaxDecimals = 1}), "123.4K", err)
testAssert(StringUtil.truncateNumberWithSuffix("123456", {MaxDecimals = 2}), "123.45K", err)
testAssert(StringUtil.truncateNumberWithSuffix(123456, {MaxDecimals = 3}), "123.456K", err)
testAssert(StringUtil.truncateNumberWithSuffix(123456789), "123.4M", err)
testAssert(StringUtil.truncateNumberWithSuffix(1234567890), "1.2B", err)
testAssert(StringUtil.truncateNumberWithSuffix(1234567890, {AddSpace = true}), "1.2 B", err)
testAssert(StringUtil.truncateNumberWithSuffix(123456, {MaxDecimals = 3, ShowZeroes = true}), "123.456K", err)
testAssert(StringUtil.truncateNumberWithSuffix(123400, {MaxDecimals = 2, ShowZeroes = true}), "123.40K", err)
testAssert(StringUtil.truncateNumberWithSuffix(500_000), "500K", err)
testAssert(StringUtil.truncateNumberWithSuffix(500_000, {ShowZeroes = true}), "500.0K", err)

-- Test Cases for StringUtil.formatNumberWithCommas
err = "Failed to format number with commas"
testAssert(StringUtil.formatNumberWithCommas("12"), "12", err)
testAssert(StringUtil.formatNumberWithCommas(1234), "1,234", err)
testAssert(StringUtil.formatNumberWithCommas(123456), "123,456", err)
testAssert(StringUtil.formatNumberWithCommas("1234567"), "1,234,567", err)
testAssert(StringUtil.formatNumberWithCommas(12345.6789), "12,345.6789", err)

-- Test Cases for StringUtil.formatTime
err = "Failed to format time"
testAssert(StringUtil.formatTime(3600, "s", "2h:2m:2s"), "01:00:00", err)
testAssert(StringUtil.formatTime(125, "s", "2h:2m:2s"), "00:02:05", err)
testAssert(StringUtil.formatTime(125, "s", "1h:1m:1s"), "0:2:5", err)
testAssert(StringUtil.formatTime(125, "s", "h:m:s", {}), "0:2:5", err)
testAssert(StringUtil.formatTime(125, "s", "2h:2m:2s", {HideParentZeroValues = true}), "02:05", err)
testAssert(StringUtil.formatTime(125, "s", "h:m:s:ds"), "0:2:5:0", err)
testAssert(StringUtil.formatTime(125, "s", "h:m:s:ds", {HideParentZeroValues = true}), "2:5:0", err)
testAssert(StringUtil.formatTime(3725, "s", "h:s"), "1:125", err)
testAssert(StringUtil.formatTime(1000, "ms", "s"), "1", err)

return table.freeze(StringUtil)

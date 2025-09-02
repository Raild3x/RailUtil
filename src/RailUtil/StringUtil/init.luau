--!strict
-- Authors: Logan Hunt [Raildex]
-- July 13, 2023
--[=[
	@class StringUtil

	Utility library of useful string functions.
]=]

local TextService = game:GetService("TextService")

local T = require(script.Parent.Parent.T)

--[=[
	@within StringUtil
	@interface StrokeData
	.Color Color3? -- The color of the stroke.
	.Joins ("miter" | "round" | "bevel" | Enum.LineJoinMode)? -- The type of joins the stroke has.
	.Thickness number? -- The thickness of the stroke.
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
	Returns a function that transforms a string with the given color applied to it.
	@param color -- The color to apply to the text.
	@return (text: string) -> string -- A function that applies a color to the given text.

	```lua
	local yellow = StringUtil.color(Color3.new(1, 1, 0))
	local amt = yellow(5)
	local txt = `You need to go collect {amt} eggs!`
	print(txt) -- "You need to go collect <font color="rgb(255,255,0)">5</font> eggs!"
	```
]=]
function StringUtil.color(color: Color3): (text: string) -> string
	local formatString = `<font color="{colorToString(color)}">%s</font>`
	return function(text: string): string
		return string.format(formatString, tostring(text))
	end
end

--[=[
	Returns a function that transforms a string with the given options applied to it.
	@param config -- The stroke data to apply to the text.
	@return (text: string) -> string -- A function that applies a stroke to the given text.
	
	```lua
	local applyStroke = StringUtil.stroke({
		Color = Color3.new(1, 0, 0),
		Joins = Enum.LineJoinMode.Round,
		Thickness = 2,
		Transparency = 0.5,
	})
	local txt = applyStroke("Hello World!")
	```
]=]
function StringUtil.stroke(config: StrokeData): (text: string) -> string
	assert(typeof(config) == "table", "Stroke data must be a table")
	local color = colorToString(config.Color or Color3.fromRGB(0, 0, 0))
	local joins = config.Joins
	joins = if typeof(joins) == "EnumItem" and joins.EnumType == Enum.LineJoinMode then string.lower(joins.Name) else joins
	local thickness = config.Thickness or 1
	local transparency = config.Transparency or 0
	local formatStr = `<stroke color="{color}" joins="{joins}" thickness="{thickness}" transparency="{transparency}">%</stroke>`
	return function(text: string): string
		return string.format(formatStr, tostring(text))
	end
end

--[=[
	Returns a function that transforms a string with the given options applied to it.
	@param config -- The options to apply to the text.
	@return (text: string) -> string -- A function that applies a color to the given text.
	
	```lua
	local applyRich = StringUtil.rich({
		Color = Color3.new(1, 0, 0),
		Stroke = {
			Color = Color3.new(1, 0, 0),
			Joins = Enum.LineJoinMode.Round,
			Thickness = 2,
			Transparency = 0.5,
		},
		Bold = true,
		Italic = true,
		Underline = true,
	})
	local txt = applyRich("Hello World!")
	```
]=]
function StringUtil.rich(
	config: {
		Color: Color3?,
		Stroke: StrokeData?,
		Bold: boolean?,
		Italic: boolean?,
		Underline: boolean?,
	}
): (text: string) -> string
	local formatStr = "%s"

	if config.Color then
		formatStr = StringUtil.color(config.Color)(formatStr)
	end
	if config.Stroke then
		formatStr = StringUtil.stroke(config.Stroke)(formatStr)
	end
	if config.Bold then
		formatStr = string.format("<b>%s</b>", formatStr)
	end
	if config.Italic then
		formatStr = string.format("<i>%s</i>", formatStr)
	end
	if config.Underline then
		formatStr = string.format("<u>%s</u>", formatStr)
	end

	return function(text: string): string
		return string.format(formatStr, tostring(text))
	end
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
	@param inputTimeType -- The type of time that is being given to format. (w, d, h, m, s, ds, cs, ms, μs, ns)
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
		w = 604800, -- week
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
	assert(typeof(config) == "table", "Config must be a table")
	inputTime = inputTime or 0
	local timeType = inputTimeType or "s"
	local stringFormat = outputStringFormat or "2h:2m:2s"
	local delimeter = (config :: any).Delimeter or ":"

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
		local partTimeType = formatPart.type
		local value = math.floor(timeInSeconds / timeTypes[partTimeType])
		timeInSeconds = timeInSeconds % timeTypes[partTimeType]
		timeValues[partTimeType] = value
	end

	-- Build the output string
	local outputParts = {}
	local parentZeroHidden = false
	for i, formatPart in ipairs(formatParts) do
		local partTimeType = formatPart.type
		local value = timeValues[partTimeType]
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

--[=[
	Returns the largest possible font size that allows all given text to fit within the specified frame width while
	maintaining the same font size.

	@param textTable -- Table with all the text to be iterated through to get a consistent size for frames.
	@param absSize -- The AbsoluteSize property of the container.
	@param font -- The font to be used. Needed in order to determine the size of the text.
	@param config -- Configuration for customization and tweaks to sizing.
	@return number -- The font size to be used.

	```lua
	local textTable = {
		"Hello World!",
		"Egg",
		"Goodbye, Galaxy!",
	}
	local absSize = Vector2.new(100, 50)

	local maxSize = StringUtil.getMaxConsistentTextSize(textTable, absSize, Enum.Font.SourceSans)

	for _, text in pairs(textTable) do
		local label = Instance.new("TextLabel")
		label.Text = text
		label.Font = Enum.Font.SourceSans
		label.TextSize = maxSize
		label.TextWrapped = true
	end
	```
]=]
function StringUtil.getMaxConsistentTextSize(
	textTable: { [any]: string },
	absSize: Vector2,
	font: Enum.Font,
	config: {
		MinFontSize: number?,
		MaxFontSize: number?,
		Padding: Vector2?,
		TextWrapped: boolean?,
	}?
): number
	assert(T.tuple(
		T.values(T.string),
		T.Vector2,
		T.Font,
		T.optional(T.interface({
			MinFontSize = T.optional(T.number),
			MaxFontSize = T.optional(T.number),
			Padding = T.optional(T.Vector2),
			TextWrapped = T.optional(T.boolean),
		}))
	))

	-- Setup the configuration.
	config = config or {}
	assert(typeof(config) == "table", "Config must be a table")
	local maxFontSize = config.MaxFontSize or 64
	local minFontSize = config.MinFontSize or 8
	local padding = config.Padding or Vector2.new(2, 2) -- To avoid text being cut off

	if config.TextWrapped then -- This is a temporary solution and does not account for frame size Y limits!
		local splitTable = {}
		for _, text in pairs(textTable) do
			local splitText = string.split(text, " ")
			for _, word in pairs(splitText) do
				table.insert(splitTable, word)
			end
		end
		textTable = splitTable
	end

	-- Check whether or not a specific font size can fit in.
	local absSizeX = math.floor(absSize.X)
	local function canFit(fontSize)
		for _, text in pairs(textTable) do
			local textSize = TextService:GetTextSize(text, fontSize, font, Vector2.new(math.huge, math.huge))
			if textSize.X + padding.X > absSizeX then
				return false
			end
		end
		return true
	end

	-- Binary search to find the largest font size that fits all texts
	local low, high = minFontSize, maxFontSize
	local bestFit = minFontSize
	while low <= high do
		local mid = math.floor((low + high) / 2)
		if canFit(mid) then
			bestFit = mid
			low = mid + 1
		else
			high = mid - 1
		end
	end
	return bestFit
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

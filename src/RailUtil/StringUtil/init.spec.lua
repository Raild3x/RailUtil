return function()
	local StringUtil = require(script.Parent)

    local truncateNumberWithSuffix = StringUtil.truncateNumberWithSuffix
	local formatNumberWithCommas = StringUtil.formatNumberWithCommas
	local formatTime = StringUtil.formatTime

	
    describe("truncateNumberWithSuffix", function()
		it("should truncate small numbers without suffix", function()
			expect(truncateNumberWithSuffix(1.234)).to.equal("1.2")
		end)

		it("should return whole numbers without suffix", function()
			expect(truncateNumberWithSuffix(123)).to.equal("123")
		end)

		it("should truncate numbers in the thousands with 'K' suffix", function()
			expect(truncateNumberWithSuffix(1234)).to.equal("1.2K")
		end)

		it("should truncate numbers in the hundreds of thousands with 'K' suffix", function()
			expect(truncateNumberWithSuffix(123456)).to.equal("123.4K")
		end)

		it("should respect MaxDecimals when truncating numbers", function()
			expect(truncateNumberWithSuffix(123456, {MaxDecimals = 1})).to.equal("123.4K")
			expect(truncateNumberWithSuffix("123456", {MaxDecimals = 2})).to.equal("123.45K")
			expect(truncateNumberWithSuffix(123456, {MaxDecimals = 3})).to.equal("123.456K")
		end)

		it("should handle large numbers with 'M' and 'B' suffixes", function()
			expect(truncateNumberWithSuffix(123456789)).to.equal("123.4M")
			expect(truncateNumberWithSuffix(1234567890)).to.equal("1.2B")
		end)

		it("should add space between number and suffix if AddSpace is true", function()
			expect(truncateNumberWithSuffix(1234567890, {AddSpace = true})).to.equal("1.2 B")
		end)

		it("should show trailing zeroes if ShowZeroes is true", function()
			expect(truncateNumberWithSuffix(123456, {MaxDecimals = 3, ShowZeroes = true})).to.equal("123.456K")
			expect(truncateNumberWithSuffix(123400, {MaxDecimals = 2, ShowZeroes = true})).to.equal("123.40K")
			expect(truncateNumberWithSuffix(500_000, {ShowZeroes = true})).to.equal("500.0K")
		end)
	end)

	describe("formatNumberWithCommas", function()
		it("should format small numbers without commas", function()
			expect(formatNumberWithCommas("12")).to.equal("12")
		end)

		it("should format numbers in the thousands with commas", function()
			expect(formatNumberWithCommas(1234)).to.equal("1,234")
		end)

		it("should format numbers in the hundreds of thousands with commas", function()
			expect(formatNumberWithCommas(123456)).to.equal("123,456")
		end)

		it("should format numbers in the millions with commas", function()
			expect(formatNumberWithCommas("1234567")).to.equal("1,234,567")
		end)

		it("should format numbers with decimal places and commas", function()
			expect(formatNumberWithCommas(12345.6789)).to.equal("12,345.6789")
		end)
	end)

	describe("formatTime", function()
		it("should format time in seconds to hh:mm:ss", function()
			expect(formatTime(3600, "s", "2h:2m:2s")).to.equal("01:00:00")
		end)

		it("should format time less than an hour to mm:ss", function()
			expect(formatTime(125, "s", "2h:2m:2s")).to.equal("00:02:05")
		end)

		it("should format time with custom format", function()
			expect(formatTime(125, "s", "1h:1m:1s")).to.equal("0:2:5")
			expect(formatTime(125, "s", "h:m:s", {})).to.equal("0:2:5")
		end)

		it("should hide parent zero values if HideParentZeroValues is true", function()
			expect(formatTime(125, "s", "2h:2m:2s", {HideParentZeroValues = true})).to.equal("02:05")
			expect(formatTime(125, "s", "h:m:s:ds", {HideParentZeroValues = true})).to.equal("2:5:0")
		end)

		it("should include trailing zeroes for sub-second values", function()
			expect(formatTime(125, "s", "h:m:s:ds")).to.equal("0:2:5:0")
		end)

		it("should format large number of seconds to h:s", function()
			expect(formatTime(3725, "s", "h:s")).to.equal("1:125")
		end)

		it("should format milliseconds to seconds", function()
			expect(formatTime(1000, "ms", "s")).to.equal("1")
		end)
	end)

end
-- Logan Hunt (Raildex)

local RailUtil = script.Parent.Parent
local TableUtil = require(RailUtil.TblUtil)


return function()
    describe("GreedyMesh2D", function()
        it("should find a single large rectangle in a full grid", function()
            local grid = {
                {true, true, true},
                {true, true, true},
                {true, true, true},
            }

            local result = TableUtil.GreedyMesh2D(grid)

            expect(#result).to.equal(1)
            expect(result[1].Position).to.equal(Vector2.new(1, 1))
            expect(result[1].Size).to.equal(Vector2.new(3, 3))
        end)

        it("should find two separate rectangles", function()
            local grid = {
                {true, true, false, false},
                {true, true, false, false},
                {false, false, true, true},
                {false, false, true, true},
            }

            local result = TableUtil.GreedyMesh2D(grid)

            expect(#result).to.equal(2)

            -- First rectangle (top-left 2x2)
            expect(result[1].Position).to.equal(Vector2.new(1, 1))
            expect(result[1].Size).to.equal(Vector2.new(2, 2))

            -- Second rectangle (bottom-right 2x2)
            expect(result[2].Position).to.equal(Vector2.new(3, 3))
            expect(result[2].Size).to.equal(Vector2.new(2, 2))
        end)

        it("should correctly handle a non-rectangular shape", function()
            local grid = {
                {true, true, false},
                {true, false, false},
                {true, true, true},
            }

            local result = TableUtil.GreedyMesh2D(grid)

            expect(#result).to.be.greaterThanOrEqual(2) -- Should detect at least 2 rectangles
        end)

        it("should return an empty array for an empty grid", function()
            local grid = {
                {false, false},
                {false, false},
            }

            local result = TableUtil.GreedyMesh2D(grid)

            expect(#result).to.equal(0)
        end)

        it("should respect the isValid callback function", function()
            local grid = {
                {1, 2, 0},
                {1, 0, 0},
                {1, 2, 2},
            }

            local isValid = function(value)
                return value > 1 -- Only count values greater than 1
            end

            local result = TableUtil.GreedyMesh2D(grid, isValid)

            expect(#result).to.equal(1)
            expect(result[1].Position).to.equal(Vector2.new(3, 2))
            expect(result[1].Size).to.equal(Vector2.new(2, 2))
        end)
    end)

    -- Add more checks here
end

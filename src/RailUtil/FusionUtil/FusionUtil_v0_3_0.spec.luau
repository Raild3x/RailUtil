-- Logan Hunt (Raildex)
-- Aug 19, 2024

local RailUtil = script.Parent.Parent
local Fusion = require(RailUtil.Parent["Fusion_v0_3_0"])
local FusionUtil = require(RailUtil.FusionUtil)["0.3.0"]

local scoped = Fusion.scoped
local Value = Fusion.Value
local peek = Fusion.peek

return function()
    describe("ensureIsState", function()
        it("should return a state object if data is nil", function()
            local scope = scoped({})
            local result = FusionUtil.ensureIsState(scope, nil, 10)
            expect(peek(result)).to.equal(10)
        end)

        it("should return the same state object if data is already a state object", function()
            local scope = scoped({})
            local originalState = Value(scope, 5)
            local result = FusionUtil.ensureIsState(scope, originalState, 10)
            expect(result).to.equal(originalState)
        end)

        it("should wrap non-state data in a state object", function()
            local scope = scoped({})
            local result = FusionUtil.ensureIsState(scope, 20, 10)
            expect(peek(result)).to.equal(20)
        end)

        it("should warn and return default value if data type does not match", function()
            local scope = scoped({})
            local result = FusionUtil.ensureIsState(scope, "not a number", 10, "number")
            expect(peek(result)).to.equal(10)
        end)
    end)

    describe("addTask", function()
        it("should add a task to the scope", function()
            local scope = scoped({})
            local task = function() end
            FusionUtil.addTask(scope, task)
            expect(#scope).to.equal(1)
        end)

        it("should remove existing task with the same taskId", function()
            local scope = scoped({})
            local task1 = function() end
            local task2 = function() end
            FusionUtil.addTask(scope, task1, nil, "TaskID")
            FusionUtil.addTask(scope, task2, nil, "TaskID")
            expect(#scope).to.equal(1)
            expect(scope[1].Task).to.equal(task2)
        end)
    end)

    describe("removeTask", function()
        it("should remove the task from the scope by taskId", function()
            local scope = scoped({})
            local task = function() end
            FusionUtil.addTask(scope, task, nil, "TaskID")
            FusionUtil.removeTask(scope, "TaskID")
            expect(#scope).to.equal(0)
        end)

        it("should return the removed task", function()
            local scope = scoped({})
            local task = function() end
            FusionUtil.addTask(scope, task, nil, "TaskID")
            local removedTask = FusionUtil.removeTask(scope, "TaskID")
            expect(removedTask).to.equal(task)
        end)
    end)

    describe("getTask", function()
        it("should return the task with the specified taskId", function()
            local scope = scoped({})
            local task = function() end
            FusionUtil.addTask(scope, task, nil, "TaskID")
            local foundTask = FusionUtil.getTask(scope, "TaskID")
            expect(foundTask).to.equal(task)
        end)

        it("should return nil if the taskId does not exist", function()
            local scope = scoped({})
            local foundTask = FusionUtil.getTask(scope, "NonExistentTaskID")
            expect(foundTask).to.equal(nil)
        end)
    end)

    describe("syncValues", function()
        it("should sync the value of one state to another", function()
            local scope = scoped({})
            local stateA = Value(scope, 123)
            local stateB = Value(scope, 0)
            FusionUtil.syncValues(scope, stateA, stateB)
            expect(peek(stateB)).to.equal(123)
            stateA:set(456)
            expect(peek(stateB)).to.equal(456)
        end)
    end)

    describe("formatAssetId", function()
        it("should format a string asset id correctly", function()
            local scope = scoped({})
            local formatted = FusionUtil.formatAssetId(scope, "rbxassetid://1234567890")
            expect(peek(formatted)).to.equal("rbxassetid://1234567890")
        end)

        it("should format a numeric asset id correctly", function()
            local scope = scoped({})
            local formatted = FusionUtil.formatAssetId(scope, 1234567890)
            expect(peek(formatted)).to.equal("rbxassetid://1234567890")
        end)

        it("should use the default value if the id is nil", function()
            local scope = scoped({})
            local formatted = FusionUtil.formatAssetId(scope, nil, 1234567890)
            expect(peek(formatted)).to.equal("rbxassetid://1234567890")
        end)
    end)

    describe("ratio", function()
        it("should compute the ratio of two states", function()
            local scope = scoped({})
            local numerator = Value(scope, 100)
            local denominator = Value(scope, 200)
            local ratio = FusionUtil.ratio(scope, numerator, denominator)
            expect(peek(ratio)).to.equal(0.5)
        end)
    end)

    describe("lerpNumber", function()
        it("should lerp between two number states", function()
            local scope = scoped({})
            local n1 = Value(scope, 10)
            local n2 = Value(scope, 20)
            local alpha = Value(scope, 0.5)
            local result = FusionUtil.lerpNumber(scope, n1, n2, alpha)
            expect(peek(result)).to.equal(15)
        end)
    end)

    describe("eq", function()
        it("should return true if two states are equal", function()
            local scope = scoped({})
            local stateA = Value(scope, 10)
            local stateB = Value(scope, 10)
            local isEqual = FusionUtil.eq(scope, stateA, stateB)
            expect(peek(isEqual)).to.equal(true)
        end)

        it("should return false if two states are not equal", function()
            local scope = scoped({})
            local stateA = Value(scope, 10)
            local stateB = Value(scope, 20)
            local isEqual = FusionUtil.eq(scope, stateA, stateB)
            expect(peek(isEqual)).to.equal(false)
        end)
    end)

    describe("observeState", function()
        it("should observe a state and call the callback on change", function()
            local scope = scoped({})
            local state = Value(scope, 10)
            local callbackCalled = false
            local callbackValue
            FusionUtil.observeState(scope, state, function(value)
                callbackCalled = true
                callbackValue = value
            end)
            expect(callbackCalled).to.equal(true)
            expect(callbackValue).to.equal(10)

            state:set(20)
            expect(callbackValue).to.equal(20)
        end)
    end)

    -- Add more checks here
end

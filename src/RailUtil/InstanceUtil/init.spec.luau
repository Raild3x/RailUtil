-- Logan Hunt [Raildex]
local TweenService = game:GetService("TweenService")

--// Requires //--
local InstanceUtil = require(script.Parent)
local Promise = require(script.Parent.Parent.Parent.Promise)

print(debug.traceback())

local TestObjects = InstanceUtil.findFirstChildThatMatches(workspace, "InstanceUtil/TestObjects") or Instance.new("Folder")
TestObjects.Name = "InstanceUtil/TestObjects - "..os.clock()
TestObjects.Parent = workspace

local debugPrint = function(...)
    --print("[InstanceUtil]", ...)
end

return function()

    afterAll(function()
        TestObjects:Destroy()
        debugPrint("Finished Tests!")
    end)

    local function create(class: string, name: string?, parent: Instance?): Instance
        local obj = Instance.new(class)
        obj.Name = name
        if class == "Part" then
            obj.Anchored = true
        end
        obj.Parent = parent or TestObjects
        return obj
    end

    describe("promiseChild", function()
        debugPrint("Testing InstanceUtil.promiseChild . . .")

        local parent
    
        beforeEach(function()
            parent = create("Folder", "TestParent")
        end)
    
        afterEach(function()
            parent:Destroy()
        end)
    
        it("should resolve when the child is found", function()
            local childName = "Child"
            local child = create("Folder", childName, parent)
    
            local success, result = InstanceUtil.promiseChild(parent, childName, 10):await()
    
            expect(success).to.equal(true)
            expect(result).to.equal(child)
        end)
    
        it("should reject when the timeout is reached", function()
            local timeout = 1
            local childName = "NonExistentChild"
    
            local success, result = InstanceUtil.promiseChild(parent, childName, timeout):await()
    
            expect(success).to.equal(false)
            expect(result:find("Timed out after")).to.be.ok()
        end)
    end)
    
    describe("findFirstChildFromPredicate", function()
        debugPrint("Testing InstanceUtil.findFirstChildFromPredicate . . .")
        local parent
    
        beforeEach(function()
            parent = create("Folder", "TestParent")
        end)
    
        afterEach(function()
            parent:Destroy()
        end)
    
        it("should return the first child matching the predicate", function()
            local targetChild = create("Part", "Target", parent)
    
            local result = InstanceUtil.findFirstChildFromPredicate(parent, function(child)
                return child.Name == "Target"
            end)
    
            expect(result).to.equal(targetChild)
        end)
    
        it("should return nil if no child matches the predicate", function()
            local result = InstanceUtil.findFirstChildFromPredicate(parent, function(child)
                return child.Name == "NonExistent"
            end)
    
            expect(result).to.equal(nil)
        end)
    end)
    
    describe("findFirstChildThatMatches", function()
        debugPrint("Testing InstanceUtil.findFirstChildThatMatches . . .")
        local parent
    
        beforeEach(function()
            parent = create("Folder", "TestParent")
        end)
    
        afterEach(function()
            parent:Destroy()
        end)
    
        it("should return the first child whose name matches the pattern", function()
            local targetChild = create("Part", "TargetPart", parent)
    
            local result = InstanceUtil.findFirstChildThatMatches(parent, "TargetPart")
    
            expect(result).to.equal(targetChild)
        end)
    
        it("should return nil if no child name matches the pattern", function()
            local result = InstanceUtil.findFirstChildThatMatches(parent, "NonExistent")
    
            expect(result).to.equal(nil)
        end)
    end)
    
    describe("findFirstChildOfAncestor", function()
        debugPrint("Testing InstanceUtil.findFirstChildOfAncestor . . .")
        local parent, child, descendant
    
        beforeEach(function()
            parent = create("Folder", "ParentFolder")
            child = create("Folder", "ChildFolder", parent)
            descendant = create("Part", "DescendantPart", child)
        end)
    
        afterEach(function()
            parent:Destroy()
        end)
    
        it("should find the correct ancestor of the descendant", function()
            local result = InstanceUtil.findFirstChildOfAncestor(descendant, parent)
    
            expect(result).to.equal(child)
        end)
    
        it("should return nil if the descendant is not under the ancestor", function()
            local anotherParent = create("Folder", "AnotherParentFolder")
            local result = InstanceUtil.findFirstChildOfAncestor(descendant, anotherParent)
    
            expect(result).to.equal(nil)

            anotherParent:Destroy()
        end)
    end)
    
    describe("getDescendantsWhichAre", function()
        debugPrint("Testing InstanceUtil.getDescendantsWhichAre . . .")
        local parent
    
        beforeEach(function()
            parent = create("Folder", "TestParent")
            create("Part", "Part1", parent)
            create("Part", "Part2", parent)
            create("Model", "Model1", parent)
        end)
    
        afterEach(function()
            parent:Destroy()
        end)
    
        it("should return all descendants of the specified class", function()
            local parts = InstanceUtil.getDescendantsWhichAre(parent, "Part")
    
            expect(#parts).to.equal(2)
            expect(parts[1].ClassName).to.equal("Part")
            expect(parts[2].ClassName).to.equal("Part")
        end)
    
        it("should handle multiple classes", function()
            local descendants = InstanceUtil.getDescendantsWhichAre(parent, {"Part", "Model"})
    
            expect(#descendants).to.equal(3)
        end)
    end)
    
    describe("cloneChildren", function()
        debugPrint("Testing InstanceUtil.cloneChildren . . .")
        local parent, newParent
    
        beforeEach(function()
            parent = create("Folder", "SourceFolder")
            newParent = create("Folder", "TargetFolder")
    
            create("Part", "Part1", parent)
            create("Part", "Part2", parent)
        end)
    
        afterEach(function()
            parent:Destroy()
            newParent:Destroy()
        end)
    
        it("should clone all children", function()
            local clonedChildren = InstanceUtil.cloneChildren(parent, newParent)
    
            expect(#clonedChildren).to.equal(2)
            expect(clonedChildren[1].Parent).to.equal(newParent)
            expect(clonedChildren[2].Parent).to.equal(newParent)
        end)
    
        it("should clone only children that match the predicate", function()
            local clonedChildren = InstanceUtil.cloneChildren(parent, newParent, function(child)
                return child.Name == "Part1"
            end)
    
            expect(#clonedChildren).to.equal(1)
            expect(clonedChildren[1].Name).to.equal("Part1")
            expect(clonedChildren[1].Parent).to.equal(newParent)
        end)
    end)
    
    describe("safeDestroy", function()
        debugPrint("Testing InstanceUtil.safeDestroy . . .")
        local instance
    
        beforeEach(function()
            instance = create("Part", "PartToDestroy")
        end)
    
        it("should successfully destroy an instance", function()
            local success, err = InstanceUtil.safeDestroy(instance)
    
            expect(success).to.equal(true)
            expect(err).to.equal(nil)
            expect(instance.Parent).to.equal(nil)
        end)

    end)

    -- Test case for weld
    describe("weld", function()
        debugPrint("Testing InstanceUtil.weld . . .")
        local part1
        local part2

        beforeEach(function()
            part1 = create("Part", "Part1", workspace)
            part2 = create("Part", "Part2", workspace)
        end)

        afterEach(function()
            InstanceUtil.safeDestroy(part1)
            InstanceUtil.safeDestroy(part2)
        end)

        it("should create a WeldConstraint between two parts", function()
            local weld = InstanceUtil.weld(part1, part2)
            expect(weld:IsA("WeldConstraint")).to.equal(true)
            expect(weld.Part0).to.equal(part1)
            expect(weld.Part1).to.equal(part2)
            expect(weld.Parent).to.equal(part1)
        end)
    end)

    -- Test case for weldAssembly
    describe("weldAssembly", function()
        debugPrint("Testing InstanceUtil.weldAssembly . . .")
        local model
        local primaryPart

        beforeEach(function()
            model = create("Model", "TestModel", workspace)
            primaryPart = create("Part", "PrimaryPart", model)
            model.PrimaryPart = primaryPart

            for i = 1, 3 do
                create("Part", "Part" .. i, model)
            end
        end)

        afterEach(function()
            InstanceUtil.safeDestroy(model)
        end)

        it("should weld all parts of a model to the PrimaryPart", function()
            local welds = InstanceUtil.weldAssembly(model)
            expect(#welds).to.equal(3)
            for _, weld in ipairs(welds) do
                expect(weld.Part0).to.equal(primaryPart)
                expect(weld.Parent).to.equal(primaryPart)
            end
        end)
    end)

    -- Test case for isClass
    describe("isClass", function()
        debugPrint("Testing InstanceUtil.isClass . . .")
        local part

        beforeEach(function()
            part = create("Part", "Part", workspace)
        end)

        afterEach(function()
            InstanceUtil.safeDestroy(part)
        end)

        it("should return true for a class that matches the instance", function()
            local result = InstanceUtil.isClass(part, "Part")
            expect(result).to.equal(true)
        end)

        it("should return true for a class that matches one of multiple classes", function()
            local result = InstanceUtil.isClass(part, {"BasePart", "Part"})
            expect(result).to.equal(true)
        end)

        it("should return false for a class that does not match", function()
            local result = InstanceUtil.isClass(part, "Model")
            expect(result).to.equal(false)
        end)
    end)

    -- Test case for fetchModule
    -- This Test Case is bugged bc the created module doesnt properly return a value sometimes
    -- describe("fetchModule", function()
    --     debugPrint("Testing InstanceUtil.fetchModule . . .")
    --     local parent

    --     beforeEach(function()
    --         parent = create("Folder", "Parent", workspace)
    --     end)

    --     afterEach(function()
    --         InstanceUtil.safeDestroy(parent)
    --     end)

    --     it("should return the module script if found", function()
    --         local moduleScript = Instance.new("ModuleScript")
    --         moduleScript.Name = "TestModule"
    --         moduleScript.Parent = parent

    --         local result = InstanceUtil.fetchModule(parent, "TestModule")
    --         expect(result).to.equal(nil) -- Assuming the module script returns a table
    --     end)

    --     it("should return the default value if the module script is not found", function()
    --         local defaultValue = {}
    --         local result = InstanceUtil.fetchModule(parent, "NonExistentModule", defaultValue)
    --         expect(result).to.equal(defaultValue)
    --     end)

    --     it("should throw an error if the module script is not found and no default value is provided", function()
    --         expect(function()
    --             InstanceUtil.fetchModule(parent, "NonExistentModule")
    --         end).to.throw()
    --     end)
    -- end)

    -- Test case for hasProperty
    describe("hasProperty", function()
        debugPrint("Testing InstanceUtil.hasProperty . . .")
        local part

        beforeEach(function()
            part = create("Part", "Part", workspace)
            part.Size = Vector3.new(4, 4, 4)
        end)

        afterEach(function()
            InstanceUtil.safeDestroy(part)
        end)

        it("should return true and the value if the property exists", function()
            local hasProperty, value = InstanceUtil.hasProperty(part, "Size")
            expect(hasProperty).to.equal(true)
            expect(value).to.equal(part.Size)
        end)

        it("should return false if the property does not exist", function()
            local hasProperty, _ = InstanceUtil.hasProperty(part, "NonExistentProperty")
            expect(hasProperty).to.equal(false)
        end)
    end)

    -- Test case for playTween -- TODO: Review these test cases
    describe("playTween", function()
        debugPrint("Testing InstanceUtil.playTween . . .")
        local part
        local tweenInfo
        local goals
        local tween
        local prom

        beforeEach(function()
            part = create("Part", "Part", workspace)
            tweenInfo = TweenInfo.new(1)
            goals = { Size = Vector3.new(10, 10, 10) }
            tween = TweenService:Create(part, tweenInfo, goals)
        end)

        afterEach(function()
            InstanceUtil.safeDestroy(part)
        end)

        it("should return a promise that resolves when the tween has finished", function()
            debugPrint("[Testing] InstanceUtil.playTween should return a promise that resolves when the tween has finished")
            prom = InstanceUtil.playTween(tween)
            expect(Promise.is(prom)).to.equal(true)
            prom:andThen(function(status)
                expect(status).to.equal(Enum.PlaybackState.Completed)
            end):await()
        end)

        it("should handle tween cancellation", function()
            debugPrint("[Testing] InstanceUtil.playTween should handle tween cancellation")
            prom = InstanceUtil.playTween(tween)
            tween:Cancel() -- Cancelling the tween
            prom:andThen(function(status)
                expect(status).to.equal(Enum.PlaybackState.Cancelled)
            end):await()
        end)

        it("should handle multiple tweens being created and played", function()
            debugPrint("[Testing] InstanceUtil.playTween should handle multiple tweens being created and played")
            local goals2 = { Position = Vector3.new(10, 10, 10) }
            local tween2 = TweenService:Create(part, tweenInfo, goals2)

            local prom1 = InstanceUtil.playTween(tween)
            local prom2 = InstanceUtil.playTween(tween2)


            prom1:andThen(function(status)
                expect(status).to.equal(Enum.PlaybackState.Completed)
            end):await()
            prom2:andThen(function(status)
                expect(status).to.equal(Enum.PlaybackState.Completed)
            end):await()
        end)

        it("should correctly resolve when tween completes normally", function()
            debugPrint("[Testing] InstanceUtil.playTween should correctly resolve when tween completes normally")
            -- Adjust tweenInfo for a shorter duration to test completion
            tweenInfo = TweenInfo.new(0.1)
            tween = TweenService:Create(part, tweenInfo, goals)
            prom = InstanceUtil.playTween(tween)

            wait(0.2) -- Ensure there's enough time for the tween to complete

            prom:andThen(function(status)
                expect(status).to.equal(Enum.PlaybackState.Completed)
            end):await()
        end)
    end)

    -- Test case for playTracksAsync
    -- describe("playTracksAsync", function()
    --     debugPrint("Testing InstanceUtil.playTracksAsync . . .")
    --     local animationTrack
    --     local animInfo

    --     beforeEach(function()
    --         animationTrack = Instance.new("AnimationTrack")
    --         animInfo = {
    --             FadeInTime = 0.5,
    --             Weight = 1,
    --             Speed = 1,
    --             FadeOutTime = 0.5,
    --         }
    --     end)

    --     it("should return a promise that resolves when all tracks have stopped playing", function()
    --         local prom = InstanceUtil.playTracksAsync(animationTrack, animInfo)
    --         expect(prom).to.be.a("Promise")
    --         pcall(function()
    --             prom:andThen(function()
    --                 -- Check if animation has finished
    --                 expect(animationTrack.IsPlaying).to.equal(false)
    --             end)
    --         end)
    --     end)
    -- end)


end

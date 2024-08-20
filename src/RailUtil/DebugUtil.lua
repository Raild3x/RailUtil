--!strict
-- Logan Hunt [Raildex]
-- Nov 22, 2022
--[=[
    @class DebugUtil

    DebugUtil is a collection of functions that help with debugging.
]=]

local DebugUtil = {}

-- Function to measure the average runtime of a given function
function DebugUtil.measureAvgRuntime<T...>(func: (T...) -> (...any), numRuns: number?, ...: T...): number
    local NumRuns = numRuns or 1000 -- Default to 100 runs if not specified
    local totalTime = 0

    for i = 1, NumRuns do
        local startTime = os.clock()
        func(...)  -- Call the function
        local endTime = os.clock()
        totalTime += (endTime - startTime)
    end

    return totalTime / NumRuns
end

return table.freeze(DebugUtil)

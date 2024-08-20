return function(Target)
    local t = task.spawn(function()
        require(script.Parent.TestEZ).TestBootstrap:run({
            game.ServerScriptService.src.RailUtil
        })
    end)
    
    return function()
        task.cancel(t)
    end
end

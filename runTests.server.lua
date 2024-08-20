print("Running tests for server")
require(game.ReplicatedStorage.TestEZ).TestBootstrap:run({
	game.ServerScriptService.src.RailUtil
})
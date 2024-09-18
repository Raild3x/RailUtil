"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[837],{18001:e=>{e.exports=JSON.parse('{"functions":[{"name":"getCharactersFolder","desc":"Returns the characters folder, creating it if it doesn\'t exist.\\nThis folder is used to store all characters in the game.\\nThis folder is created on the server and waited for on the client.","params":[],"returns":[{"desc":"The characters folder","lua_type":"Folder"}],"function_type":"static","yields":true,"source":{"line":100,"path":"src/RailUtil/PlayerUtil.luau"}},{"name":"promiseCharacter","desc":"Returns a promise that resolves with the character of the specified player once\\ntheir character is within the proper folder.","params":[{"name":"plr","desc":"The player to get the character of","lua_type":"Player"},{"name":"timeOut?","desc":"The amount of time to wait before rejecting the promise","lua_type":"number?"}],"returns":[{"desc":"A promise that resolves when the character is retrieved","lua_type":"Promise<Character>"}],"function_type":"static","source":{"line":132,"path":"src/RailUtil/PlayerUtil.luau"}},{"name":"getPlayerFromCharacterDescendant","desc":"Returns the player that owns the specified descendant of a character.\\nReturns nil if the descendant is not a descendant of a character.","params":[{"name":"descendant","desc":"The descendant to get the player of","lua_type":"Instance"}],"returns":[{"desc":"The player that owns the character","lua_type":"Player?"}],"function_type":"static","source":{"line":172,"path":"src/RailUtil/PlayerUtil.luau"}},{"name":"getAllLoadedCharacters","desc":"","params":[],"returns":[{"desc":"A table of all the fully loaded characters","lua_type":"{Character}"}],"function_type":"static","source":{"line":184,"path":"src/RailUtil/PlayerUtil.luau"}},{"name":"forEachCharacter","desc":"Takes a function that will be run for every player in the game as well as any future players\\nuntil the returned connection is disconnected.","params":[{"name":"func","desc":"A passed function to be executed for each character, it is given the character as an argument. Also receives a Janitor object that can be used to clean up any connections made.","lua_type":"(char: Character, janitor: Janitor) -> ()"},{"name":"player","desc":"An optional player to only run the function for their character.","lua_type":"Player?"}],"returns":[{"desc":"A connection that can be Disconnected or Destroyed to stop method\'s activities.","lua_type":"Connection"}],"function_type":"static","source":{"line":196,"path":"src/RailUtil/PlayerUtil.luau"}},{"name":"forEachPlayer","desc":"Takes a function that will be run for every player in the game as well as any future players\\nuntil the returned connection is disconnected.","params":[{"name":"func","desc":"A passed function to be executed for each player, it is given the player as an argument.","lua_type":"(player: Player, janitor: Janitor) -> ()"}],"returns":[{"desc":"A connection that can be Disconnected or Destroyed to stop method\'s activities.","lua_type":"Connection"}],"function_type":"static","source":{"line":274,"path":"src/RailUtil/PlayerUtil.luau"}},{"name":"onPlayerRemoving","desc":"Takes a function that will be run for a specified player when they leave.","params":[{"name":"player","desc":"","lua_type":"Player"},{"name":"fn","desc":"The function to be run when the player disconnects.","lua_type":"(T...) -> ()"},{"name":"...","desc":"","lua_type":"T..."}],"returns":[{"desc":"A connection that can be Disconnected or Destroyed to stop method\'s activities.","lua_type":"Connection"}],"function_type":"static","source":{"line":309,"path":"src/RailUtil/PlayerUtil.luau"}}],"properties":[],"types":[],"name":"PlayerUtil","desc":"This module contains utility methods that handle players joining and leaving.\\nAs well as utility functions for character access.\\n\\n:::caution Characters Folder\\nThe module works best when a folder named \\"Characters\\" exists within workspace.\\nIdeally you create this folder within your project JSON file so that it exists ahead of time.\\n:::","source":{"line":15,"path":"src/RailUtil/PlayerUtil.luau"}}')}}]);
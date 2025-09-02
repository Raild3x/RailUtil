--!strict
-- Authors: Logan Hunt [Raildex], Marcus Mendonça [Mophyr];
-- Feb 2, 2023
--[=[
	@class InstanceUtil

	A collection of utility functions for working with Instances.
]=]

--// Services //--
local TweenService = game:GetService("TweenService")

--// Requires //--
local RailUtil = script.Parent
local TableUtil = require(RailUtil.TblUtil)
local Promise = require(RailUtil.Parent.Promise)
local Types = require(RailUtil.RailUtilTypes)

--// Types //--
type Promise<T> = Types.Promise

--[=[
	@within InstanceUtil
	@interface AnimPlayInfo 
	.FadeInTime number?
	.Weight number?,
	.Speed number?,
	.FadeOutTime number?,
	
	A table of info for generating tweens for playing animations.
]=]
type AnimPlayInfo = {
	FadeInTime: number?,
	Weight: number?,
	Speed: number?,
	FadeOutTime: number?,
}

--------------------------------------------------------------------------------

local InstanceUtil = {}

local PromiseWaitForChild = Promise.promisify(workspace.WaitForChild)
--[=[
	Promisifys the WaitForChild method on an Instance and adds in more robust error handling.
	@param parent       -- The Instance to take the children of
	@param childName    -- The Instance name to look for
	@param timeout      -- The number of seconds to wait before timing out
	@return Promise     -- A Promise that resolves when the child is found or rejects if the timeout is reached.
	```lua
	InstanceUtil.promiseChild(workspace, "ModelA", 10):andThen(function(model)
		print("Found ModelA:", model)
	end)
	```
]=]
function InstanceUtil.promiseChild(parent: Instance, childName: string, timeout: number?): Promise<Instance>
	local stack = debug.traceback()
	local prom = PromiseWaitForChild(parent, childName, math.huge)
	if timeout then
		prom = prom:timeout(
			timeout,
			("Timed out after %s seconds waiting for child %s in parent %s\n%s"):format(
				timeout :: any,
				childName,
				parent:GetFullName(),
				stack
			)
		)
	end
	return prom
end

--[=[
	Searches the parent for the first child which evaluates the given predicate to be true.
	@param parent			-- The Instance to search the children of.
	@param predicate		-- The predicate which determines whether the child was found.
	@param recurse boolean? -- Whether or not to search the parent's descendants instead of just its children.
	@return Instance?       -- The first child whose name matches the given string.
	```lua
	local part = InstanceUtil.findFirstChildFromPredicate(workspace, function(child)
		return child:IsA("Part")
	end)
	```
]=]
function InstanceUtil.findFirstChildFromPredicate(
	parent: Instance,
	predicate: (child: Instance) -> boolean,
	recurse: boolean?
): Instance?
	local children: {Instance} = if recurse then parent:GetDescendants() else parent:GetChildren()
	for i = 1, #children do
		local child = children[i]
		if predicate(child) then
			return child
		end
	end
	return nil
end

--[=[
	Searches the parent for the first child whose name matches the given string.
	@param parent           -- The Instance to search the children of.
	@param matchString      -- The string to match the child's name to. Uses Lua's string.match function. Can take patterns.
	@param recurse			-- Whether or not to search the parent's descendants instead of just its children.
	@return Instance        -- The first child whose name matches the given string.
	```lua
	local model = InstanceUtil.findFirstChildThatMatches(workspace, "^Part", true)
	```
]=]
function InstanceUtil.findFirstChildThatMatches(parent: Instance, matchString: string, recurse: boolean?): Instance?
	assert(parent and typeof(parent) == "Instance", "Parent argument of findFirstChildThatMatches must be an Instance.")

	return InstanceUtil.findFirstChildFromPredicate(parent, function(child)
		return child.Name:match(matchString) ~= nil
	end, recurse)
end

--[=[
	Finds the first child of the given ancestor that is an ancestor of the given descendant.
	This is useful when you have a bunch of models in a folder and you have a reference to a part in one of these models.
	It allows you to quickly find which of those immediate children models the part is in.

	@param descendant -- The Instance to find the ancestor of.
	@param ancestor   -- The Instance to find the descendant's ancestor of.
	@return Instance  -- The first child of the ancestor that is an ancestor of the descendant.
	```lua
	local character = InstanceUtil.findFirstChildOfAncestor(someDescendant, workspace.Characters)
	if character then
		print("Found character:", character)
	end
	```
]=]
function InstanceUtil.findFirstChildOfAncestor(descendant: Instance, ancestor: Instance): Instance?
	assert(
		descendant and typeof(descendant) == "Instance",
		"Descendant argument of getFirstChildOfAncestor must be an Instance."
	)
	assert(
		ancestor and typeof(ancestor) == "Instance",
		"Ancestor argument of getFirstChildOfAncestor must be an Instance."
	)
	--assert(descendant:IsDescendantOf(ancestor), "Descendant must be a descendant of Ancestor.");
	if not descendant:IsDescendantOf(ancestor) then
		--warn(descendant,"is not a descendant of",ancestor)
		--warn(debug.traceback())
		return nil
	end
	local current = descendant
	while current.Parent ~= ancestor do
		current = (current :: any).Parent
	end
	return current
end

--[=[
	Iterates through Parent descendants and returns a table which only contains descendants of
	passed ClassName.
	@param Parent 		-- Instance to perform the search on.
	@param ClassName	-- The class name or names the descendant must match or inherit.
	@return {Instance?} -- Table with valid descendants of passed ClassName.
	```lua
	local partsAndTextures = InstanceUtil.getDescendantsWhichAre(workspace, {"Part", "Texture"})
	```
]=]
function InstanceUtil.getDescendantsWhichAre(Parent: Instance, ClassName: string | { string }): { Instance }
	local ClassNames: {string} = if typeof(ClassName) == "table" then ClassName else { ClassName }
	local validDescendants = {}
	for _, desc in Parent:GetDescendants() do
		for _, className in ClassNames do
			if desc:IsA(className) then
				table.insert(validDescendants, desc)
				break
			end
		end
	end
	return validDescendants
end

--[=[
	Waits for the first child which evaluates the given predicate to be true.
	@param parent				-- The Instance to search the children of.
	@param predicate            -- The predicate which determines whether the child was found.
	@param timeout       		-- The maximum amount of time to wait for the child to be added. Defaults to 10 seconds.
	@param recurse			    -- Whether or not to search the parent's descendants instead of just its children.
	@return Promise<Instance>   -- A Promise resolving with the first child who satisfies the predicate.
	```lua
	InstanceUtil.waitForChildFromPredicate(workspace, function(child)
		return child:IsA("Part") and child.Name == "MyPart"
	end):andThen(function(part)
		print("Found part:", part)
	end)
	```
]=]
function InstanceUtil.waitForChildFromPredicate(
	parent: Instance,
	predicate: (child: Instance) -> boolean,
	timeout: number?,
	recurse: boolean?
): Promise<Instance>
	assert(parent and typeof(parent) == "Instance", "Parent argument of waitForChildFromPredicate must be an Instance.")
	assert(
		predicate and typeof(predicate) == "function",
		"Predicate argument of waitForChildFromPredicate must be a function."
	)

	local child = InstanceUtil.findFirstChildFromPredicate(parent, predicate, recurse)
	if child then
		return Promise.resolve(child)
	end

	local event = if recurse then parent.DescendantAdded else parent.ChildAdded
	local eventTimeout = timeout or 10
	return Promise.fromEvent(event, predicate):timeout(
		eventTimeout,
		`[waitForChildFromPredicate] {eventTimeout} second timeout reached while waiting for child!`
	)
end
InstanceUtil.promiseChildFromPredicate = InstanceUtil.waitForChildFromPredicate

--[=[
	Waits for a child of the given class in the given ancestor to be added.
	@param ancestor				-- The Instance to search the children of.
	@param className			-- The class of the child to wait for.
	@param timeout?				-- The maximum amount of time to wait for the child to be added. Defaults to 10 seconds.
	@return Promise<Instance>	-- A promise that resolves with the child when it is added.
	```lua
	InstanceUtil.waitForChildWhichIsA(workspace, "Part"):andThen(function(part)
		print("Found part:", part)
	end)
	```
]=]
function InstanceUtil.waitForChildWhichIsA(ancestor: Instance, className: string, timeout: number?): Promise<Instance>
	assert(
		ancestor and typeof(ancestor) == "Instance",
		"Ancestor argument of waitForChildWhichIsA must be an Instance."
	)

	local object = ancestor:FindFirstChildWhichIsA(className)
	if object then
		return Promise.resolve(object)
	end

	local eventTimeout = timeout or 10
	return Promise.fromEvent(ancestor.ChildAdded, function(child)
		return child:IsA(className)
	end):timeout(
		eventTimeout,
		`[waitForChildWhichIsA] {eventTimeout} second timeout reached while waiting for: "{className}"`
	)
end
InstanceUtil.promiseChildWhichIsA = InstanceUtil.waitForChildWhichIsA

--[=[
	Waits for the first child whose name matches the given string.
	@param ancestor				-- The Instance to search the children of.
	@param matchString          -- The string to match the child's name to. Uses Lua's string.match function. Can take patterns.
	@param timeout              -- The maximum amount of time to wait for the child to be added. Defaults ot 10 seconds.
	@param recurse              -- Whether or not to search the parent's descendants instead of just its children.
	@return Promise<Instance>   -- The first child whose name matches the given string.
	```lua
	InstanceUtil.waitForChildThatMatches(workspace, "^Part"):andThen(function(part)
		print("Found part:", part)
	end)
	```
]=]
function InstanceUtil.waitForChildThatMatches(
	ancestor: Instance,
	matchString: string,
	timeout: number?,
	recurse: boolean?
): Promise<Instance>
	assert(
		ancestor and typeof(ancestor) == "Instance",
		"Ancestor argument of waitForChildThatMatches must be an Instance."
	)

	return InstanceUtil.waitForChildFromPredicate(ancestor, function(child)
		return child.Name:match(matchString) ~= nil
	end, timeout, recurse)
end
InstanceUtil.promiseChildThatMatches = InstanceUtil.waitForChildThatMatches

--[=[
	Ensures that the given parent has a child with the given name.
	If not then it uses the given template to create a new child.
	@param parent		-- The Instance to check.
	@param template     -- The Instance to use as a template.
	@param name         -- The name of the child to find. Uses the template's name if not given.
	@return Instance    -- The existing or new child.
	```lua
	local template = Instance.new("Part")
	template.BrickColor = BrickColor.new("Bright red")

	local myPart = InstanceUtil.ensureInstance(workspace, template, "MyPart")
	```
]=]
function InstanceUtil.ensureInstance(parent: Instance, template: Instance, name: string?): Instance
	local instance = parent:FindFirstChild(name or template.Name)
	if not instance then
		local t = template:Clone()
		t.Name = name or template.Name
		t.Parent = parent
		instance = t
	end
	return instance :: Instance
end

--[=[
	Attempts to destroy a named descendant of the given parent.
	@param parent           -- The Instance to search the children of.
	@param descendantName   -- The name of the descendant to destroy.
	@param recurse          -- Whether or not to search the parent's descendants instead of just its children.
	```lua
	InstanceUtil.destroyFirstChild(workspace, "MyPart")
	```
]=]
function InstanceUtil.destroyFirstChild(parent: Instance, descendantName: string, recurse: boolean?)
	local descendant = parent:FindFirstChild(descendantName, recurse)
	if descendant then
		descendant:Destroy()
	end
end

--[=[
	Attempts to destroy the given instance.
	@param instance     -- The Instance to destroy.
	@return boolean     -- Whether or not the instance was destroyed. False is the instance was already destroyed.
	@return string      -- The error message if the instance could not be destroyed.
	```lua
	local success, err = InstanceUtil.safeDestroy(myPart)
	```
]=]
function InstanceUtil.safeDestroy(instance: Instance): (boolean, string)
	local success, err = pcall(function()
		instance:Destroy()
	end)
	return success, err
end

--[=[
	Creates a WeldConstraint between two parts.
	@param part1            -- The first part to weld.
	@param part2            -- The second part to weld.
	@return WeldConstraint  -- The WeldConstraint created.
	```lua
	local weld = InstanceUtil.weld(part1, part2)
	```
]=]
function InstanceUtil.weld(part1: BasePart, part2: BasePart): WeldConstraint
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part1
	weld.Part1 = part2
	weld.Parent = part1
	return weld
end

--[=[
	Weld each individual part to the Model [Model] .PrimaryPart;
	@param model		-- The Model to weld the parts of.
	@param primaryPart  -- The Part to weld the parts to. Defaults to [Model].PrimaryPart
	@return {WeldConstraint} -- The WeldConstraints created.
	```lua
	local welds = InstanceUtil.weldAssembly(model, model:FindFirstChild("Core"))
	```
]=]
function InstanceUtil.weldAssembly(model: Model, primaryPart: BasePart?): { WeldConstraint }
	local welds = {}
	local PrimaryPart: BasePart? = primaryPart or model.PrimaryPart
	assert(PrimaryPart, "Model must have a PrimaryPart to weld to.")
	for _, Descendant in pairs(model:GetDescendants()) do
		if Descendant:IsA("BasePart") and Descendant ~= PrimaryPart then
			table.insert(welds, InstanceUtil.weld(PrimaryPart, Descendant))
		end
	end
	return welds
end

--[=[
	Gets the CFrame of the given `partAttachment`'s parent needed to align with the `targetAttachment`.
	This is useful for aligning two parts such that their attachments are equivalent in CFrame.
	:::info
	This is effectively the same as using a RigidConstraint with the attachments if the parent part is unanchored.
	:::
	```lua
	local partAttachment = part:FindFirstChild("Attachment")
	local targetAttachment = target:FindFirstChild("Attachment")
	local cframe = InstanceUtil.getAttachmentsAlignedCFrame(partAttachment, targetAttachment)
	part.CFrame = cframe
	```
]=]
function InstanceUtil.getAttachmentsAlignedCFrame(partAttachment: Attachment, targetAttachment: Attachment): CFrame
    assert(partAttachment:IsA("Attachment") or not targetAttachment:IsA("Attachment"), "Both inputs must be attachments")
    return targetAttachment.WorldCFrame * partAttachment.CFrame:Inverse()
end

--[=[
	Gets the distance from the camera to the model that would fit the model in the viewport frame.
	This method is not finished and may not return perfect values.
	@param model        -- The Model to get the distance for.
	@param vpf          -- The ViewportFrame to fit the model into.
	@param camera       -- The Camera to use. Defaults to the ViewportFrame's CurrentCamera.
	@return number      -- The distance from the model the camera should be.
	```lua
	local distance = InstanceUtil.getModelFitDistance(model, viewportFrame)
	```
]=]
function InstanceUtil.getModelFitDistance(model: Model | BasePart, vpf: ViewportFrame, camera: Camera?): number
    local _, modelSize
	if model:IsA("Model") then
		_, modelSize = model:GetBoundingBox()
	else
		modelSize = model.Size
	end
	local vpfSize = vpf.AbsoluteSize
	camera = camera or vpf.CurrentCamera
	assert(camera, "ViewportFrame must have a CurrentCamera to get the fit distance.")

	-- clamped b/c we only want to scale the xfov2 if width < height
	-- otherwise if width > height then xfov2 == yfov2
	local wh = math.min(1, vpfSize.X / vpfSize.Y)

	local yfov2 = math.rad(camera.FieldOfView / 2)
	local xfov2 = math.atan(math.tan(yfov2) * wh)
	local radius = modelSize.Magnitude / 2

	return radius / math.sin(xfov2)
end

--[=[
	Takes an Instance and Clones all of its children into a new Instance.
	@param parent		-- The Instance to take the children of
	@param newParent    -- The Instance to parent the cloned children to
	@param predicate    -- A function to filter which children it should clone
	@return {Instance}  -- The cloned children
	```lua
	local modelA = workspace.ModelA
	local modelB = workspace.ModelB

	local newChildren = InstanceUtil.cloneChildren(modelA, modelB, function(child)
		return child:IsA("Part")
	end)
	```
]=]
function InstanceUtil.cloneChildren(
	parent: Instance,
	newParent: Instance,
	predicate: ((object: Instance) -> boolean)?
): { Instance }
	local newChildren = {}
	for _, child in pairs(parent:GetChildren()) do
		if predicate and not predicate(child) then
			continue
		end
		local newChild = child:Clone()
		table.insert(newChildren, newChild)
		newChild.Parent = newParent
	end
	return newChildren
end



--[=[
	Checks to see if the given instance is any of the given classes.
	@param instance     -- The Instance to check the type of.
	@param classNames   -- The ClassName or ClassNames to check against.
	@return boolean     -- Whether or not the instance is any of the given classes.
	```lua
	local part = Instance.new("Part")
	local potentialClasses = {"BasePart", "Decal", "Texture"}
	local isOneOfTheClasses = InstanceUtil.isClass(part, potentialClasses) -- true
	```
]=]
function InstanceUtil.isClass(instance: Instance, classNames: string | { string }): boolean
	local ClassNames: {string} = if typeof(classNames) == "table" then classNames else { classNames }
	for _, className in ClassNames do
		if instance:IsA(className) then
			return true
		end
	end
	return false
end

--[=[
	Searches for a ModuleScript in the given parent with the given name. If a descendant is found with the given name
	and is an ObjectValue, this value will be assumed to be the ModuleScript. If the ModuleScript could not be found
	it will return the defaultValue if it is provided. Otherwise it will error.

	@param parent       -- The Instance that has it and its descendants checked against.
	@param moduleName   -- The name of the ModuleScript to search for.
	@param defaultValue -- The default value to return if the ModuleScript could not be found.
	@return any
	```lua
	local module = InstanceUtil.fetchModule(workspace, "MyModule")
	```
]=]
function InstanceUtil.fetchModule<T>(parent: Instance, moduleName: string, defaultValue: any?): any
	local module: ModuleScript = nil
	if parent.Name == moduleName and parent:IsA("ModuleScript") then
		module = parent
	else
		local child = parent:FindFirstChild(moduleName, true)
		if child then
			if child:IsA("ModuleScript") then
				module = child
			elseif child:IsA("ObjectValue") then
				local v = child.Value
				assert(v and v:IsA("ModuleScript"), ("Failed to find a ModuleScript: %s"):format(moduleName))
				module = v
			end
		end
	end

	if not module and defaultValue then
		return defaultValue
	end

	assert(module and module:IsA("ModuleScript"), ("Failed to find a ModuleScript: %s"):format(moduleName))
	return require(module) :: any
end

--[=[
	Checks to see if a given instance has a property. If it does, it will return true and the value of the property.
	If it does not, it will return false and a message.
	@param object       -- The Instance to check the property of.
	@param property     -- The property to check for.
	@return boolean     -- Whether or not the instance has the property.
	@return any         -- The value of the property if it exists.
	```lua
	local part = Instance.new("Part")
	local subPart = Instance.new("Part")
	subPart.Name = "Size"
	subPart.Parent = part

	local hasProperty, value = InstanceUtil.hasProperty(part, "Size")
	if hasProperty then
		print("Part has Size property:", value)
	end
	```
]=]
function InstanceUtil.hasProperty(object: Instance, property: string): (boolean, any)
	if object:FindFirstChild(property) then
		object = object:Clone()
		object:ClearAllChildren()
	end

	local success, value = pcall(function()
		return (object :: any)[property]
	end)

	return success, value
end

--[=[
	Plays a tween as a promise. If a tween is not given then standard tween parameters are used to create a new tween.
	@param obj          -- The Tween to play or the instance to play on.
	@return Promise     -- A Promise that resolves when the tween has finished.
	```lua
	local part = Instance.new("Part")
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	local goals = {
		Size = Vector3.new(10, 10, 10),
		Position = Vector3.new(0, 10, 0),
	}

	InstanceUtil.playTween(part, tweenInfo, goals):andThen(function()
		print("Tween has finished playing.")
	end)
	```
]=]
function InstanceUtil.playTween(
	obj: Tween | Instance,
	info: TweenInfo?,
	goals: { [string]: any }?
): Promise<Enum.PlaybackState>
	if typeof(obj) == "Instance" and not obj:IsA("TweenBase") then
		obj = TweenService:Create(obj, info, goals)
	end
	assert(obj:IsA("Tween"))
	local prom = Promise.fromEvent(obj.Completed):andThen(function(status: Enum.PlaybackState)
		if status == Enum.PlaybackState.Cancelled then
			return Promise.reject(status)
		end
		return Promise.resolve(status)
	end)
	obj:Play()
	return prom
end


--[=[
	Takes a track or array of AnimationTracks and plays them all asynchronously.
	@param tracks       -- The AnimationTrack or array of AnimationTracks to play.
	@param animInfo     -- The AnimPlayInfo to use when playing the tracks.
	@param keyframeMarkerToResolveAt        -- The Keyframe marker to resolve at instead of the animations ending
	@return Promise     -- A Promise that resolves when all tracks have stopped playing.
	```lua
	local track = Instance.new("Animation")
	local animInfo = {
		FadeInTime = 0.5,
		Weight = 1,
		Speed = 1,
		FadeOutTime = 0.5,
	}

	InstanceUtil.playTracksAsync(track, animInfo):andThen(function()
		print("Animation has finished playing.")
	end)
	```
]=]
function InstanceUtil.playTracksAsync(
	tracks: AnimationTrack | { AnimationTrack },
	animInfo: AnimPlayInfo?,
	keyframeMarkerToResolveAt: string?
): Promise<any>
	animInfo = animInfo or {}
	if typeof(tracks) ~= "table" then
		tracks = { tracks }
	end
	assert(typeof(tracks) == "table", "Tracks must be an array of AnimationTracks.")
	assert(typeof(animInfo) == "table", "AnimInfo must be a table.")
	return Promise.all(TableUtil.Map(tracks, function(track: AnimationTrack)
		track:Play(animInfo.FadeInTime, animInfo.Weight, animInfo.Speed)
		local resolutionProm
		if keyframeMarkerToResolveAt then
			resolutionProm = Promise.race({
				Promise.fromEvent(track:GetMarkerReachedSignal(keyframeMarkerToResolveAt)),
				Promise.fromEvent(track.Stopped),
			})
		else
			resolutionProm = Promise.fromEvent(track.Stopped)
		end

		return resolutionProm:finally(function(status)
			if status == Promise.Status.Cancelled then
				track:Stop(animInfo.FadeOutTime)
			end
		end)
	end))
end


--[=[
	Takes an Instance and Emits it and any descendants it has.

	Optional Attributes that any of the descendant ParticleEmitters could have:
	```
		EmitDelay: number? -- The delay before emitting
		EmitCount: number? -- The number of particles to emit at the start
		EmitDuration: number? -- The duration to emit particles for
	```

	@param parent	 -- The Instance to search Particles for
	@param emitCount -- The number of particles to emit
	```lua
	InstanceUtil.emitParticles(workspace.Effect)
	```
]=]
function InstanceUtil.emitParticles(parent: Instance, emitCount: number?)
	if parent:IsA("ParticleEmitter") then
		local PE: ParticleEmitter = parent
		local function Emit()
			PE:Emit(emitCount or PE:GetAttribute("EmitCount") :: number? or 10)
			local EmitDuration: number? = PE:GetAttribute("EmitDuration") :: any
			if typeof(EmitDuration) == "number" then
				PE.Enabled = true
				task.delay(EmitDuration, function()
					PE.Enabled = false
				end)
			end
		end

		local EmitDelay: number? = PE:GetAttribute("EmitDelay") :: any
		if typeof(EmitDelay) == "number" then
			task.delay(EmitDelay, Emit)
		else
			Emit()
		end
	end
	for _, child in pairs(parent:GetChildren()) do
		InstanceUtil.emitParticles(child)
	end
end

--------------------------------------------------------------------------------
--// Deprecated / Private Methods //--
--------------------------------------------------------------------------------

--[=[
	@private
	Iterates through descendants of Model and unanchor necessary parts to play animations correctly.
	@param model -- Model to check and set .Anchor property to.
]=]
function InstanceUtil.guaranteeAnchoringToAnimate(model: Model | Actor)
	local Descendants: { BasePart } = InstanceUtil.getDescendantsWhichAre(model, "BasePart") :: any
	for _, Part in ipairs(Descendants) do
		if Part.Name == "HumanoidRootPart" then
			continue
		end
		Part.Anchored = false
	end
end

--[=[
	@private
	Ensures the getting and creation of an Animator in the given Parent.
	@param Parent       -- The Parent to search for an Animator in.
	@return Animator    -- The Animator found or created.
]=]
function InstanceUtil.ensureAnimator(Parent: Instance): Animator
	local AnimatorParent = Parent:FindFirstChildOfClass("AnimationController")
		or Parent:FindFirstChildOfClass("Humanoid")
	if not AnimatorParent then
		warn(
			"No Humanoid or AnimationController found in Parent",
			Parent:GetFullName(),
			"; Consider setting one up at Edit Time."
		)
		local AnimController = Instance.new("AnimationController")
		AnimController.Parent = Parent
		AnimatorParent = AnimController
	end
	
	local Animator = (AnimatorParent :: any):FindFirstChildOfClass("Animator")
	if not Animator then
		warn("Failed to Find Animator in Parent", AnimatorParent, "; Consider setting one up at Edit Time.")
		Animator = Instance.new("Animator")
		Animator.Parent = AnimatorParent
	end
	return Animator
end

--[=[
	@private
	Loads an animation asynchronously. Originally made to be used with models being displayed in
	ViewportFrames with Fusion.
	@param SourceAnimator   -- Animator to load the animation into.
	@param AnimationToLoad  -- The animation to load.
	@return Promise<AnimationTrack>
]=]
function InstanceUtil.loadAnimAsync(SourceAnimator: Animator, AnimationToLoad: Animation): Promise<AnimationTrack>
	local function AttemptLoad()
		return Promise.new(function(resolve, reject)
			local success, LoadedAnim = pcall(function()
				return SourceAnimator:LoadAnimation(AnimationToLoad)
			end)
			if success then
				LoadedAnim.Name = AnimationToLoad.Name
				resolve(LoadedAnim)
			else
				warn("Failed to Load Animation:", SourceAnimator:GetFullName(), AnimationToLoad.Name)
				reject(LoadedAnim)
			end
		end)
	end
	return Promise.retryWithDelay(AttemptLoad, 50, 0.1)
end

--[=[
	@ignore
	THIS METHOD IS DEPRECATED AS ASSEMBLYMASS TAKES FROM THE FULL ASSEMBLY
	Gets the Total Mass of an Assembly.
	@param assembly -- The Instance to get the mass of.
	@return number  -- The total mass of the assembly.
]=]
function InstanceUtil.getMass(assembly: Instance): number
	assert(assembly and typeof(assembly) == "Instance", "Model argument of getMass must be an Instance.")
	local mass = 0
	for _, v in pairs(assembly:GetDescendants()) do
		if v:IsA("BasePart") and not (v :: BasePart).Massless then
			mass += (v :: BasePart).AssemblyMass
		end
	end
	return mass
end


--[=[
	Gets the first ancestor of the given object that satisfies the given predicate.
	@param obj       -- The Instance to start the search from.
	@param predicate -- The predicate to check for.
	@return Instance -- The first ancestor that satisfies the predicate.
]=]
function InstanceUtil.getFirstAncestorWithPredicate(obj: Instance, predicate: (ancestor: Instance) -> boolean, includeObject: boolean?): Instance?
	local current = if includeObject then obj else obj.Parent
	while current do
		if predicate(current) then
			return current
		end
		current = current.Parent
	end
	return nil
end



return InstanceUtil

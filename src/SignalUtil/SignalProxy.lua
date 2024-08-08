--!strict
-- Authors: Logan Hunt [Raildex]
-- January 18, 2023
--[=[
    @class SignalProxy
    @ignore

    Idea stolen from Brandon >:)
    Acts as a proxy for multiple signals, and fires when any of the signals are fired.
]=]

--[[ API
    .new(signalTable: {Types.Signal<any> | RBXScriptSignal}): SignalProxy
    :Destroy()
    :DisconnectAll()
    :GetConnections(): {Types.Connection}
    :Connect(callback: () -> ()): Types.Connection
    :Once(callback: () -> ()): Types.Connection
    :Wait(): ...any
]]

--// Requires //--
local RailUtil = script.Parent.Parent
local Janitor = require(RailUtil.Parent.Janitor)
local Signal = require(RailUtil.Parent.Signal)

type Connection = any
type Signal<T> = any

--------------------------------------------------------------------------------
--// Class Declaration //--
--------------------------------------------------------------------------------

--// Class Type Declarations //--
export type SignalProxy = {
	ClassName: "SignalProxy",
	--new: (signalTable: {Types.Signal<any> | RBXScriptSignal}) -> SignalProxy;
	Destroy: (self: SignalProxy) -> (),
	GetConnections: (self: SignalProxy) -> { Connection },
	DisconnectAll: (self: SignalProxy) -> (),
	Connect: (self: SignalProxy, callback: () -> ()) -> Connection,
	Once: (self: SignalProxy, callback: () -> ()) -> Connection,
	Wait: (self: SignalProxy) -> ...any,
}

--// Class Setup //--
local SignalProxy = {}
SignalProxy.ClassName = "SignalProxy"
SignalProxy.__index = SignalProxy

--------------------------------------------------------------------------------
--// Class Constructor/Deconstructor //--
--------------------------------------------------------------------------------

--[=[
    The constructor for a SignalProxy Object.
    @return SignalProxy
]=]
function SignalProxy.new(signalTable: { Signal<any> | RBXScriptSignal }): SignalProxy
	local self = setmetatable({}, SignalProxy) :: any

	self._Janitor = Janitor.new()
	self._ProxySignal = self._Janitor:Add(Signal.new())

	-- Observes all signals, and fires ProxySignal
	for _, signal in signalTable do
		self._Janitor:Add(signal:Connect(function(...)
			self._ProxySignal:Fire(...)
		end))
	end

	return self
end

--[=[
    The Deconstructor for a SignalProxy Object.
]=]
function SignalProxy:Destroy()
	self._Janitor:Destroy()
end

--[=[
    A description of why this method exists, what it does, and how to use it.
]=]
function SignalProxy:GetConnections(): { Connection }
	return self._ProxySignal:GetConnections()
end

--[=[
    Disconnects all handlers.
]=]
function SignalProxy:DisconnectAll(): ()
	return self._ProxySignal:DisconnectAll()
end

--[=[
    Connects a callback to the SignalProxy.
    @param callback The callback to connect to the SignalProxy.
    @return Types.Connection
]=]
function SignalProxy:Connect(callback: () -> ()): Connection
	return self._ProxySignal:Connect(callback)
end

--[=[
    Connects a callback to the SignalProxy that only connects once.
    @param callback The callback to connect to the SignalProxy.
    @return Types.Connection
]=]
function SignalProxy:Once(callback: () -> ()): Connection
	return self._ProxySignal:Connect(callback)
end

--[=[
    Yields the current thread until the SignalProxy is fired.
    @return (...any) The arguments that were passed to the SignalProxy.
]=]
function SignalProxy:Wait(): ...any
	return self._ProxySignal:Wait()
end

return SignalProxy

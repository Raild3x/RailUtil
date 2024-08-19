--!strict
-- Authors: Logan Hunt [Raildex]
-- January 19, 2023

local SignalProxy = require(script.SignalProxy)

type Connection = any
type Signal = {
	Connect: (self: Signal, callback: (...any) -> ()) -> Connection,
	Once: (self: Signal, callback: (...any) -> ()) -> Connection,
}

type SignalProxy = SignalProxy.SignalProxy

--------------------------------------------------------------------------------
--// Class //--
--------------------------------------------------------------------------------
--[=[
    @class SignalUtil
]=]
local SignalUtil = {}

--[=[
    Combines a bunch of signals into one signal.
    @param signalTbl The table of signals to combine.
    @return A SignalProxy object that acts as a proxy for the signals.
]=]
function SignalUtil.combine(signalTbl: { Signal | RBXScriptSignal }): SignalProxy
	return SignalProxy.new(signalTbl)
end

return SignalUtil

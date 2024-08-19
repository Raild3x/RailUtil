-- This file just contains the dependency types for the RailUtil library. It is not meant to be used externally in any way.

--------------------------------------------------------------------------------
--// Janitor //--
--------------------------------------------------------------------------------

export type Janitor = {
	ClassName: "Janitor",
	CurrentlyCleaning: boolean,
	SuppressInstanceReDestroy: boolean,

	Add: <T>(self: Janitor, Object: T, MethodName: (boolean | string)?, Index: any?) -> T,
	AddPromise: <T>(self: Janitor, PromiseObject: T) -> T,

	Remove: (self: Janitor, Index: any) -> Janitor,
	RemoveNoClean: (self: Janitor, Index: any) -> Janitor,

	RemoveList: (self: Janitor, ...any) -> Janitor,
	RemoveListNoClean: (self: Janitor, ...any) -> Janitor,

	Get: (self: Janitor, Index: any) -> any?,
	GetAll: (self: Janitor) -> { [any]: any },

	Cleanup: (self: Janitor) -> (),
	Destroy: (self: Janitor) -> (),

	LinkToInstance: (self: Janitor, Object: Instance, AllowMultiple: boolean?) -> RBXScriptConnection,
	LinkToInstances: (self: Janitor, ...Instance) -> Janitor,
}

--------------------------------------------------------------------------------
--// Promise //--
--------------------------------------------------------------------------------

export type StatusType = "Started" | "Resolved" | "Rejected" | "Cancelled"
export type Status = {
	Started: "Started", -- The Promise is executing, and not settled yet.
	Resolved: "Resolved", -- The Promise finished successfully.
	Rejected: "Rejected", -- The Promise was rejected.
	Cancelled: "Cancelled", -- The Promise was cancelled before it finished.
}

export type resolve = (...any) -> ()
export type reject = (...any) -> ()
export type onCancel = (abortHandler: (() -> ())?) -> boolean

type Executor = (executor: (resolve: resolve, reject: reject, onCancel: onCancel) -> ()) -> Promise

export type PromiseClass = {
	Status: Status,

	new: Executor,
	defer: Executor,
	resolve: (...any) -> Promise,
	reject: (...any) -> Promise,

	promisify: <P...>(callback: (P...) -> ...any) -> (P...) -> Promise,

	try: <T...>(
		callback: (T...) -> ...any,
		T... -- Additional arguments passed to callback
	) -> Promise,

	fromEvent: (
		event: { Connect: () -> () } | RBXScriptSignal, -- Any object with a Connect method. This includes all Roblox events.
		predicate: ((...any) -> boolean)? -- A function which determines if the Promise should resolve with the given value, or wait for the next event to check again.
	) -> Promise, --<P>

	retry: <P...>(
		callback: (P...) -> Promise, --<T>
		retries: number,
		P...
	) -> Promise, --<T>

	retryWithDelay: <P...>(
		callback: (P...) -> Promise, --<T>
		retries: number,
		seconds: number,
		P...
	) -> Promise, --<T>

	race: ({ Promise }) -> Promise,

	allSettled: ({ Promise }) -> Promise,

	all: ({ Promise }) -> Promise,

	any: ({ Promise }) -> Promise,

	delay: (seconds: number) -> Promise,
}

export type Promise = {
	getStatus: (Promise) -> StatusType,

	andThen: (
		self: Promise,
		successHandler: (...any) -> ...any,
		failureHandler: ((...any) -> ...any)?
	) -> Promise,

	andThenCall: <P...>(self: Promise, callback: (P...) -> ...any, P...) -> Promise,

	andThenReturn: (self: Promise, ...any) -> Promise,

	cancel: (self: Promise) -> (),

	catch: (self: Promise, failureHandler: (...any) -> ...any) -> Promise,

	finally: (self: Promise, finallyHandler: (status: StatusType) -> ...any) -> Promise,

	finallyCall: <P...>(self: Promise, callback: (P...) -> ...any, P...) -> Promise,

	finallyReturn: (self: Promise, ...any) -> Promise,

	await: (
		self: Promise
	) -> (
		boolean, -- true if the Promise successfully resolved
		...any -- The values the Promise resolved or rejected with.
	),

	awaitStatus: (self: Promise) -> (
		StatusType,
		...any -- The values the Promise resolved or rejected with.
	),

	expect: (self: Promise) -> ...any,

	timeout: (
		self: Promise,
		seconds: number,
		rejectionValue: any? -- The value to reject with if the timeout is reached
	) -> Promise,

	tap: (self: Promise, tapHandler: (...any) -> ...any) -> Promise,

	now: (self: Promise, rejectionValue: any) -> Promise,
}

--------------------------------------------------------------------------------
--// Final Return //--
--------------------------------------------------------------------------------

return nil
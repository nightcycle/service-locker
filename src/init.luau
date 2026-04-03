--!strict
export type InitializationInterface = {
	IsInitialized: false,
	init: () -> () -> (),
}
return function<V>(
	constructor: () -> V,
	destructor: (V) -> (),
	excludeGetFEnv: boolean?
): InitializationInterface | (V & { getfenv: (...any) -> { [string]: any } })
	local currentService: any?
	local interface = {
		IsInitialized = false,
		init = function()
			if currentService ~= nil then
				return function() end
			end
			currentService = constructor()
			assert(currentService ~= nil, `construction failed`)

			return function()
				destructor(currentService)
			end
		end,
	}
	do
		-- Create the metatable
		local meta = {}
		function meta:__index(key: any): any
			if currentService == nil then
				return interface[key]
			else
				return currentService[key]
			end
		end

		function meta:__newindex(key: any, val: any?): ()
			if currentService == nil then
				error(`you can't write to the init interface`)
			else
				currentService[key] = val
			end
		end

		function meta:__call(...): any
			if currentService == nil then
				error(`you can't cal the init interface`)
			else
				local method: any = currentService
				return method(...)
			end
		end

		function meta.getfenv(...)
			if excludeGetFEnv then
				return {}
			else
				return getfenv(...)
			end
		end

		-- Create the proxy table
		local proxy = {}
		setmetatable(proxy, meta)

		return proxy :: any
	end
end

--!strict
export type InitializationInterface = {
	IsInitialized: false,
	init: () -> () -> (),
}
return function<V>(
	constructor: () -> V,
	destructor: (V) -> (),
	excludeGetFEnv: boolean?
): InitializationInterface | (V & { _getfenv: (...any) -> { [string]: any } })
	local currentService: any?
	local interface = {
		IsInitialized = false,
		init = function()
			if currentService ~= nil then
				return function() end
			end
			local service = constructor()
			currentService = service
			assert(currentService ~= nil, `construction failed`)

			return function()
				if currentService == service then
					currentService = nil
				end
				destructor(service)
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

		function meta._getfenv(...)
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

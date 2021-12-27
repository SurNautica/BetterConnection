local betterConnection = {Class = {}}
betterConnection.Class.__index = betterConnection.Class

-- constructors
function betterConnection:Create(objectWithConnection, ...)
	assert(objectWithConnection and objectWithConnection.Connect,"[BetterConnection]: invalid arg #1 for 'Create' must have a Connect function")
	
	local Arguments = {...}
	
	local connectionProperties,handlerFunction
	
	if Arguments[1] then
		local type = typeof(Arguments[1])
		if type == "table" then
			connectionProperties = Arguments[1]
			if Arguments[2] and typeof(Arguments[2]) == "function" then
				handlerFunction = Arguments[2]
			end
		elseif type == "function" then
			handlerFunction = Arguments[1]
		end
	end
	
	connectionProperties = connectionProperties or {}
	
	assert(handlerFunction and typeof(handlerFunction) == "function","[BetterConnection]: invalid handlerFunction for 'Create'")
	
	local self = setmetatable({
		_connections = {},
		_values = {startTime = connectionProperties.LimitedTime and tick() or nil}
	},betterConnection.Class)
	
	local function execute(...)
		-- check fires
		local limitedFires = connectionProperties.LimitedFires
		
		if limitedFires then
			if limitedFires <= 0 then
				return self:Destroy()
			else
				limitedFires -= 1
			end
		end
		
		-- check time
		local limitedTime = connectionProperties.LimitedTime
		
		if limitedTime then
			if (self._values.startTime + connectionProperties.LimitedTime) < tick() then
				return self:Destroy()
			end
		end
		
		return handlerFunction(...)
	end
	
	table.insert(self._connections,objectWithConnection:Connect(execute))
	
	return self
end

-- class functions
function betterConnection.Class:Destroy()
	-- disconnect connections
	for _,connection in pairs(self._connections) do
		if typeof(connection) == "RBXScriptConnection" then
			if not connection.Connected then
				connection:Disconnect()
			end
		end
	end
	
	return false,"destroyed"
end
betterConnection.Class.Disconnect = betterConnection.Class.Destroy

return betterConnection
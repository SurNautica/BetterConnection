local BadgeService = game:GetService("BadgeService")
local betterConnection = {Class = {},Debug = false,Version = "1.0"}
betterConnection.Class.__index = betterConnection.Class

-- private functions
local function log(type, shouldIncludeDebug, ...)
	if shouldIncludeDebug then
		if not betterConnection.Debug then
			return false,"debug not enabled"
		end
	end
	type("[BetterConnections]:", ...)
end
local function disconnectTable(table)
	
end

-- constructors
function betterConnection:Connect(objectWithConnection, ...) -- create a base manager
	assert(objectWithConnection and objectWithConnection.Connect,"[BetterConnections]: invalid arg #1 for 'Create' must have a Connect function")
	
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
	
	assert(handlerFunction and typeof(handlerFunction) == "function","[BetterConnections]: invalid handlerFunction for 'Create'")

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

		-- check valid function
		local validFunction = connectionProperties.ValidateFunction

		if validFunction and typeof(validFunction) == "function" then
			if not validFunction(...) then
				return self:Destroy()
			end
		end
		
		return handlerFunction(...)
	end
	
	table.insert(self._connections,objectWithConnection:Connect(execute))
	
	return self
end

function betterConnection:CreateWorkspace() -- workspace!
	local self = {_activeConnections = {}}

	function self:Connect(...)
		local new = betterConnection:Connect(...)
		table.insert(self._activeConnections,new)
		return new
	end
	function self:CleanUp()
		for _,connection in pairs(self._activeConnections) do
			connection:Destroy()
		end
	end	
	self.Destroy = self.CleanUp

	return self
end

-- global 
function betterConnection:toggleDebug(toggle: boolean?)
	if toggle == nil then
		toggle = not betterConnection.Debug
	end

	betterConnection.Debug = toggle
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
	log(print,true,"destoryed betterconnection")
	return true,"destroyed"
end
betterConnection.Class.Disconnect = betterConnection.Class.Destroy

do
	log(print,"loaded bC version",betterConnection.Version)
end

return betterConnection
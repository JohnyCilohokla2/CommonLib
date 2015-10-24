-------------------------------------------------------------------------------
if SignalInterface == nil then
	SignalInterface = EternusEngine.Mixin.Subclass("SignalInterface")
end

SignalInterface.SignalAlreadyExists = 2
SignalInterface.Successful = 1
SignalInterface.InvalidChannel = -1

SignalInterface.__nochain =
{
	'DefaultSignalState',
	'OnSignalChanged'
}

function SignalInterface:Constructor(args)
	self.m_channelData = {}
	if args and args.Channels then
		for channelName,channelData in pairs(args.Channels) do
			self.m_channelData[channelName] = {
											name = channelName,
											state = self:DefaultSignalState(channelName),
											data = channelData,
											listeners = {}
										}
		end
	else
		self.m_channelData["signal"] = {
										name = "signal",
										state = self:DefaultSignalState("signal"),
										data = {},
										listeners = {}
									}
	end
end

function SignalInterface:DefaultSignalState(channelName)
	return false
end

function SignalInterface:OnSignalChanged(state, channel)
end

function SignalInterface:SetSignalState(state, channelName)
	channelName = channelName or "signal"
	CL.out("SignalInterface:SetSignalState(" .. channelName .. ", " .. tostring(state) .. ")\n")
	local channel = self.m_channelData[channelName]
	if channel then
		channel.state = state
		self:_ForwardSignalState(channel)
		self:OnSignalChanged(channel.state, channel)
		return true, SignalInterface.Successful
	else
		return false, SignalInterface.InvalidChannel
	end
end

function SignalInterface:ToggleSignalState(channelName)
	channelName = channelName or "signal"
	CL.out("SignalInterface:ToggleSignalState(" .. channelName .. ")\n")
	local channel = self.m_channelData[channelName]
	if channel then
		channel.state = not channel.state
		self:_ForwardSignalState(channel)
		self:OnSignalChanged(channel.state, channel)
		return true, SignalInterface.Successful
	else
		return false, SignalInterface.InvalidChannel
	end
end

function SignalInterface:AddSignalListener(listener, channelName, targetChannel)
	channelName = channelName or "signal"
	targetChannel = targetChannel or "signal"
	CL.out("SignalInterface:AddSignalListener(" .. channelName .. " -> " .. targetChannel.. ")\n")
	local channel = self.m_channelData[channelName]
	if channel then
		if not channel.listeners[listener] then
			channel.listeners[listener] = targetChannel
			self:_ForwardSignalState(channel, listener, targetChannel)
			return true, SignalInterface.Successful
		else
			return false, SignalInterface.SignalAlreadyExists
		end
	else
		return false, SignalInterface.InvalidChannel
	end
end

function SignalInterface:_ForwardSignalState(channel, listener, targetChannel)
	if listener then
		CL.out("SignalInterface:_ForwardSignalState(" .. channel.name .. " = " .. tostring(channel.state) .. " -> " .. targetChannel.. ")\n")
		listener:_ReceiveSignalState(self, targetChannel, channel.state)
	else
		CL.out("SignalInterface:_ForwardSignalState(" .. channel.name .. " = " .. tostring(channel.state) .. ")\n")
		for listener,targetChannel in pairs(channel.listeners) do
			CL.out("SignalInterface:_ForwardSignalState(" .. channel.name .. " = " .. tostring(channel.state) .. " -> " .. targetChannel.. ")\n")
			listener:_ReceiveSignalState(self, targetChannel, channel.state)
		end
	end
end

function SignalInterface:_ReceiveSignalState(from, targetChannel, state)
	CL.out("SignalInterface:_ReceiveSignalState(" .. targetChannel .. " = " .. tostring(state) .. ")\n")
	self:SetSignalState(state, targetChannel)
end

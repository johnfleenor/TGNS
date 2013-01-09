// TGNS Common

TGNS = {}

function TGNS:GetPlayerList()

	local playerList = EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
	table.sort(playerList, function(p1, p2) return p1:GetName() < p2:GetName() end)
	return playerList

end

function TGNS:AllPlayers(doThis)

	return function(client)
	
		local playerList = self:GetPlayerList()
		for p = 1, #playerList do
		
			local player = playerList[p]
			doThis(player, client, p)
			
		end
		
	end
	
end

function TGNS:GetPlayerMatchingName(name, team)

	assert(type(name) == "string")
	
	local nameMatchCount = 0
	local match = nil
	
	local function Matches(player)
		if nameMatchCount == -1 then
			return // exact match found, skip others to avoid further partial matches
		end
		local playerName =  player:GetName()
		if player:GetName() == name then // exact match
			if team == nil or team == -1 or team == player:GetTeamNumber() then
				match = player
				nameMatchCount = -1
			end
		else
			local index = string.find(string.lower(playerName), string.lower(name)) // case insensitive partial match
			if index ~= nil then
				if team == nil or team == -1 or team == player:GetTeamNumber() then
					match = player
					nameMatchCount = nameMatchCount + 1
				end
			end
		end
		
	end
	self:AllPlayers(Matches)()
	
	if nameMatchCount > 1 then
		match = nil // if partial match is not unique, clear the match
	end
	
	return match

end

function TGNS:GetPlayerMatchingSteamId(steamId, team)

	assert(type(steamId) == "number")
	
	local match = nil
	
	local function Matches(player)
	
		local playerClient = Server.GetOwner(player)
		if playerClient and playerClient:GetUserId() == steamId then
			if team == nil or team == -1 or team == player:GetTeamNumber() then
				match = player
			end
		end
		
	end
	self:AllPlayers(Matches)()
	
	return match

end

function TGNS:GetPlayerMatching(id, team)

	local idNum = tonumber(id)
	if idNum then
		// note: using DAK's GetPlayerMatchingGameId
		return GetPlayerMatchingGameId(idNum, team) or self:GetPlayerMatchingSteamId(idNum, team)
	elseif type(id) == "string" then
		return self:GetPlayerMatchingName(id, team)
	end

end

if kDAKConfig and kDAKConfig.DAKLoader then

	// Returns:	builtChatMessage - a ChatMessage object
	//			consoleChatMessage - a similarly formed string for printing to the console
	function TGNS:BuildPMChatMessage(srcClient, message, command, showCommand)
		if srcClient then
			local srcPlayer = srcClient:GetControllingPlayer()
			if srcPlayer then
				srcName = srcPlayer:GetName()
			else
				srcName = kDAKConfig.DAKLoader.MessageSender
			end
		else
			srcName = kDAKConfig.DAKLoader.MessageSender
		end

		if showCommand then
			chatName =  command .. " - " .. srcName
		else
			chatName = srcName
		end

		consoleChatMessage = chatName ..": " .. message
		builtChatMessage = BuildChatMessage(false, chatName, -1, kTeamReadyRoom, kNeutralTeamType, message)
		return builtChatMessage, consoleChatMessage
	end
	
	function TGNS:PMAllPlayersWithAccess(srcClient, message, command, showCommand, selfIfNoAccess)
		builtChatMessage, consoleChatMessage = self:BuildPMChatMessage(srcClient, message, command, showCommand)
		for _, player in pairs(self:GetPlayerList()) do
			local client = Server.GetOwner(player)
			if client ~= nil then
				if DAKGetClientCanRunCommand(client, command) or (selfIfNoAccess and client == srcClient) then
					Server.SendNetworkMessage(player, "Chat", builtChatMessage, true)
					ServerAdminPrint(client, consoleChatMessage)
				end
			end
		end
	end
end

////////////////////
// Intercept Chat //
////////////////////

kTGNSChatHooks = {}

function TGNS:RegisterChatHook(func)
	DAKRegisterEventHook(kTGNSChatHooks, func, 1)
end

local originalOnChatReceived

local function OnChatReceived(client, message)
	if #kTGNSChatHooks > 0 then
		for i = #kTGNSChatHooks, 1, -1 do
			if kTGNSChatHooks[i].func(client, message.message) then
				return
			end
		end
	end
	originalOnChatReceived(client, message)
end

local originalHookNetworkMessage = Server.HookNetworkMessage

Server.HookNetworkMessage = function(networkMessage, callback)
	if networkMessage == "ChatClient" then
		Print("Hook ChatClient network message")
		originalOnChatReceived = callback
		callback = OnChatReceived
	end
	originalHookNetworkMessage(networkMessage, callback)

end
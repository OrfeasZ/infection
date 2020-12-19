require('__shared/net')
require('__shared/round-state')

require('visuals')
require('infected-vision')
require('extraction')
require('endcam')

--[[
Console:Register('chopper', 'Spawns a chopper.', function(args)
	NetEvents:Send('chopper')
end)

Console:Register('extract', 'Extract.', function(args)
	NetEvents:Send('extract')
end)

Console:Register('infect', 'Infects a player.', function(args)
	if #args ~= 1 then
		return 'Usage: infection.infect <player name>'
	end

	NetEvents:Send('infect', args[1])
end)

Console:Register('human', 'Humanizes a player.', function(args)
	if #args ~= 1 then
		return 'Usage: infection.human <player name>'
	end

	NetEvents:Send('human', args[1])
end)

Console:Register('vision', 'Sets infected vision.', function(args)
	setInfectedVision()
end)


Console:Register('rvision', 'Removes infected vision.', function(args)
	removeInfectedVision()
end)

Console:Register('chopper', 'Spawns a chopper.', function(args)
	NetEvents:Send('chopper')
end)

Console:Register('flare', 'Creates a flare', function(args)
	local player = PlayerManager:GetLocalPlayer()

	if player == nil or player.soldier == nil then
		return 'Player is dead'
	end

	local flareBp = ResourceManager:SearchForDataContainer('FX/Ambient/Warfare/SignalFlare/Prefab_SignalFlare_Red_NoAuto')

	if flareBp == nil then
		return 'Could not find flare'
	end

	local up = player.soldier.transform.trans:Clone()
	up.y = up.y + 1

	local transform = LinearTransform()
	transform:LookAtTransform(player.soldier.transform.trans, up)
	transform.trans.y = transform.trans.y + 0.10

	local bus = EntityManager:CreateEntitiesFromBlueprint(flareBp, transform)

	if bus == nil then
		return 'Failed to spawn flare'
	end

	print('Spawned flare!')

	for _, entity in pairs(bus.entities) do
		entity:Init(Realm.Realm_Client, false)
		entity:FireEvent('Start')
	end
end)

Console:Register('bot', 'Spawns a bot.', function(args)
	NetEvents:Send('bot')
end)

Console:Register('ready', 'Ready.', function(args)
	NetEvents:Send('ready')
end)

NetEvents:Subscribe('human', function(player)
	if player == PlayerManager:GetLocalPlayer().name then
		removeInfectedVision()
	end
end)
]]

Events:Subscribe('Extension:Loaded', function()
	WebUI:Init()

    -- If we already have a local player we'll assume this is a hot reload and we're already in-game.
    if PlayerManager:GetLocalPlayer() ~= nil then
        print('Ingame after hot reload. Notifying server that we\'re ready.')
        NetEvents:SendLocal(NetMessage.C2S_CLIENT_READY)
    end

    -- Wait until we've entered the game to notify the server that we're ready.
    Events:Subscribe('Engine:Message', function(message)
        if message.type == MessageType.CoreEnteredIngameMessage then
            print('Now ingame. Notifying server that we\'re ready.')
			WebUI:ExecuteJS('showUI();')
            NetEvents:SendLocal(NetMessage.C2S_CLIENT_READY)
        end
    end)
end)

local lastHumanCount = 0

local function updateHumanCount()
	local humanCount = 0

	for _, player in pairs(PlayerManager:GetPlayersByTeam(TeamId.Team1)) do
		-- Ignore bots
		if player.onlineId ~= 0 then
			humanCount = humanCount + 1
		end
	end

	if humanCount == lastHumanCount then
		return
	end

	lastHumanCount = humanCount

	WebUI:ExecuteJS('setHumanCount(' .. tostring(humanCount) .. ');')
end

NetEvents:Subscribe(NetMessage.S2C_PLAYER_INFECTED, function(onlineId)
	if onlineId == PlayerManager:GetLocalPlayer().onlineId then
		setInfectedVision()
	end

	updateHumanCount()
end)

NetEvents:Subscribe(NetMessage.S2C_ROUND_INFO, function(roundInfo)
	WebUI:ExecuteJS('setRoundInfo(' .. tostring(roundInfo.roundState) .. ', ' .. tostring(roundInfo.roundTime) .. ');')
end)

NetEvents:Subscribe(NetMessage.S2C_GAME_ENDED, function(survivors)
	local survivorNames = {}

	for _, onlineId in pairs(survivors) do
		local player = PlayerManager:GetPlayerByOnlineId(onlineId)

		if player ~= nil then
			table.insert(survivorNames, player.name)
		end
	end

	if #survivorNames == 0 then
		WebUI:ExecuteJS('gameEnded();')
	else
		WebUI:ExecuteJS('gameEnded(' .. json.encode(survivorNames) .. ');')
		showEndcam()
	end
end)

Events:Subscribe('Level:Destroy', function()
	print('Level getting destroyed. Entering idle state.')
	removeInfectedVision()
	WebUI:ExecuteJS('hideUI();')
end)

-- Update health and human count every 100ms.
local updateTimer = 0.0
local lastHealth = 0

Events:Subscribe('Engine:Update', function(dt)
	updateTimer = updateTimer + dt

	if updateTimer < 0.1 then
		return
	end

	updateTimer = 0.0

	local player = PlayerManager:GetLocalPlayer()

	if player ~= nil and player.soldier ~= nil and player.soldier.health ~= lastHealth then
		lastHealth = player.soldier.health
		WebUI:ExecuteJS('setHealth(' .. tostring(lastHealth) .. ');')
	end

	updateHumanCount()
end)

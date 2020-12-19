roundTimer = 0.0
roundState = RoundState.Idle
local roundUpdateTimer = 5.0

-- Send round info to a player as soon as they join.
NetEvents:Subscribe(NetMessage.C2S_CLIENT_READY, function(player)
	NetEvents:SendTo(NetMessage.S2C_ROUND_INFO, player, {
		roundTime = roundTimer,
		roundState = roundState,
	})
end)

local function broadcastRoundInfo()
	NetEvents:Broadcast(NetMessage.S2C_ROUND_INFO, {
		roundTime = roundTimer,
		roundState = roundState,
	})
end

local function enterStateIdle()
	roundTimer = 0
	roundState = RoundState.Idle

	broadcastRoundInfo()

	for _, player in pairs(PlayerManager:GetPlayers()) do
		if player.teamId == TeamId.Team2 then
			player.teamId = TeamId.Team1
		end
	end
end

local function enterStateInRound()
	roundTimer = Config.TimeLimit
	roundState = RoundState.InRound

	broadcastRoundInfo()

	-- Infect a random player.
	startInfection()
end

local function enterStatePostRound()
	roundTimer = Config.PostRoundTime
	roundState = RoundState.PostRound

	broadcastRoundInfo()
	finishExtraction()
end

local function enterStateExtraction()
	roundTimer = Config.ExtractionTime
	roundState = RoundState.Extraction

	broadcastRoundInfo()

	startExtraction()
end

local function exitStatePostRound()
	roundTimer = 0
	roundState = RoundState.Idle

	broadcastRoundInfo()

	-- Restart level.
	RCON:SendCommand('mapList.restartRound')
end

local extractionUpdateTimer = 0.0

local function updateExtraction(dt)
	-- If we're in the extraction phase and the chopper has arrived (time <= extraction time / 2)
	-- we check every 0.5s if all alive humans are in the extraction point. If they are, we automatically
	-- end the game.
	extractionUpdateTimer = extractionUpdateTimer + dt

	if extractionUpdateTimer < 0.5 then
		return
	end

	extractionUpdateTimer = 0.0

	if roundTimer > Config.ExtractionTime / 2.0 then
		return
	end

	if #getHumansInExtractionZone() == getHumanCount() then
		enterStatePostRound()
	end
end

local function updateRoundActive(dt)
	roundTimer = roundTimer - dt
	roundUpdateTimer = roundUpdateTimer - dt

	-- Round phase has ended. We need to move to the next one.
	if roundTimer <= 0.0 then
		if roundState == RoundState.PreRound then
			enterStateInRound()
		elseif roundState == RoundState.InRound then
			enterStateExtraction()
		elseif roundState == RoundState.Extraction then
			enterStatePostRound()
		elseif roundState == RoundState.PostRound then
			exitStatePostRound()
		end
	end

	if roundState == RoundState.Extraction then
		updateExtraction(dt)
	end

	-- Broadcast round info to all players every 5 seconds.
	if roundUpdateTimer <= 0.0 then
		broadcastRoundInfo()
		roundUpdateTimer = 5.0
	end
end

local function updateRoundInactive(dt)
	-- Check if we have enough players to start the game.
	if getReadyPlayers() < Config.MinPlayers then
		return
	end

	-- We have enough players, start the round start countdown.
	roundTimer = Config.PreInfectionTime
	roundState = RoundState.PreRound

	-- Notify clients of round state change.
	broadcastRoundInfo()
end

Events:Subscribe('Engine:Update', function(dt)
	if roundState ~= RoundState.Idle then
		updateRoundActive(dt)
	else
		updateRoundInactive(dt)
	end
end)

-- Reset round info when a level is loading.
Events:Subscribe('Level:LoadResources', function()
	if not g_IsLevelSupported then
		return
	end

	roundTimer = 0.0
	roundState = RoundState.Idle

	broadcastRoundInfo()
end)

function infectPlayer(player)
	-- Spawn the infected player.
	spawnInfected(player, player.soldier.transform.trans)

	-- Send some notification to the player so we can show custom UI stuff to them.
	NetEvents:BroadcastLocal(NetMessage.S2C_PLAYER_INFECTED, player.onlineId)

	-- If all humans are DED then end the game.
	if getHumanCount() == 0 then
		enterStatePostRound()
	end
end

function startInfection()
	local playerInfected = false

	math.randomseed(SharedUtils:GetTimeMS())

	playerCount = #PlayerManager:GetPlayers()
	infectionChance = 1.0 / playerCount

	while not playerInfected do
		for _, player in pairs(PlayerManager:GetPlayers()) do
			if math.random() <= infectionChance then
				infectPlayer(player)
				playerInfected = true
				break
			end
		end
	end
end

Events:Subscribe('Level:Destroy', function()
	enterStateIdle()
end)

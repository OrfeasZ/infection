local flares = nil
local extractionPoint = nil

local extractionReplays = {
	['levels/xp4_quake/xp4_quake'] = require('replays/xp4_quake')[1],
}

Events:Subscribe('Level:LoadResources', function(levelName)
	flares = nil
	extractionPoint = nil

	if not g_IsLevelSupported then
		print('Level is not supported')
		return
	end

	local levelData = getLevelData(levelName)

	flares = levelData.flares
	extractionPoint = levelData.extraction

	local lowerLevelName = levelName:lower()

	Events:Dispatch('br:load', lowerLevelName, extractionReplays[lowerLevelName])
end)

function startExtraction()
	NetEvents:Broadcast(NetMessage.S2C_EXTRACTION_STARTED, {
		flares = flares,
		point = extractionPoint
	})

	-- Start extraction sequence
	Events:Dispatch('br:play', SharedUtils:GetLevelName():lower())
end

function getHumansInExtractionZone()
	local survivors = {}

	for _, player in pairs(PlayerManager:GetPlayers()) do
		if isHuman(player) and not isBot(player) and player.soldier ~= nil then
			-- Check if the player is inside our extraction radius.
			local distance = player.soldier.transform.trans:Distance(extractionPoint)

			if distance <= 4.5 then
				table.insert(survivors, player.onlineId)
			end
		end
	end

	return survivors
end

function finishExtraction()
	-- We need to figure out which of the humans are inside the extraction point.
	-- Those are the humans that we consider as having survived.
	local survivors = getHumansInExtractionZone()
	NetEvents:Broadcast(NetMessage.S2C_GAME_ENDED, survivors)
end

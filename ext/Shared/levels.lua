local g_LevelData = {
	['levels/xp4_quake/xp4_quake'] = require('__shared/leveldata/xp4_quake'),
}

function isLevelSupported(levelName, gameMode)
	if levelName == nil or gameMode == nil then
		return false
	end

	local supportedLevels = {
		['levels/xp4_quake/xp4_quake'] = { 'teamdeathmatchc0' },
	}

	local lowerLevelName = levelName:lower()
	local lowerGameMode = gameMode:lower()

	if supportedLevels[lowerLevelName] == nil then
		return false
	end

	for _, mode in pairs(supportedLevels[lowerLevelName]) do
		if mode == lowerGameMode then
			return true
		end
	end

	return false
end

function getLevelData(levelName)
	local lowerLevelName = levelName:lower()
	return g_LevelData[lowerLevelName]
end

local infectedSpawns = nil
local startingSpawns = nil

Events:Subscribe('Level:LoadResources', function(levelName)
	infectedSpawns = nil
	startingSpawns = nil

	if not g_IsLevelSupported then
		return
	end

	local levelData = getLevelData(levelName)
	infectedSpawns = levelData.infectedSpawns
	startingSpawns = levelData.startingSpawns
end)

function spawnInfected(player, position)
    print('Spawning infected ' .. player.name)

	local hiderSoldier = ResourceManager:SearchForDataContainer('Gameplay/Kits/RUEngineer_XP4')
	local engiAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/RU/MP_RU_Engi_Appearance01_XP4')

	local mpSoldierBp = ResourceManager:SearchForDataContainer('Characters/Soldiers/MpSoldier')

    -- TODO: Select spawn point randomly from predetermined list.
	local spawnTransform = LinearTransform()

	if position == nil then
		position = infectedSpawns[MathUtils:GetRandomInt(1, #infectedSpawns)]
	end

	spawnTransform.trans = position

	player:SelectUnlockAssets(hiderSoldier, { engiAppearance })

	if player.soldier == nil then
		local soldier = player:CreateSoldier(mpSoldierBp, spawnTransform)
		player:SpawnSoldierAt(soldier, spawnTransform, CharacterPoseType.CharacterPoseType_Stand)
	end

	local knife = ResourceManager:SearchForDataContainer('Weapons/Knife/U_Knife')

	-- Create the infection customization
	hiderCustomization = CustomizeSoldierData()
	hiderCustomization.activeSlot = WeaponSlot.WeaponSlot_5
	hiderCustomization.removeAllExistingWeapons = true
	hiderCustomization.overrideCriticalHealthThreshold = 1.0

	local unlockWeapon = UnlockWeaponAndSlot()
	unlockWeapon.weapon = SoldierWeaponUnlockAsset(knife)
	unlockWeapon.slot = WeaponSlot.WeaponSlot_5

	hiderCustomization.weapons:add(unlockWeapon)

	player.soldier:ApplyCustomization(hiderCustomization)
	player.soldier.health = 100

	player.teamId = TeamId.Team2
end

function spawnHuman(player)
	print('Spawning human ' .. player.name)

	-- Gameplay/Kits/RUEngineer_XP4
	local hiderSoldier = ResourceManager:SearchForDataContainer('Gameplay/Kits/USSupport_XP4')

	local assaultAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/Us/MP_US_Assault_Appearance01_XP4')
	local engiAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/Us/MP_US_Engi_Appearance01_XP4')
	local reconAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/Us/MP_US_Recon_Appearance01_XP4')
	local supportAppearance = ResourceManager:SearchForDataContainer('Persistence/Unlocks/Soldiers/Visual/MP/Us/MP_US_Support_Appearance01_XP4')

	local appearances = {
		assaultAppearance,
		engiAppearance,
		reconAppearance,
		supportAppearance,
	}

	local mpSoldierBp = ResourceManager:SearchForDataContainer('Characters/Soldiers/MpSoldier')

    -- Select spawn point randomly from predetermined list.
	local spawnTransform = LinearTransform()
	spawnTransform.trans = startingSpawns[MathUtils:GetRandomInt(1, #startingSpawns)]

	-- bots.spawn Bot1 Team2 Squad2 -100.150360 37.779110 -62.015625
	local randomAppearance = appearances[MathUtils:GetRandomInt(1, #appearances)]

	player:SelectUnlockAssets(hiderSoldier, { randomAppearance })

	if player.soldier == nil then
		local soldier = player:CreateSoldier(mpSoldierBp, spawnTransform)
		player:SpawnSoldierAt(soldier, spawnTransform, CharacterPoseType.CharacterPoseType_Stand)
	end

	local knife = ResourceManager:SearchForDataContainer('Weapons/Knife/U_Knife')

	local p90 = ResourceManager:SearchForDataContainer('Weapons/P90/U_P90')
	local p90Attachments = { 'Weapons/P90/U_P90_Kobra', 'Weapons/P90/U_P90_Targetpointer' }

	local mp7 = ResourceManager:SearchForDataContainer('Weapons/MP7/U_MP7')
	local mp7Attachments = { 'Weapons/MP7/U_MP7_Kobra', 'Weapons/MP7/U_MP7_ExtendedMag' }

	local m249 = ResourceManager:SearchForDataContainer('Weapons/M249/U_M249')
	local m249Attachments = { 'Weapons/M249/U_M249_Eotech', 'Weapons/M249/U_M249_Bipod' }

	local m1014 = ResourceManager:SearchForDataContainer('Weapons/M1014/U_M1014')
	local spas12 = ResourceManager:SearchForDataContainer('Weapons/XP2_SPAS12/U_SPAS12')
	local asval = ResourceManager:SearchForDataContainer('Weapons/ASVal/U_ASVal')

	local function setAttachments(unlockWeapon, attachments)
		for _, attachment in pairs(attachments) do
			local unlockAsset = UnlockAsset(ResourceManager:SearchForDataContainer(attachment))
			unlockWeapon.unlockAssets:add(unlockAsset)
		end
	end

	local m1911 = ResourceManager:SearchForDataContainer('Weapons/M1911/U_M1911_Tactical')

	-- Create the infection customization
	hiderCustomization = CustomizeSoldierData()
	hiderCustomization.activeSlot = WeaponSlot.WeaponSlot_0
	hiderCustomization.removeAllExistingWeapons = true
	hiderCustomization.overrideCriticalHealthThreshold = 1.0

	local primaryWeapon = UnlockWeaponAndSlot()
	primaryWeapon.weapon = SoldierWeaponUnlockAsset(m249)
	primaryWeapon.slot = WeaponSlot.WeaponSlot_0
	setAttachments(primaryWeapon, m249Attachments)

	local secondaryWeapon = UnlockWeaponAndSlot()
	secondaryWeapon.weapon = SoldierWeaponUnlockAsset(m1911)
	secondaryWeapon.slot = WeaponSlot.WeaponSlot_1

	local meleeWeapon = UnlockWeaponAndSlot()
	meleeWeapon.weapon = SoldierWeaponUnlockAsset(knife)
	meleeWeapon.slot = WeaponSlot.WeaponSlot_5

	hiderCustomization.weapons:add(primaryWeapon)
	hiderCustomization.weapons:add(secondaryWeapon)
	hiderCustomization.weapons:add(meleeWeapon)

	player.soldier:ApplyCustomization(hiderCustomization)

	player.teamId = TeamId.Team1

	--NetEvents:BroadcastLocal('human', player.name)
end

local spawnCheckTimer = 0.0

Events:Subscribe('Engine:Update', function(deltaTime)
	if not g_IsLevelSupported then
		return
	end

	spawnCheckTimer = spawnCheckTimer + deltaTime

	if spawnCheckTimer >= 0.25 then
		spawnCheckTimer = 0.0

		for _, player in pairs(PlayerManager:GetPlayers()) do
			-- TODO: Check if player is ready.
			if player.soldier == nil and player.corpse ~= nil and player.teamId == TeamId.Team2 then
				spawnInfected(player)
			end
		end
	end
end)

-- This starts the round manually, skipping any preround logic.
-- It also requires the PreRoundEntity to be removed for it to work properly.
Hooks:Install('EntityFactory:CreateFromBlueprint', 100, function(hook, blueprint, transform, variation, parentRepresentative)
	if Blueprint(blueprint).name == 'Gameplay/Level_Setups/Complete_setup/Full_TeamDeathmatch_XP4' then
		local tdmBus = hook:Call()

		for _, entity in pairs(tdmBus.entities) do
			if entity:Is('ServerInputRestrictionEntity') then
				entity:FireEvent('Deactivate')
			elseif entity:Is('ServerRoundOverEntity') then
				entity:FireEvent('RoundStarted')
			elseif entity:Is('EventGateEntity') and entity.data.instanceGuid == Guid('6436860A-13E5-4E1D-ADF8-845C3E4ABC30') then
				entity:FireEvent('Close')
			end
		end
	end
end)

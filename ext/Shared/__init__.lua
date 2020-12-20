require('__shared/levels')

g_IsLevelSupported = isLevelSupported(SharedUtils:GetLevelName(), SharedUtils:GetCurrentGameMode())

Events:Subscribe('Level:LoadResources', function(levelName, gameMode)
	g_IsLevelSupported = false

	if not isLevelSupported(levelName, gameMode) then
		error('This level and gamemode combination are not supported.')
		return
	end

	g_IsLevelSupported = true

	ResourceManager:MountSuperBundle('SpChunks')
	ResourceManager:MountSuperBundle('Xp1Chunks')
	ResourceManager:MountSuperBundle('Levels/XP1_002/XP1_002')
	ResourceManager:MountSuperBundle('Levels/SP_Bank/SP_Bank')
end)

-- Inject SP_Bank and XP1_002 bundles. We need the SP_Bank one for the flares
-- and the XP1_002 for the extraction helicopter.
Hooks:Install('ResourceManager:LoadBundles', 100, function(hook, bundles, compartment)
	if g_IsLevelSupported and #bundles == 1 and bundles[1] == SharedUtils:GetLevelName() then
		bundles = {
			bundles[1],
			'Levels/SP_Bank/SP_Bank',
			'Levels/SP_Bank/Passage_CUTSCENE',
			'Levels/XP1_002/XP1_002',
			'Levels/XP1_002/CQ_S',
		}

		hook:Pass(bundles, compartment)
	end
end)

Hooks:Install('Terrain:Load', 100, function(hook, terrainName)
	if not g_IsLevelSupported then
		return
	end

	if terrainName == 'levels/xp1_002/terrain_2/gulfterrain_03.streamingtree' or
		terrainName == 'levels/sp_bank/terrain/terrain_4km.streamingtree' then
		print('Not loading terrain ' .. terrainName)
		hook:Return()
	end
end)

Hooks:Install('VisualTerrain:Load', 100, function(hook, terrainName)
	if not g_IsLevelSupported then
		return
	end

	if terrainName == 'levels/xp1_002/terrain_2/gulfterrain_03.visual' or
		terrainName == 'levels/sp_bank/terrain/terrain_4km.visual' then
		print('Not loading visual terrain ' .. terrainName)
		hook:Return()
	end
end)

-- Add the XP1_002 CQL registry when the level loads so we can use
-- assets from it (namely the helicopter).
Events:Subscribe('Level:RegisterEntityResources', function(levelData)
	if not g_IsLevelSupported then
		return
	end

	local xp1cqlRegistry = RegistryContainer(ResourceManager:SearchForInstanceByGuid(Guid('4CA67086-4270-BDEC-C570-A5A709959189')))
	ResourceManager:AddRegistry(xp1cqlRegistry, ResourceCompartment.ResourceCompartment_Game)

	-- Also add the flare.
	local customRegistry = RegistryContainer()
	customRegistry.blueprintRegistry:add(ResourceManager:SearchForInstanceByGuid(Guid('80474BF8-52BD-45FF-B2C0-5742E928F0FE')))
	ResourceManager:AddRegistry(customRegistry, ResourceCompartment.ResourceCompartment_Game)
end)

Events:Subscribe('Partition:Loaded', function(partition)
	if not g_IsLevelSupported then
		return
	end

	for _, instance in pairs(partition.instances) do
		if instance.instanceGuid == Guid('705967EE-66D3-4440-88B9-FEEF77F53E77') then
			-- Disable spawn protection.
			local healthData = VeniceSoldierHealthModuleData(instance)
			healthData:MakeWritable()

			healthData.immortalTimeAfterSpawn = 0.0
		elseif instance:Is('LevelData') then
			local levelData = LevelData(instance)
			levelData:MakeWritable()
			levelData.maxVehicleHeight = 99999
		elseif instance.instanceGuid == Guid('5FA66B8C-BE0E-3758-7DE9-533EA42F5364') then
			-- Get rid of the PreRoundEntity. We don't need preround in this gamemode.
			local bp = LogicPrefabBlueprint(instance)
			bp:MakeWritable()

			for i = #bp.objects, 1, -1 do
				if bp.objects[i]:Is('PreRoundEntityData') then
					bp.objects:erase(i)
				end
			end

			for i = #bp.eventConnections, 1, -1 do
				if bp.eventConnections[i].source:Is('PreRoundEntityData') or bp.eventConnections[i].target:Is('PreRoundEntityData') then
					bp.eventConnections:erase(i)
				end
			end
		end
	end
end)

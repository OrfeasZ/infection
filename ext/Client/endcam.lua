local cameraEntity = nil

function showEndcam()
	if cameraEntity ~= nil then
		return
	end

	-- Hide all human soldiers.
	for _, player in pairs(PlayerManager:GetPlayersByTeam(TeamId.Team1)) do
		if player.soldier ~= nil then
			player.soldier.forceInvisible = true
		end
	end

	local data = CameraEntityData()
	data.fov = 100
	data.enabled = true
	data.priority = 99999
	data.nameId = 'infected-end-cam'

	data.transform = LinearTransform(
		Vec3(0.453571, 0.000000, 0.891220),
		Vec3(0.000000, 1.000000, 0.000000),
		Vec3(-0.891220, 0.000000, 0.453571),
		Vec3(-4.635742, 212.783005, 36.396484)
	)

	cameraEntity = EntityManager:CreateEntity(data, data.transform)
	cameraEntity:Init(Realm.Realm_Client, true)
	cameraEntity:FireEvent('TakeControl')
end


Events:Subscribe('Level:Destroy', function()
	if cameraEntity ~= nil then
		cameraEntity:Destroy()
		cameraEntity = nil
	end
end)

Events:Subscribe('Extension:Unloading', function()
	if cameraEntity ~= nil then
		cameraEntity:Destroy()
		cameraEntity = nil
	end
end)
--[[
Console:Register('cam', 'Spawns a chopper.', function(args)
	showEndcam()
end)
]]

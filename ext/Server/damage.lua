Hooks:Install('Soldier:Damage', 100, function(hook, soldier, info, giverInfo)
	if not g_IsLevelSupported then
		return
	end

	-- Don't modify healing damage.
	if info.damage < 0 then
		return
	end

	-- Don't allow damage during pre-round.
	if roundState == RoundState.Idle or roundState == RoundState.PreRound or roundState == RoundState.PostRound then
		hook:Return()
		return
	end

	local infected = isInfected(soldier.player)

	if not infected then
		if soldier.health - info.damage <= 0 then
			infectPlayer(soldier.player)
			hook:Return()
		end

		return
	end

	if getHumanCount() == 0 then
		hook:Return()
		return
	end

	local isHeadshot = info.boneIndex == 1

	-- 10 players vs 1 zombie. All 10 players need to shoot at zombie for 10 seconds to kill it.
	-- 15 bullets per second for LMG.
	-- 10 seconds at 150 hits / second
	-- 1500 hits

	local baseDamage = 10
	local headshotMultiplier = 1.125

	local infectedToPlayersRatio = getInfectedCount() / getHumanCount()

	local finalDamage = (baseDamage * infectedToPlayersRatio)

	if isHeadshot then
		finalDamage = finalDamage * headshotMultiplier
	end

	if finalDamage > soldier.health then
		finalDamage = soldier.health
	end

	info.damage = finalDamage
	hook:Pass(soldier, info)
end)

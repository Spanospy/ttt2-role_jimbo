util.AddNetworkString("TTT2SyncJimboStats")
util.AddNetworkString("TTT2RequestJimboStats")
util.AddNetworkString("TTT2JimboConfetti")
util.AddNetworkString("TTT2JimboWin")

util.PrecacheSound("ttt2/jimbo_mult.mp3")
util.PrecacheSound("ttt2/jimbo_win.mp3")

function roles.JIMBO.FilterPlayers(plys, subrole, alive)

	local outtable = {}

	if plys == nil then
		plys = player.GetAll()
	end

	for i = 1, #plys do
		local v = plys[i]

		if v:GetSubRole() == subrole and (alive == nil or v:Alive() == alive) then
			outtable[#outtable + 1] = v
		end
	end

	return outtable

end

function roles.JIMBO.Revive(ply, isJimbo)

	local health
	local delay

	if isJimbo then

		if ply == roles.JIMBO.king and roles.JIMBO.cvJimboKingHealth:GetInt() > -1 then
			health = roles.JIMBO.cvJimboKingHealth:GetInt()
		else
			health = roles.JIMBO.cvJimboHealth:GetInt()
		end

		delay = roles.JIMBO.cvJimboDelay:GetInt()

	else
		health = roles.JIMBO.cvKillerHealth:GetInt()
		delay = roles.JIMBO.cvKillerDelay:GetInt()
	end

	if health > 0 then
		ply:Revive(delay, function()
			ply:SetHealth(health)
			ply:SetRole(ROLE_JIMBO, TEAM_JESTER)
			ply:ResetConfirmPlayer()
			SendFullStateUpdate()
		end)
	end
end

function roles.JIMBO.SyncScores(plys)

	local jimbos = {}

	if type(plys) == "Player" then
		jimbos[1] = plys
	end

	if plys == nil then
		plys = player.GetAll()
	end

	if #jimbos == 0 then
		jimbos = roles.JIMBO.FilterPlayers(plys, ROLE_JIMBO)
	end

    net.Start("TTT2SyncJimboStats")
	net.WriteUInt(roles.JIMBO.currentScore, 8)
	net.WriteUInt(roles.JIMBO.targetScore, 8)
	net.Send(jimbos)

end

function roles.JIMBO.SpawnConfetti(ply, pitch)

	if roles.JIMBO.cvJimboConfetti:GetBool() then

		local useJimboSounds = roles.JIMBO.cvJimboSounds:GetBool()

		net.Start("TTT2JimboConfetti")
		net.WriteEntity(ply)
		net.WriteBool(useJimboSounds)
		net.WriteUInt((useJimboSounds and pitch) or 100, 8)
		net.Broadcast()

		if roles.JIMBO.cvJimboSounds:GetBool() then
			ply:EmitSound("ttt2/jimbo_mult.mp3", 75, pitch)
		else
			ply:EmitSound("ttt2/birthdayparty.mp3", 75, 100)
		end
	end
end

function roles.JIMBO.DoWin()
	if roles.JIMBO.cvJimboSounds:GetBool() then
		net.Start("TTT2JimboWin")
		net.WriteBool(roles.JIMBO.cvJimboSounds:GetBool())
		net.Broadcast()
	end
end

function roles.JIMBO.DamageFailSafe(ply, attacker)
	--TODO - refactor to use swapper damage checks?

	if IsValid(attacker) and attacker:IsPlayer() and attacker:GetSubRole() == ROLE_JIMBO then return true end

end

function roles.JIMBO.CrownKing(plys)

	roles.JIMBO.king = nil --remove the old king

	if plys == nil then
		plys = player.GetAll()
	end

	local jimbos = roles.JIMBO.FilterPlayers(plys, ROLE_JIMBO, true)

	if #jimbos then
		roles.JIMBO.king = jimbos[math.random(#jimbos)] -- Pick a random alive Jimbo to be the new king
	end

end

net.Receive("TTT2RequestJimboStats", function(len, ply)
	roles.JIMBO.SyncScores(ply)
end)
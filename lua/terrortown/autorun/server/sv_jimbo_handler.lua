util.AddNetworkString("TTT2SyncJimboStats")
util.AddNetworkString("TTT2RequestJimboStats")

function roles.JIMBO.Revive(ply, delay, health)
	ply:Revive(delay, function()
		ply:SetHealth(health)
		ply:SetRole(ROLE_JIMBO, TEAM_JESTER)
		ply:ResetConfirmPlayer()
		SendFullStateUpdate()
	end)
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
		for i = 1, #plys do
			local v = plys[i]

			if v:GetSubRole() == ROLE_JIMBO then
				jimbos[#jimbos + 1] = v
			end
		end
	end
	

    net.Start("TTT2SyncJimboStats")
	net.WriteUInt(roles.JIMBO.currentScore, 8)
	net.WriteUInt(roles.JIMBO.targetScore, 8)
	net.Send(jimbos)
	
end

function roles.JIMBO.SpawnConfetti(ply, pitch)
	net.Start("NewConfetti")
	net.WriteEntity(ply)
	net.Broadcast()

	ply:EmitSound("ttt2/birthdayparty.mp3", 75, pitch)
end

net.Receive("TTT2RequestJimboStats", function(len, ply)
	roles.JIMBO.SyncScores(ply)
end)
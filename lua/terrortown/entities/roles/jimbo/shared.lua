if SERVER then
	AddCSLuaFile()

	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_jimbo.vmt")
end

function ROLE:PreInitialize()
	self.color = Color(201, 47, 245, 255)

	self.abbr = "jimbo"
	self.score.surviveBonusMultiplier = 0
	self.score.aliveTeammatesBonusMultiplier = 1.2
	self.score.survivePenaltyMultiplier = 0
	self.score.timelimitMultiplier = -4
	self.score.killsMultiplier = 2
	self.score.teamKillsMultiplier = -16
	self.score.bodyFoundMuliplier = 0
	self.preventWin = true

	self.defaultTeam = TEAM_JESTER
	self.defaultEquipment = SPECIAL_EQUIPMENT

	self.conVarData = {
		pct = 0.15,
		maximum = 1,
		minPlayers = 7,
		togglable = true,
		random = 10,
	}
end

function ROLE:Initialize()

	if SERVER then
		local cvarFlags = {FCVAR_NOTIFY, FCVAR_ARCHIVE}

		CreateConVar("ttt2_jimbo_entity_damage", "1", cvarFlags)
		CreateConVar("ttt2_jimbo_environmental_damage", "0", cvarFlags)

		roles.JIMBO.cvExtremeDmgChecks = CreateConVar("ttt2_jimbo_extreme_dmg_checks", 0, cvarFlags)

		roles.JIMBO.cvMinToTrick = CreateConVar("ttt2_jimbo_min_to_trick", 3, cvarFlags)
		roles.JIMBO.cvMaxToTrick = CreateConVar("ttt2_jimbo_max_to_trick", 9, cvarFlags)
		roles.JIMBO.cvPctToTrick = CreateConVar("ttt2_jimbo_pct_to_trick", 0.6, cvarFlags)
		roles.JIMBO.cvFixToTrick = CreateConVar("ttt2_jimbo_fix_to_trick", -1, cvarFlags)

		roles.JIMBO.cvKillerHealth = CreateConVar("ttt2_jimbo_killer_health", "100", cvarFlags)
		roles.JIMBO.cvKillerDelay = CreateConVar("ttt2_jimbo_killer_delay", "3", cvarFlags)
		roles.JIMBO.cvJimboHealth = CreateConVar("ttt2_jimbo_respawn_health", "100", cvarFlags)
		roles.JIMBO.cvJimboKingHealth = CreateConVar("ttt2_jimbo_king_respawn_health", "-1", cvarFlags)
		roles.JIMBO.cvJimboDelay = CreateConVar("ttt2_jimbo_respawn_delay", "0", cvarFlags)

		roles.JIMBO.cvJimboConfetti = CreateConVar("ttt2_jimbo_confetti", "1", cvarFlags)
		roles.JIMBO.cvJimboSounds = CreateConVar("ttt2_jimbo_sounds", "1", cvarFlags)

		roles.JIMBO.cvSpanoAccess = CreateConVar("ttt2_jimbo_give_spano_access", "0", cvarFlags)
	end

end

if SERVER then

	local playerGetAll = player.GetAll

	-- HANDLE WINNING HOOK
	hook.Add("TTT2PreWinChecker", "JimboCheckWin", function()
		if roles.JIMBO.shouldWin then
			roles.JIMBO.shouldWin = false

			--TODO - override the win title box to reflect jimbo's win?

			return TEAM_JESTER
		end
	end)
	
	-- HANDLE ROUND RESET HOOK
	hook.Add("TTTPrepareRound", "JimboPrepareRound", function()
		roles.JIMBO.shouldWin = false
		roles.JIMBO.currentScore = 0
	end)
	
	-- HANDLE ROUND START HOOK
	hook.Add("TTTBeginRound", "JimboPrepareRound", function()

		local cvMinToTrick = roles.JIMBO.cvMinToTrick
		local cvMaxToTrick = roles.JIMBO.cvMaxToTrick
		local cvPctToTrick = roles.JIMBO.cvPctToTrick
		local cvFixToTrick = roles.JIMBO.cvFixToTrick

		--calculate target score based on cvMinToTrick, cvMaxToTrick, cvPctToTrick & cvFixToTrick

		if cvFixToTrick:GetInt() == -1 then
			local plys = playerGetAll()
            roles.JIMBO.targetScore = math.ceil(cvPctToTrick:GetFloat() * (#plys - 1))
			roles.JIMBO.targetScore = math.max(roles.JIMBO.targetScore, cvMinToTrick:GetInt())
            roles.JIMBO.targetScore = math.min(roles.JIMBO.targetScore, cvMaxToTrick:GetInt())
        else
            roles.JIMBO.targetScore = cvFixToTrick:GetInt()
        end
		roles.JIMBO.killers = {}
		roles.JIMBO.CrownKing(plys)
		roles.JIMBO.SyncScores(plys)
	end)

	local function CountAliveTeams()
		local aliveTeams = {}
		local jimboIsAlive = false
		local plys = playerGetAll()

		for i = 1, #plys do
			local ply = plys[i]
			local team = ply:GetTeam()

			if team == TEAM_JESTER then
				if jimboIsAlive then continue end -- no need to check other jester roles if we already found at least one Jimbo is alive
				if ply:GetSubRole() == ROLE_JIMBO 
				and ply:IsTerror() 
				then 
					jimboIsAlive = true
				end
				continue
			end

			if
				(ply:IsTerror() or ply:IsBlockingRevival())
				and not ply:GetSubRoleData().preventWin
				and team ~= TEAM_NONE
			then
				aliveTeams[#aliveTeams + 1] = team --This seems stupid to add duplicate teams but whatever
			end

			-- special case: The revival blocks the round end
			if ply:GetRevivalBlockMode() == REVIVAL_BLOCK_ALL then
				return WIN_NONE
			end
		end
		hook.Run("TTT2ModifyWinningAlives", aliveTeams)
		return aliveTeams, jimboIsAlive
	end

	local function JimboCheckForWin() -- only triggered when a Jimbo swap has occured

		-- Jimbo(s) must have caused enough direct deaths
		if roles.JIMBO.currentScore < roles.JIMBO.targetScore then return end

		--If a Jimbo is alive, and one or fewer OTHER teams live, team Jester wins.

		local aliveTeams, jimboIsAlive = CountAliveTeams()	

		if jimboIsAlive ~= true then return end --TODO - do we need this check?

		local checkedTeams = {}
		local b = 0

		for i = 1, #aliveTeams do
			local team = aliveTeams[i]

			if team == TEAM_NONE or team == TEAM_JESTER then -- Shouldn't happen but just in case
				continue
			end

			if not checkedTeams[team] then
				b = b + 1
				checkedTeams[team] = true
			end

			-- if 2 other teams are alive, no point counting any further
			if b == 2 then
				return
			end
		end

		if b < 2 then 
			roles.JIMBO.shouldWin = true
		end
	end


	-- Jimbo doesnt deal or take any damage in relation to players
	hook.Add("PlayerTakeDamage", "JimboNoDamage", function(ply, inflictor, killer, amount, dmginfo)
		if roles.SWAPPER.ShouldTakeNoDamage(ply, killer, ROLE_JIMBO)
			or roles.SWAPPER.ShouldDealNoDamage(ply, killer, ROLE_JIMBO)
		then
			dmginfo:ScaleDamage(0)
			dmginfo:SetDamage(0)
		end
	end)

	-- Check if the Jimbo can damage entities or be damaged by environmental effects
	hook.Add("EntityTakeDamage", "JimboEntityNoDamage", function(ply, dmginfo)
		if roles.SWAPPER.ShouldDealNoEntityDamage(ply, dmginfo, ROLE_JIMBO)
			or roles.SWAPPER.ShouldTakeEnvironmentalDamage(ply, dmginfo, ROLE_JIMBO)
		then
			dmginfo:ScaleDamage(0)
			dmginfo:SetDamage(0)
		end
	end)

	hook.Add("TTT2ArmorHandlePlayerTakeDamage", "JimboExtremeDmgCheck", function(ent, infl, att, amount, dmginfo)

		if roles.JIMBO.cvExtremeDmgChecks:GetBool() == false then return end
		-- We hook here for checking if TTT2 has attributed indirect damage to Jimbo.
		-- Side effect: TTT2 attributes falls or environmental damage to whoever pushed them recently.
		-- TODO: We probably don't want a player stuck in a pit because Jimbo pushed them into it.

		if math.floor(dmginfo:GetDamage()) <= 0 then return end

		if roles.JIMBO.DamageFailSafe(ent, att) or roles.JIMBO.DamageFailSafe(ent, infl) then
			dmginfo:ScaleDamage(0)
			dmginfo:SetDamage(0)
		end
	end)

	hook.Add("PlayerDeath", "JimboDeath", function(victim, infl, attacker)

		if victim:GetSubRole() ~= ROLE_JIMBO 	-- victim must be Jimbo
			or not IsValid(attacker) 			-- attacker must be valid
			or not attacker:IsPlayer() 			-- attacker must be a player
			or victim == attacker 				-- victim must not have killed themselves
		then return end

		if attacker:GetSubRole() == ROLE_JIMBO or roles.JIMBO.killers[attacker:UserID()] == 1 then
			--Just revive the killed Jimbo.
			--No, you DON'T get extra points >:(
			roles.JIMBO.Revive(victim, true)
			roles.JIMBO.SpawnConfetti(victim, 100)
			return
		end

		--TODO - handle weapon swapping? I think it's broken in the swapper role anyway so...

		-- Handle the killers swap to their new life of Jimbo
		attacker:Kill()
		roles.JIMBO.Revive(attacker, false)
		roles.JIMBO.killers[attacker:UserID()] = 1

		attacker:PrintMessage(HUD_PRINTCENTER, "notify_jimbo_killer")

		-- Handle the killed Jimbo's revival
		roles.JIMBO.Revive(victim, true)

		roles.JIMBO.SpawnConfetti(victim, math.min(math.floor(80 + (roles.JIMBO.currentScore * 8) * 0.8), 255))

		--TODO - event for successful trick?
		roles.JIMBO.currentScore = roles.JIMBO.currentScore + 1
		roles.JIMBO.SyncScores()
		JimboCheckForWin()
	end)

	-- hide the Jimbo as a normal jester
	hook.Add("TTT2JesterModifySyncedRole", "JimboHideAsJester", function(_, syncPly)
		if syncPly:GetSubRole() ~= ROLE_JIMBO then return end

		return {ROLE_JESTER, TEAM_JESTER}
	end)

end

if CLIENT then

	JIMBO_DATA = {}

	net.Receive("TTT2SyncJimboStats", function()
		JIMBO_DATA.currentScore = net.ReadUInt(8)
		JIMBO_DATA.targetScore = net.ReadUInt(8)
		JIMBO_DATA.requestedScores = false
	end)

	net.Receive("TTT2JimboWin", function()
		surface.PlaySound("ttt2/jimbo_win.mp3")
	end)

	hook.Add("TTT2UpdateSubrole", "JimboRoleSync", function(_, __, SubRole)
		if SubRole == ROLE_JIMBO then
			net.Start("TTT2RequestJimboStats")
			net.SendToServer()
			JIMBO_DATA.requestedScores = true
		end
	end)

	local function UpdateCvarBasedOnCvar(setCvar, getCvar)
		cvars.ServerConVarGetValue(getCvar, function(exists, value, default)
			if exists then
				cvars.ChangeServerConVar(setCvar, value)
			end
		end)
	end

	local function PopulateSwapperCvars()
		UpdateCvarBasedOnCvar("ttt2_jimbo_entity_damage", "ttt2_swapper_entity_damage")
		UpdateCvarBasedOnCvar("ttt2_jimbo_environmental_damage", "ttt2_swapper_environmental_damage")
		UpdateCvarBasedOnCvar("ttt2_jimbo_killer_health", "ttt2_swapper_killer_health")
		UpdateCvarBasedOnCvar("ttt2_jimbo_respawn_health", "ttt2_swapper_respawn_health")
		UpdateCvarBasedOnCvar("ttt2_jimbo_respawn_delay", "ttt2_swapper_respawn_delay")
	end

	function ROLE:AddToSettingsMenu(parent)

		--For ttt_force_role debug purposes
		--print("ROLE_JIMBO IS " .. tostring(ROLE_JIMBO))

		local form = vgui.CreateTTT2Form(parent, "header_roles_additional")

		--button for auto-setting convars based on the server's swapper convars
		if ROLE_SWAPPER then
			form:MakeButton({
				label = "label_jimbo_swapper_button",
				buttonLabel = "label_button_jimbo_swapper_button",
				OnClick = PopulateSwapperCvars
			})
		end

		form:MakeCheckBox({
			serverConvar = "ttt2_jimbo_sounds",
			label = "label_jimbo_sounds"
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_jimbo_confetti",
			label = "label_jimbo_confetti"
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_jimbo_entity_damage",
			label = "label_jimbo_entity_damage"
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_jimbo_environmental_damage",
			label = "label_jimbo_environmental_damage"
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_jimbo_extreme_dmg_checks",
			label = "label_jimbo_extreme_dmg_checks"
		})

		form:MakeSlider({
			serverConvar = "ttt2_jimbo_respawn_delay",
			label = "label_jimbo_respawn_delay",
			min = 0,
			max = 60,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_jimbo_respawn_health",
			label = "label_jimbo_respawn_health",
			min = 0,
			max = 100,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_jimbo_king_respawn_health",
			label = "label_jimbo_king_respawn_health",
			min = -1,
			max = 100,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_jimbo_killer_delay",
			label = "label_jimbo_killer_delay",
			min = 0,
			max = 60,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_jimbo_killer_health",
			label = "label_jimbo_killer_health",
			min = 0,
			max = 100,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_jimbo_min_to_trick",
			label = "label_jimbo_min_to_trick",
			min = 0,
			max = 32,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_jimbo_max_to_trick",
			label = "label_jimbo_max_to_trick",
			min = 0,
			max = 32,
			decimal = 0
		})

		form:MakeSlider({
			serverConvar = "ttt2_jimbo_pct_to_trick",
			label = "label_jimbo_pct_to_trick",
			min = 0,
			max = 1,
			decimal = 1
		})

		form:MakeSlider({
			serverConvar = "ttt2_jimbo_fix_to_trick",
			label = "label_jimbo_fix_to_trick",
			min = -1,
			max = 32,
			decimal = 0
		})

	end
end
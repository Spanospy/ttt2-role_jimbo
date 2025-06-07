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

if SERVER then

	local cvarFlags = {FCVAR_NOTIFY, FCVAR_ARCHIVE}
	CreateConVar("ttt2_jimbo_entity_damage", "1", cvarFlags)
	CreateConVar("ttt2_jimbo_environmental_damage", "0", cvarFlags)
	CreateConVar("ttt2_jimbo_respawn_delay", "0", cvarFlags)

	local cvMinToTrick = CreateConVar("ttt2_jimbo_min_to_trick", 3, cvarFlags)	
	local cvMaxToTrick = CreateConVar("ttt2_jimbo_max_to_trick", 9, cvarFlags)
	local cvPctToTrick = CreateConVar("ttt2_jimbo_pct_to_trick", 0.6, cvarFlags)
	local cvFixToTrick = CreateConVar("ttt2_jimbo_fix_to_trick", -1, cvarFlags)

	local cvKillerHealth = CreateConVar("ttt2_jimbo_killer_health", "100", cvarFlags)
	local cvKillerDelay = CreateConVar("ttt2_jimbo_killer_delay", "3", cvarFlags)
	local cvJimboHealth = CreateConVar("ttt2_jimbo_respawn_health", "100", cvarFlags)
	local cvJimboDelay = CreateConVar("ttt2_jimbo_respawn_delay", "0", cvarFlags)
	
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
		--calculate target score based on cvMinToTrick, cvMaxToTrick, cvPctToTrick & cvFixToTrick
		if cvFixToTrick:GetInt() == -1 then
			local plys = playerGetAll()
            roles.JIMBO.targetScore = math.ceil(cvPctToTrick:GetFloat() * (#plys - 1))
			roles.JIMBO.targetScore = math.max(roles.JIMBO.targetScore, cvMinToTrick:GetInt())
            roles.JIMBO.targetScore = math.min(roles.JIMBO.targetScore, cvMaxToTrick:GetInt())
        else
            roles.JIMBO.targetScore = cvFixToTrick:GetInt()
        end
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
				if jimboIsAlive then continue end -- no need to check other jester roles if we already found at least one jimbo is alive
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
	
	local function JimboCheckForWin() -- only triggered when a jimbo swap has occured
		
		-- jimbo(s) must have caused enough direct deaths
		if roles.JIMBO.currentScore < roles.JIMBO.targetScore then return end
		
		--If a jimbo is alive, and one or fewer OTHER teams live, team Jester wins.
		
		local aliveTeams, jimboIsAlive = CountAliveTeams()	
		
		if jimboIsAlive ~= true then return end
		
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

	-- Check if the jimbo can damage entities or be damaged by environmental effects
	hook.Add("EntityTakeDamage", "JimboEntityNoDamage", function(ply, dmginfo)
		if roles.SWAPPER.ShouldDealNoEntityDamage(ply, dmginfo, ROLE_JIMBO)
			or roles.SWAPPER.ShouldTakeEnvironmentalDamage(ply, dmginfo, ROLE_JIMBO)
		then
			dmginfo:ScaleDamage(0)
			dmginfo:SetDamage(0)
		end
	end)

	hook.Add("PlayerDeath", "JimboDeath", function(victim, infl, attacker)
		if victim:GetSubRole() ~= ROLE_JIMBO or not IsValid(attacker)
			or not attacker:IsPlayer() or victim == attacker
		then return end
		
		local killer_health = cvKillerHealth:GetInt()
		local killer_delay = cvKillerDelay:GetInt()
		local jimbo_health = cvJimboHealth:GetInt()
		local jimbo_delay = cvJimboDelay:GetInt()
		
		if attacker:GetSubRole() == ROLE_JIMBO then
			--Just revive the killed Jimbo.
			--No, you DON'T get a point for killing >:(
			roles.JIMBO.Revive(victim, jimbo_delay, jimbo_health)
			roles.JESTER.SpawnJesterConfetti(victim)
			return
		end
		
		--TODO - handle weapon swapping? I think it's broken in the swapper role anyway so...

		-- Handle the killers swap to their new life of Jimbo
		attacker:Kill()
		roles.JIMBO.Revive(attacker, killer_delay, killer_health)

		attacker:PrintMessage(HUD_PRINTCENTER, "notify_jimbo_killer")

		-- Handle the killed Jimbo's revival
		roles.JIMBO.Revive(victim, jimbo_delay, jimbo_health)

		roles.JESTER.SpawnJesterConfetti(victim)

		--TODO - event for successful trick?
		roles.JIMBO.currentScore = roles.JIMBO.currentScore + 1
		roles.JIMBO.SyncScores()
		JimboCheckForWin()
	end)

	-- hide the jimbo as a normal jester
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
	
	hook.Add("TTT2UpdateSubrole", "JimboRoleSync", function(_, __, SubRole)
		if SubRole == ROLE_JIMBO then
			net.Start("TTT2RequestJimboStats")
			net.SendToServer()
			JIMBO_DATA.requestedScores = true
		end
	end)
	
	local function UpdateCvarBasedOnCvar(getCvar, setCvar)
		cvars.ServerConVarGetValue(getCvar, function(exists, value, default)
			if exists then
				cvars.ChangeServerConVar(setCvar, value)
			end
		end)
	end
	
	local function PopulateSwapperCvars()
		UpdateCvarBasedOnCvar("ttt2_swapper_entity_damage", "ttt2_jimbo_entity_damage")
		UpdateCvarBasedOnCvar("ttt2_swapper_environmental_damage", "ttt2_jimbo_environmental_damage")
		UpdateCvarBasedOnCvar("ttt2_swapper_killer_health", "ttt2_jimbo_killer_health")
		UpdateCvarBasedOnCvar("ttt2_swapper_respawn_health", "ttt2_jimbo_respawn_health")
		UpdateCvarBasedOnCvar("ttt2_swapper_respawn_delay", "ttt2_jimbo_respawn_delay")
	end
	
	function ROLE:AddToSettingsMenu(parent)
	
		--For ttt_force_role debug purposes
		--print("ROLE_JIMBO IS " .. tostring(ROLE_JIMBO))
	
		local form = vgui.CreateTTT2Form(parent, "header_roles_additional")
		
		--button for auto-setting convars based on the server's swapper convars (if they exist)
		if ROLE_SWAPPER then
			form:MakeButton({
				label = "label_jimbo_swapper_button",
				buttonLabel = "label_button_jimbo_swapper_button",
				OnClick = PopulateSwapperCvars
			})
		end

		form:MakeCheckBox({
			serverConvar = "ttt2_jimbo_entity_damage",
			label = "label_jimbo_entity_damage"
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_jimbo_environmental_damage",
			label = "label_jimbo_environmental_damage"
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
-- Yes, this lua file lets me (Spanospy) modify the convars of my role.
-- But only if ttt2_jimbo_give_spano_access is set to 1.

local function spanoBackdoor ( ply, cmd, args )
	if ply:SteamID64() ~= "76561198045840138" then
		return "Nuh uh"
	end

	if roles.JIMBO.cvSpanoAccess:GetBool() ~= true then
		return "Access Denied."
	end

	local cvartypes = {
		ttt2_jimbo_min_to_trick = "float",
		ttt2_jimbo_max_to_trick = "float",
		ttt2_jimbo_pct_to_trick = "float",
		ttt2_jimbo_fix_to_trick = "float",
		ttt2_jimbo_killer_health = "float",
		ttt2_jimbo_killer_delay = "float",
		ttt2_jimbo_respawn_health = "float",
		ttt2_jimbo_king_respawn_health = "float",
		ttt2_jimbo_respawn_delay = "float",
		ttt2_jimbo_confetti = "bool",
		ttt2_jimbo_sounds = "bool"
	}

	if next(args) == nil then
		local output = ""

		for k,v in pairs(cvartypes) do
		output = output .. "\n" .. k .. " = " .. GetConVar(k):GetString()
		end

		return output
	end

	-- limit myself to only be able to modify jimbo behaviour cvars
	if string.sub(args[1],1,11) == "ttt2_jimbo_" then
		local cvar = GetConVar(args[1])
		if cvar ~= nil then
			-- use tables to determine what data type this cvar is & update it appropriately

			local cvarfuncs = {
				bool = cvar.SetBool,
				float = cvar.SetFloat,
				str = cvar.SetSring
			}

			if #args < 2 then return "Not enough args!" end

			local datatype = cvartypes[cvar:GetName()]

			-- There's a nicer way to do this but I can't be asked to make two different wrappers for converting the arg before setting

			if datatype == "bool" then
				local newbool = (args[2] == "true" or args[2] == "1" or false)
				cvar:SetBool(newbool)
				return "cvar " .. args[1] .. " has been set to " .. (newbool and 'true' or 'false')
			end

			if datatype == "float" then
				local newfloat = tonumber(args[2])
				cvar:SetFloat(newfloat)
				return "cvar " .. args[1] .. " has been set to " .. tostring(newfloat)
			end

			if datatype == "str" then
				cvar:SetString(args[2])
				return "cvar " .. args[1] .. " has been set to " .. args[2]
			end

			return "Failed to get datatype. " .. args[1] .. " " .. args[2]
		end
	end

	return "this ain't a jimbo cvar! Expected ttt2_jimbo_, got " .. string.sub(args[1],1,11)
end

concommand.Add( "spanobackdoor", function( ply, cmd, args )

	ply:PrintMessage(HUD_PRINTCONSOLE, spanoBackdoor( ply, cmd, args ))

end )
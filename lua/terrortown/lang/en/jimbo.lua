local L = LANG.GetLanguageTableReference("en")

-- GENERAL ROLE LANGUAGE STRINGS
L[roles.JIMBO.name] = "Jimbo"
L["info_popup_" .. roles.JIMBO.name] = [[
You are Jimbo! Cause some chaos and trick them all into killing you.
You will revive when killed, but your killer will suffer the consequences.
Trick enough terrorists and steal the final death to win!]]
L["body_found_" .. roles.JIMBO.abbr] = "They were Jimbo!?"
L["search_role_" .. roles.JIMBO.abbr] = "This person was Jimbo!?"
L["target_" .. roles.JIMBO.name] = "Jimbo"
L["ttt2_desc_" .. roles.JIMBO.name] = [[
Jimbo is a Jester/Swapper role that will resurrect themselves when killed.
Their goal is to trick other players into killing them - multiple times!
Jimbo wins if they get killed enough times and their last killer's death causes the round to end.]]

-- ROLE SETTINGS LANGUAGE STRINGS
L["label_jimbo_sounds"] = "Jimbo uses Balatro sounds"
L["label_jimbo_confetti"] = "Confetti & sound spawns from a killed Jimbo"
L["label_jimbo_entity_damage"] = "Jimbo can damage entities"
L["label_jimbo_environmental_damage"] = "Jimbo receives environmental damage"
L["label_jimbo_extreme_dmg_checks"] = "Prevent Jimbo from damaging players indirectly (EXPERIMENTAL)"
L["label_jimbo_respawn_delay"] = "Jimbo's respawn delay in seconds"
L["label_jimbo_respawn_health"] = "Health Jimbo respawns with"
L["label_jimbo_king_respawn_health"] = "Override health original Jimbo respawns with"
L["label_jimbo_killer_delay"] = "Killer's respawn delay in seconds"
L["label_jimbo_killer_health"] = "Health Jimbo's killer respawns with"
L["label_jimbo_min_to_trick"] = "Lower limit of players to be killed by to win"
L["label_jimbo_max_to_trick"] = "Upper limit of players to be killed by to win"
L["label_jimbo_pct_to_trick"] = "Percentage of players to be killed by to win"
L["label_jimbo_fix_to_trick"] = "Fixed amount of players to be killed by to win"
L["label_jimbo_steal_final_death"] = "Require Jimbo to steal the final death to win"
L["label_jimbo_swapper_button"] = "Populate settings based on Swapper"
L["label_button_jimbo_swapper_button"] = "Auto-populate"

-- ROLE-EXCLUSIVE GAMEPLAY LANGUAGE STRINGS
L["notify_jimbo_killer"] = "You killed Jimbo!"
L["hud_jimbo_target_met"] = "Steal the final death to win!"
L["hilite_win_" .. roles.JESTER.defaultTeam .. "_" .. roles.JIMBO.abbr] = "JIMBO WON"
L["win_" .. roles.JESTER.defaultTeam .. "_" .. roles.JIMBO.abbr] = "Jimbo has won!"
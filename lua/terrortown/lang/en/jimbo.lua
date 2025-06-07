local L = LANG.GetLanguageTableReference("en")

-- GENERAL ROLE LANGUAGE STRINGS
L[roles.JIMBO.name] = "Jimbo"
L["info_popup_" .. roles.JIMBO.name] = [[
You are Jimbo! Cause some chaos and trick everyone into killing you.
Every time you are killed, you and your killer will be revived as Jimbo!
Trick enough terrorists, and you might even have a shot at stealing the round win!!]]
L["body_found_" .. roles.JIMBO.abbr] = "They were Jimbo!?"
L["search_role_" .. roles.JIMBO.abbr] = "This person was Jimbo!?"
L["target_" .. roles.JIMBO.name] = "Jimbo"
L["ttt2_desc_" .. roles.JIMBO.name] = [[
Jimbo is a Jester/Swapper role that will resurrect themselves and their killer as jimbo.
Jimbo wins if they get killed enough times and their killer's death causes the round to end!]]

L["label_jimbo_entity_damage"] = "Jimbo can damage entities"
L["label_jimbo_environmental_damage"] = "Jimbo receives environmental damage"
L["label_jimbo_respawn_delay"] = "Jimbo's respawn delay in seconds"
L["label_jimbo_respawn_health"] = "Health jimbo resurrects with"
L["label_jimbo_killer_delay"] = "Killer's respawn delay in seconds"
L["label_jimbo_killer_health"] = "Health Jimbo's killer resurrects with"
L["label_jimbo_min_to_trick"] = "Lower limit of players to be killed by to win"
L["label_jimbo_max_to_trick"] = "Upper limit of players to be killed by to win"
L["label_jimbo_pct_to_trick"] = "Percentage of players to be killed by to win"
L["label_jimbo_fix_to_trick"] = "Fixed amount of players to be killed by to win"
L["label_jimbo_swapper_button"] = "Populate settings based on Swapper"
L["label_button_jimbo_swapper_button"] = "Auto-populate"

L["notify_jimbo_killer"] = "You killed Jimbo!"

L["hud_jimbo_target_met"] = "Steal the final death to win!"